/// La photo prise sur place : vérification de la position, publication, et
/// l'écran de réussite.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../data/cadrage.dart';
import '../../data/depot.dart';
import '../../data/position.dart';
import '../../domain/geo.dart';
import '../../domain/modeles.dart';
import '../../providers.dart';
import '../widgets.dart';
import 'coquille.dart';

class EcranPhoto extends ConsumerStatefulWidget {
  const EcranPhoto({super.key, required this.chemin});
  final String chemin;

  @override
  ConsumerState<EcranPhoto> createState() => _EcranPhotoState();
}

class _EcranPhotoState extends ConsumerState<EcranPhoto> {
  /// La position mesurée au moment de publier, et la distance qui en découle.
  double? _distance;
  String? _probleme;
  var _verification = true;
  var _envoi = false;

  @override
  void initState() {
    super.initState();
    _verifier();
  }

  /// Une mesure fraîche : la photo compte là où elle a été prise, pas là où
  /// on était il y a cinq minutes.
  Future<void> _verifier() async {
    setState(() {
      _verification = true;
      _probleme = null;
    });
    final lieu = ref.read(lieuDuJourProvider);
    EtatPosition etat;
    try {
      etat = ref.read(simulationProvider)
          ? ref.read(positionProvider).value ?? const PositionEnAttente()
          : await ref.read(localisationProvider).actuelle();
    } catch (_) {
      etat = const PositionEnAttente();
    }
    if (!mounted) return;
    setState(() {
      _verification = false;
      switch (etat) {
        case PositionConnue(fictive: true):
          _probleme = 'Une application simule ta position. Coupe-la pour jouer.';
        case PositionConnue(:final latitude, :final longitude):
          _distance = distanceMetres(latitude, longitude, lieu.latitude, lieu.longitude);
          if (_distance! > rayonValidation) {
            _probleme =
                'Tu es à ${distanceLisible(_distance!)} du lieu. Il faut être à moins de ${rayonValidation.round()} m.';
          }
        case PositionBloquee():
          _probleme = 'BeVannes n’a plus accès à ta position.';
        case PositionEnAttente():
          _probleme = 'Le GPS ne répond pas. Réessaie à découvert, loin des murs épais.';
      }
    });
  }

