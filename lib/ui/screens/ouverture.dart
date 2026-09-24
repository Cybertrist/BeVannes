/// L'écran d'ouverture animé.
///
/// Android affiche d'abord son écran natif, le logo au centre sur le vert
/// nuit. Flutter reprend le logo au même endroit, fait monter le nom, puis
/// laisse la place à l'écran suivant.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/env.dart';
import '../../config/theme.dart';
import '../widgets.dart';

/// Vrai une fois l'animation jouée : le routeur attend ce signal.
final ouvertureFinieProvider = NotifierProvider<OuvertureFinie, bool>(OuvertureFinie.new);

class OuvertureFinie extends Notifier<bool> {
  @override
  bool build() => false;
  void finir() => state = true;
}

class EcranOuverture extends ConsumerStatefulWidget {
  const EcranOuverture({super.key});

  @override
  ConsumerState<EcranOuverture> createState() => _EcranOuvertureState();
}

class _EcranOuvertureState extends ConsumerState<EcranOuverture> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1900));
  // Le logo se pose, deux ondes partent, puis le nom s'écrit lettre par
  // lettre et la devise suit.
  late final _logo = CurvedAnimation(
    parent: _c,
    curve: const Interval(0, 0.4, curve: Curves.easeOutBack),
  );
  late final _ondes = CurvedAnimation(parent: _c, curve: const Interval(0.12, 0.75));
  late final _devise = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.65, 0.95, curve: Curves.easeOutCubic),
  );

  @override
  void initState() {
    super.initState();
    _c.forward().whenComplete(() {
      if (mounted) ref.read(ouvertureFinieProvider.notifier).finir();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Fond(
        child: Center(
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox.square(
                  dimension: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      for (final decalage in [0.0, 0.28])
                        Builder(
                          builder: (_) {
                            final p = ((_ondes.value - decalage) / (1 - decalage)).clamp(0.0, 1.0);
                            return Opacity(
                              opacity: p == 0 ? 0 : (1 - p) * 0.8,
                              child: Container(
                                width: 112 + 88 * p,
                                height: 112 + 88 * p,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular((112 + 88 * p) * 0.3),
                                  border: Border.all(color: K.accent, width: 1.6),
                                ),
                              ),
                            );
                          },
                        ),
                      Opacity(
                        opacity: _c.value.clamp(0, 0.15) / 0.15,
                        child: Transform.scale(scale: 0.6 + 0.4 * _logo.value, child: const Logo(taille: 112)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                _NomLettreALettre(t: _c.value),
                const SizedBox(height: 8),
                Opacity(
                  opacity: _devise.value,
                  child: Text(
                    modeDemo ? 'Mode démo' : 'Un lieu par jour. Sois-y.',
                    style: const TextStyle(color: K.muted, fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Le nom qui s'écrit : chaque lettre monte à son tour, « Be » en blanc,
/// « Vannes » en sarcelle.
class _NomLettreALettre extends StatelessWidget {
  const _NomLettreALettre({required this.t});
  final double t;

  @override
  Widget build(BuildContext context) {
    const nom = 'BeVannes';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < nom.length; i++)
          Builder(
            builder: (_) {
              final debut = 0.3 + i * 0.045;
              final p = Curves.easeOutCubic.transform(((t - debut) / 0.22).clamp(0.0, 1.0));
              return Opacity(
                opacity: p,
                child: Transform.translate(
                  offset: Offset(0, 22 * (1 - p)),
                  child: Text(
                    nom[i],
                    style: K.display(38, weight: FontWeight.w800, color: i < 2 ? K.text : K.accent),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

/// Le nom, « Be » en blanc et « Vannes » en sarcelle, comme sur la bannière.
class NomBeVannes extends StatelessWidget {
  const NomBeVannes({super.key, this.taille = 30});
  final double taille;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'Be',
            style: K.display(taille, weight: FontWeight.w800),
          ),
          TextSpan(
            text: 'Vannes',
            style: K.display(taille, weight: FontWeight.w800, color: K.accent),
          ),
        ],
      ),
    );
  }
}
