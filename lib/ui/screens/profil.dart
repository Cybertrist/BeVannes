/// Le profil : mes chiffres, les lieux découverts, l'historique et les
/// réglages.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../config/env.dart';
import '../../config/theme.dart';
import '../../data/depot.dart';
import '../../domain/jour.dart';
import '../../domain/modeles.dart';
import '../../domain/score.dart';
import '../../providers.dart';
import '../animations.dart';
import '../widgets.dart';

/// L'état du rappel quotidien, lu dans les préférences.
final rappelsActifsProvider = FutureProvider<bool>((ref) => ref.watch(rappelsProvider).actifs());

class EcranProfil extends ConsumerWidget {
  const EcranProfil({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final joueur = ref.watch(moiProvider).value;
    final historique = ref.watch(historiqueProvider).value ?? const <Validation>[];
    final haut = MediaQuery.viewPaddingOf(context).top;
    final bas = MediaQuery.viewPaddingOf(context).bottom + 96;
    final large = estLarge(context);

    if (joueur == null) return const Center(child: CircularProgressIndicator());

    final gauche = [
      Apparition(rang: 1, child: _Identite(joueur: joueur)),
      const SizedBox(height: 18),
      Apparition(rang: 2, child: _Chiffres(joueur: joueur)),
      const SizedBox(height: 18),
      Apparition(rang: 3, child: _Decouverte(historique: historique)),
    ];
    final droite = [
      const SizedBox(height: 8),
      Apparition(rang: 4, child: _Historique(historique: historique)),
      const SizedBox(height: 26),
      const Apparition(rang: 5, child: _Reglages()),
    ];

    if (large) {
      return ListView(
        padding: EdgeInsets.fromLTRB(
          gouttiere(context, largeur: 1000),
          haut + 8,
          gouttiere(context, largeur: 1000),
          bas,
        ),
        children: [
          const Apparition(
            child: EnTete(titre: 'Profil', sousTitre: 'Tes chiffres, tes lieux, tes réglages'),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: gauche),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: droite),
              ),
            ],
          ),
        ],
      );
    }
    return ListView(
      padding: EdgeInsets.fromLTRB(gouttiere(context), haut + 8, gouttiere(context), bas),
      children: [
        const Apparition(
          child: EnTete(titre: 'Profil', sousTitre: 'Tes chiffres, tes lieux, tes réglages'),
        ),
        ...gauche,
        const SizedBox(height: 18),
        ...droite,
      ],
    );
  }
}

class _Identite extends ConsumerWidget {
  const _Identite({required this.joueur});
  final Joueur joueur;

  Future<void> _renommer(BuildContext context, WidgetRef ref) async {
    final controleur = TextEditingController(text: joueur.pseudo);
    final form = GlobalKey<FormState>();
    final nouveau = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Changer de pseudo'),
        content: Form(
          key: form,
          child: TextFormField(
            controller: controleur,
            autofocus: true,
            maxLength: 20,
            validator: (v) => erreurPseudo(v ?? ''),
            decoration: const InputDecoration(labelText: 'Pseudo', counterText: ''),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) Navigator.pop(context, controleur.text.trim());
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    controleur.dispose();
    if (nouveau == null || nouveau == joueur.pseudo) return;
    try {
      await ref.read(depotProvider).changerPseudo(joueur.uid, nouveau);
      if (context.mounted) toast(context, 'Pseudo modifié.');
    } on ErreurDepot catch (e) {
      if (context.mounted) toast(context, e.message, erreur: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rang = (ref.watch(classementProvider).value ?? const <Joueur>[]).indexWhere((j) => j.uid == joueur.uid);
    return Carte(
      child: Row(
        children: [
          Avatar(joueur.pseudo, taille: 60, anneau: K.accent),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  joueur.pseudo,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  rang < 0 ? 'Pas encore classé' : '${rang + 1}${rang == 0 ? 're' : 'e'} au classement',
                  style: const TextStyle(color: K.muted),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _renommer(context, ref),
            icon: const Icon(Icons.edit_outlined, color: K.muted),
            tooltip: 'Changer de pseudo',
          ),
        ],
      ),
    );
  }
}

class _Chiffres extends ConsumerWidget {
  const _Chiffres({required this.joueur});
  final Joueur joueur;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serie = serieEnCours(
      dernierJour: joueur.dernierJour,
      serie: joueur.serie,
      aujourdhui: ref.watch(aujourdhuiProvider),
    );
    Widget case_(int valeur, String legende, IconData icone, Color couleur) => Expanded(
      child: Carte(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icone, color: couleur, size: 20),
            const SizedBox(height: 12),
            Compteur(valeur, style: K.number(30)),
            const SizedBox(height: 6),
            Text(legende, style: const TextStyle(color: K.muted, fontSize: 13)),
          ],
        ),
      ),
    );
    return Column(
      children: [
        Row(
          children: [
            case_(joueur.points, 'points', Icons.stars_rounded, K.accent),
            const SizedBox(width: 12),
            case_(
              joueur.validations,
              joueur.validations > 1 ? 'lieux validés' : 'lieu validé',
              Icons.verified_outlined,
              K.accent,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            case_(serie, 'jours de suite', Icons.local_fire_department_rounded, K.flamme),
            const SizedBox(width: 12),
            case_(joueur.meilleureSerie, 'meilleure série', Icons.military_tech_outlined, K.or),
          ],
        ),
      ],
    );
  }
}