  Future<void> _publier() async {
    final uid = ref.read(sessionProvider).value;
    if (uid == null || _distance == null) return;
    setState(() => _envoi = true);
    try {
      final v = await ref
          .read(depotProvider)
          .valider(
            uid: uid,
            jour: ref.read(aujourdhuiProvider),
            lieu: ref.read(lieuDuJourProvider),
            distance: _distance!,
            cheminPhoto: widget.chemin,
          );
      HapticFeedback.heavyImpact();
      // Plus besoin du rappel d'aujourd'hui.
      ref.read(rappelsProvider).planifier(ref.read(lieuxProvider), dejaValide: v.jour);
      if (mounted) context.go('/bravo', extra: v);
    } on ErreurDepot catch (e) {
      if (mounted) {
        setState(() => _envoi = false);
        toast(context, e.message, erreur: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lieu = ref.watch(lieuDuJourProvider);
    final pret = !_verification && _probleme == null;
    return Scaffold(
      body: Fond(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: _envoi ? null : () => context.pop(),
                          icon: const Icon(Icons.close_rounded),
                          tooltip: 'Annuler',
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('TA PHOTO', style: K.etiquette),
                              const SizedBox(height: 2),
                              Text(lieu.nom, overflow: TextOverflow.ellipsis, style: K.display(19)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // La photo telle qu'elle sera publiée : 3:4, sans rognage.
                    Expanded(
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: formatPhoto,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(K.radiusLg),
                            child: Image.file(File(widget.chemin), fit: BoxFit.cover),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    AnimatedSwitcher(
                      duration: K.fast,
                      child: _verification
                          ? const _Bandeau(
                              key: ValueKey('verif'),
                              icone: Icons.gps_fixed_rounded,
                              texte: 'Vérification de ta position…',
                              enCours: true,
                            )
                          : _probleme != null
                          ? _Bandeau(
                              key: const ValueKey('probleme'),
                              icone: Icons.wrong_location_outlined,
                              texte: _probleme!,
                              couleur: K.danger,
                            )
                          : _Bandeau(
                              key: const ValueKey('ok'),
                              icone: Icons.verified_rounded,
                              texte: 'Position confirmée, à ${distanceLisible(_distance!)} du lieu.',
                            ),
                    ),
                    const SizedBox(height: 14),
                    if (_probleme != null)
                      BoutonSecondaire(texte: 'Vérifier à nouveau', icone: Icons.refresh_rounded, onPressed: _verifier)
                    else
                      BoutonPrincipal(
                        texte: 'Publier',
                        icone: Icons.send_rounded,
                        occupe: _envoi,
                        onPressed: pret ? _publier : null,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Bandeau extends StatelessWidget {
  const _Bandeau({super.key, required this.icone, required this.texte, this.couleur = K.accent, this.enCours = false});
  final IconData icone;
  final String texte;
  final Color couleur;
  final bool enCours;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: couleur.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(K.radius)),
      child: Row(
        children: [
          if (enCours)
            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2, color: couleur))
          else
            Icon(icone, color: couleur, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(texte, style: const TextStyle(height: 1.35))),
        ],
      ),
    );
  }
}

/// L'écran de réussite, juste après la publication.
class EcranBravo extends ConsumerStatefulWidget {
  const EcranBravo({super.key, required this.validation});
  final Validation validation;

  @override
  ConsumerState<EcranBravo> createState() => _EcranBravoState();
}

class _EcranBravoState extends ConsumerState<EcranBravo> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
  late final _badge = CurvedAnimation(
    parent: _c,
    curve: const Interval(0, 0.6, curve: Curves.easeOutBack),
  );
  late final _texte = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.3, 1, curve: Curves.easeOutCubic),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _aller(int onglet) {
    ref.read(ongletProvider.notifier).choisir(onglet);
    context.go('/jeu');
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.validation;
    final lieu = lieuParId(ref.watch(lieuxProvider), v.lieuId);
    return Scaffold(
      body: Fond(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: gouttiere(context, min: 24, largeur: 440), vertical: 24),
              child: AnimatedBuilder(
                animation: _c,
                builder: (context, _) => Column(
                  children: [
                    Transform.scale(
                      scale: _badge.value,
                      child: Container(
                        width: 104,
                        height: 104,
                        decoration: BoxDecoration(
                          gradient: K.degrade,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: K.accent.withValues(alpha: 0.5), blurRadius: 40)],
                        ),
                        child: const Icon(Icons.check_rounded, color: K.surAccent, size: 58),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Opacity(
                      opacity: _texte.value,
                      child: Transform.translate(
                        offset: Offset(0, 14 * (1 - _texte.value)),
                        child: Column(
                          children: [
                            Text('Bien joué !', style: K.display(32)),
                            const SizedBox(height: 8),
                            Text(
                              lieu == null ? 'Lieu du jour validé.' : '${lieu.nom}, validé.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: K.muted, fontSize: 16),
                            ),
                            const SizedBox(height: 28),
                            Row(
                              children: [
                                Expanded(
                                  child: _Gain(valeur: v.gain, legende: 'points gagnés', icone: Icons.add_rounded),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _Gain(
                                    valeur: v.serie,
                                    legende: v.serie > 1 ? 'jours de suite' : 'jour de suite',
                                    icone: Icons.local_fire_department_rounded,
                                    couleur: K.flamme,
                                  ),
                                ),
                              ],
                            ),
                            if (v.serie > 1) ...[
                              const SizedBox(height: 14),
                              Text(
                                'La série ajoute un bonus, jusqu’à +10 points par jour.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: K.faint, fontSize: 13),
                              ),
                            ],
                            const SizedBox(height: 32),
                            BoutonPrincipal(
                              texte: 'Voir le classement',
                              icone: Icons.emoji_events_rounded,
                              onPressed: () => _aller(0),
                            ),
                            const SizedBox(height: 12),
                            BoutonSecondaire(texte: 'Voir qui est passé', onPressed: () => _aller(1)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Gain extends StatelessWidget {
  const _Gain({required this.valeur, required this.legende, required this.icone, this.couleur = K.accent});
  final int valeur;
  final String legende;
  final IconData icone;
  final Color couleur;

  @override
  Widget build(BuildContext context) {
    return Carte(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      child: Column(
        children: [
          Icon(icone, color: couleur, size: 22),
          const SizedBox(height: 8),
          Compteur(valeur, style: K.number(34, color: couleur)),
          const SizedBox(height: 6),
          Text(legende, style: const TextStyle(color: K.muted, fontSize: 13)),
        ],
      ),
    );
  }
}
