/// La coquille du jeu : trois onglets, le lieu du jour au milieu.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme.dart';
import '../../providers.dart';
import '../widgets.dart';
import 'classement.dart';
import 'jour.dart';
import 'profil.dart';

/// L'onglet affiché : 0 classement, 1 lieu du jour, 2 profil.
final ongletProvider = NotifierProvider<Onglet, int>(Onglet.new);

class Onglet extends Notifier<int> {
  @override
  int build() => 1;
  void choisir(int i) => state = i;
}

class Coquille extends ConsumerStatefulWidget {
  const Coquille({super.key});

  @override
  ConsumerState<Coquille> createState() => _CoquilleState();
}

class _CoquilleState extends ConsumerState<Coquille> {
  @override
  void initState() {
    super.initState();
    // Les rappels glissent avec le temps : on les reprogramme à chaque
    // ouverture, sans celui d'aujourd'hui s'il est déjà validé.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final lieux = ref.read(lieuxProvider);
      final historique = await ref.read(historiqueProvider.future);
      final jour = ref.read(aujourdhuiProvider);
      final fait = historique.any((v) => v.jour == jour);
      await ref.read(rappelsProvider).planifier(lieux, dejaValide: fait ? jour : null);
    });
  }

  static const _onglets = [
    (icone: Icons.emoji_events_outlined, active: Icons.emoji_events_rounded, texte: 'Classement'),
    (icone: Icons.explore_outlined, active: Icons.explore_rounded, texte: 'Aujourd’hui'),
    (icone: Icons.person_outline_rounded, active: Icons.person_rounded, texte: 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(ongletProvider);
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Fond(
            child: FonduEmpile(index: index, children: const [EcranClassement(), EcranJour(), EcranProfil()]),
          ),
          // Fond sous la barre d'état, pour le contenu qui défile dessous.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.viewPaddingOf(context).top + 14,
            child: const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [K.bg, Color(0xE6040C0B), Color(0x00040C0B)],
                    stops: [0, 0.7, 1],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BarreOnglets(
        index: index,
        onglets: _onglets,
        choisir: (i) {
          HapticFeedback.selectionClick();
          ref.read(ongletProvider.notifier).choisir(i);
        },
      ),
    );
  }
}

class _BarreOnglets extends StatelessWidget {
  const _BarreOnglets({required this.index, required this.onglets, required this.choisir});
  final int index;
  final List<({IconData icone, IconData active, String texte})> onglets;
  final ValueChanged<int> choisir;

  @override
  Widget build(BuildContext context) {
    // viewPadding et non padding : le Scaffold consomme le second, et la
    // barre s'arrêterait au-dessus de la zone des gestes d'Android.
    final bas = MediaQuery.viewPaddingOf(context).bottom;
    final cote = estLarge(context) ? (MediaQuery.sizeOf(context).width - 520) / 2 : 12.0;
    return Container(
      padding: EdgeInsets.fromLTRB(cote, 8, cote, 8 + bas),
      decoration: BoxDecoration(
        color: const Color(0xFF071210),
        border: const Border(top: BorderSide(color: K.border)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 24)],
      ),
      child: SizedBox(
        height: 58,
        child: LayoutBuilder(
          builder: (context, c) {
            final largeur = c.maxWidth / onglets.length;
            return Stack(
              children: [
                AnimatedPositioned(
                  duration: K.medium,
                  curve: K.spring,
                  left: largeur * index + 10,
                  top: 4,
                  width: largeur - 20,
                  height: 50,
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: K.accentSoft, borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                Row(
                  children: [
                    for (var i = 0; i < onglets.length; i++)
                      Expanded(
                        child: Semantics(
                          selected: i == index,
                          button: true,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => choisir(i),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  i == index ? onglets[i].active : onglets[i].icone,
                                  color: i == index ? K.accent : K.muted,
                                  size: 24,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  onglets[i].texte,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: i == index ? K.accent : K.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
