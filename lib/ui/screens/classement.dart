/// Le classement : un podium, puis tout le monde.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme.dart';
import '../../domain/modeles.dart';
import '../../domain/score.dart';
import '../../providers.dart';
import '../widgets.dart';

class EcranClassement extends ConsumerWidget {
  const EcranClassement({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classement = ref.watch(classementProvider);
    final moi = ref.watch(sessionProvider).value;
    final aujourdhui = ref.watch(aujourdhuiProvider);
    final haut = MediaQuery.viewPaddingOf(context).top;
    final bas = MediaQuery.viewPaddingOf(context).bottom + 96;

    return ListView(
      padding: EdgeInsets.fromLTRB(gouttiere(context), haut + 8, gouttiere(context), bas),
      children: [
        const EnTete(titre: 'Classement', sousTitre: 'Les points cumulés depuis le premier jour'),
        switch (classement) {
          AsyncData(:final value) when value.isEmpty => const Carte(
            child: EtatVide(
              icone: Icons.emoji_events_outlined,
              titre: 'Personne au classement',
              texte: 'Le premier lieu validé ouvrira la course.',
            ),
          ),
          AsyncData(:final value) => _Contenu(joueurs: value, moi: moi, aujourdhui: aujourdhui),
          AsyncError() => const Carte(
            child: EtatVide(
              icone: Icons.cloud_off_rounded,
              titre: 'Classement indisponible',
              texte: 'Vérifie ta connexion, il se mettra à jour tout seul.',
            ),
          ),
          _ => const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          ),
        },
      ],
    );
  }
}

class _Contenu extends StatelessWidget {
  const _Contenu({required this.joueurs, required this.moi, required this.aujourdhui});
  final List<Joueur> joueurs;
  final String? moi;
  final int aujourdhui;

  @override
  Widget build(BuildContext context) {
    final rang = joueurs.indexWhere((j) => j.uid == moi);
    final podium = joueurs.take(3).toList();
    final reste = joueurs.skip(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (rang >= 0) ...[
          _MonRang(rang: rang + 1, total: joueurs.length, joueur: joueurs[rang]),
          const SizedBox(height: 22),
        ],
        _Podium(joueurs: podium, moi: moi),
        if (reste.isNotEmpty) ...[
          const SizedBox(height: 22),
          Carte(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                for (final (i, j) in reste.indexed) ...[
                  if (i > 0) const Divider(color: K.border, height: 1),
                  _Ligne(rang: i + 4, joueur: j, moi: j.uid == moi, aujourdhui: aujourdhui),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _MonRang extends StatelessWidget {
  const _MonRang({required this.rang, required this.total, required this.joueur});
  final int rang;
  final int total;
  final Joueur joueur;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(K.radiusLg),
        gradient: LinearGradient(
          colors: [K.accent.withValues(alpha: 0.22), K.accent.withValues(alpha: 0.06)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: K.accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('TA PLACE', style: K.etiquette),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('$rang', style: K.number(40, color: K.accentPale)),
                  Text(
                    rang == 1 ? 're' : 'e',
                    style: K.number(20, color: K.accentPale, weight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  Text('sur $total', style: const TextStyle(color: K.muted, fontSize: 15)),
                ],
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Compteur(joueur.points, style: K.number(28)),
              const SizedBox(height: 4),
              const Text('points', style: TextStyle(color: K.muted, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Les trois premiers, le premier au centre et plus haut.
class _Podium extends StatelessWidget {
  const _Podium({required this.joueurs, required this.moi});
  final List<Joueur> joueurs;
  final String? moi;

  @override
  Widget build(BuildContext context) {
    Widget marche(int i, double hauteur, Color couleur) {
      if (i >= joueurs.length) return const Expanded(child: SizedBox());
      final j = joueurs[i];
      return Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Avatar(j.pseudo, taille: i == 0 ? 64 : 52, anneau: couleur),
            const SizedBox(height: 8),
            Text(
              j.pseudo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.w700, color: j.uid == moi ? K.accent : K.text),
            ),
            const SizedBox(height: 2),
            Text(
              '${j.points} pts',
              style: K.number(13.5, color: K.muted, weight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            Container(
              height: hauteur,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [couleur.withValues(alpha: 0.30), couleur.withValues(alpha: 0.04)],
                ),
                border: Border(top: BorderSide(color: couleur, width: 2)),
              ),
              alignment: Alignment.topCenter,
              padding: const EdgeInsets.only(top: 10),
              child: Text('${i + 1}', style: K.number(24, color: couleur)),
            ),
          ],
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [marche(1, 74, K.argent), marche(0, 102, K.or), marche(2, 56, K.bronze)],
    );
  }
}

class _Ligne extends StatelessWidget {
  const _Ligne({required this.rang, required this.joueur, required this.moi, required this.aujourdhui});
  final int rang;
  final Joueur joueur;
  final bool moi;
  final int aujourdhui;

  @override
  Widget build(BuildContext context) {
    final serie = serieEnCours(dernierJour: joueur.dernierJour, serie: joueur.serie, aujourdhui: aujourdhui);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text('$rang', style: K.number(15, color: K.muted)),
          ),
          Avatar(joueur.pseudo, taille: 38, anneau: moi ? K.accent : null),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              moi ? '${joueur.pseudo} (toi)' : joueur.pseudo,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: moi ? K.accent : K.text),
            ),
          ),
          if (serie > 1) ...[
            const Icon(Icons.local_fire_department_rounded, color: K.flamme, size: 16),
            const SizedBox(width: 2),
            Text('$serie', style: K.number(13.5, color: K.flamme)),
            const SizedBox(width: 14),
          ],
          Text('${joueur.points}', style: K.number(16)),
        ],
      ),
    );
  }
}