/// Combien de lieux différents ont été trouvés, sur tous ceux du jeu.
class _Decouverte extends ConsumerWidget {
  const _Decouverte({required this.historique});
  final List<Validation> historique;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = ref.watch(lieuxProvider).length;
    final trouves = historique.map((v) => v.lieuId).toSet().length;
    return Carte(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Vannes découverte', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5)),
              ),
              Text('$trouves / $total', style: K.number(15, color: K.accent)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: total == 0 ? 0 : trouves / total),
              duration: const Duration(milliseconds: 900),
              curve: K.spring,
              builder: (_, v, _) =>
                  LinearProgressIndicator(value: v, minHeight: 8, backgroundColor: K.surface3, color: K.accent),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            trouves == total ? 'Tous les lieux sont trouvés. Chapeau.' : 'Encore ${total - trouves} lieux à trouver.',
            style: const TextStyle(color: K.muted, fontSize: 13.5),
          ),
        ],
      ),
    );
  }
}

class _Historique extends ConsumerWidget {
  const _Historique({required this.historique});
  final List<Validation> historique;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lieux = ref.watch(lieuxProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TitreSection('Mes derniers lieux'),
        if (historique.isEmpty)
          const Carte(
            child: EtatVide(
              icone: Icons.map_outlined,
              titre: 'Aucun lieu pour l’instant',
              texte: 'Ton premier lieu validé apparaîtra ici.',
            ),
          )
        else
          Carte(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                for (final (i, v) in historique.take(estLarge(context) ? 5 : 8).indexed) ...[
                  if (i > 0) const Divider(color: K.border, height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        _Date(jour: v.jour),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            lieuParId(lieux, v.lieuId)?.nom ?? 'Lieu retiré',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                        ),
                        Text('+${v.gain}', style: K.number(15, color: K.accent)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _Date extends StatelessWidget {
  const _Date({required this.jour});
  final int jour;

  @override
  Widget build(BuildContext context) {
    final d = dateDuJour(jour);
    final local = DateTime(d.year, d.month, d.day);
    return Container(
      width: 46,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(color: K.surface2, borderRadius: BorderRadius.circular(11)),
      child: Column(
        children: [
          Text('${local.day}', style: K.number(17)),
          const SizedBox(height: 3),
          Text(
            DateFormat('MMM', 'fr_FR').format(local).replaceAll('.', '').toUpperCase(),
            style: const TextStyle(color: K.muted, fontSize: 10.5, fontWeight: FontWeight.w600, letterSpacing: 0.6),
          ),
        ],
      ),
    );
  }
}

class _Reglages extends ConsumerWidget {
  const _Reglages();

  Future<void> _supprimer(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ton compte ?'),
        content: const Text('Tes points, tes photos et ton historique seront effacés pour de bon.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: K.danger, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(depotProvider).supprimerCompte();
    } on ErreurDepot catch (e) {
      if (context.mounted) toast(context, e.message, erreur: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actifs = ref.watch(rappelsActifsProvider).value ?? true;
    final jour = ref.watch(aujourdhuiProvider);
    final (:heure, :minute) = heureDuRappel(jour);
    // Le rappel du jour saute une fois le lieu validé.
    final dejaPasse =
        ref.watch(maValidationProvider) != null ||
        DateTime.now().isAfter(DateTime.now().copyWith(hour: heure, minute: minute));
    final demain = heureDuRappel(jour + 1);
    final prochain = dejaPasse
        ? 'Demain à ${demain.heure} h ${demain.minute.toString().padLeft(2, '0')}'
        : 'Aujourd’hui à $heure h ${minute.toString().padLeft(2, '0')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TitreSection('Réglages'),
        Carte(
          padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: actifs,
            onChanged: (v) async {
              final obtenu = await ref.read(rappelsProvider).regler(v, ref.read(lieuxProvider));
              ref.invalidate(rappelsActifsProvider);
              if (v && !obtenu && context.mounted) {
                toast(context, 'Les notifications sont bloquées dans les réglages d’Android.', erreur: true);
              }
            },
            secondary: const Icon(Icons.notifications_active_outlined, color: K.accent),
            title: const Text('Rappel quotidien', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
              actifs ? '$prochain, une heure différente chaque jour' : 'Une heure différente chaque jour, comme BeReal',
              style: const TextStyle(color: K.muted, height: 1.35),
            ),
          ),
        ),
        const SizedBox(height: 14),
        BoutonSecondaire(
          texte: 'Se déconnecter',
          icone: Icons.logout_rounded,
          onPressed: () => ref.read(depotProvider).deconnexion(),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () => _supprimer(context, ref),
          style: TextButton.styleFrom(foregroundColor: K.danger),
          child: const Text('Supprimer mon compte'),
        ),
        if (modeDemo)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'Mode démo : rien ne quitte ce téléphone, tout repart de zéro à la prochaine ouverture.',
              textAlign: TextAlign.center,
              style: TextStyle(color: K.faint, fontSize: 12.5, height: 1.4),
            ),
          ),
      ],
    );
  }
}
