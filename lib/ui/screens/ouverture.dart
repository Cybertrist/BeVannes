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
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
  late final _titre = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.15, 0.7, curve: Curves.easeOutCubic),
  );
  late final _devise = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.35, 0.9, curve: Curves.easeOutCubic),
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
                const Logo(taille: 112),
                const SizedBox(height: 26),
                Opacity(
                  opacity: _titre.value,
                  child: Transform.translate(
                    offset: Offset(0, 16 * (1 - _titre.value)),
                    child: const NomBeVannes(taille: 36),
                  ),
                ),
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
