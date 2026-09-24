/// Les animations de l'application.
///
/// Chacune a un rôle : dire où regarder, montrer qu'un état change, ou
/// récompenser. Aucune ne boucle sans raison, sauf le radar du lieu et le
/// reflet du bouton quand il attend qu'on appuie.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../domain/geo.dart';

/// Rejoue une animation chaque fois que l'écran redevient visible (les
/// onglets cachés ont leur TickerMode coupé). [builder] reçoit la valeur,
/// de 0 à 1, déjà passée par la courbe.
class Rejoue extends StatefulWidget {
  const Rejoue({
    super.key,
    required this.builder,
    this.duree = const Duration(milliseconds: 620),
    this.delai = Duration.zero,
    this.courbe = K.spring,
    this.child,
  });

  final Widget Function(BuildContext context, double t, Widget? child) builder;
  final Duration duree;
  final Duration delai;
  final Curve courbe;
  final Widget? child;

  @override
  State<Rejoue> createState() => _RejoueState();
}

class _RejoueState extends State<Rejoue> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: widget.duree);
  late final _courbe = CurvedAnimation(parent: _c, curve: widget.courbe);
  var _visible = false;
  var _essai = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visible = TickerMode.valuesOf(context).enabled;
    if (visible && !_visible) _jouer();
    _visible = visible;
  }

  Future<void> _jouer() async {
    final essai = ++_essai;
    _c.value = 0;
    if (widget.delai > Duration.zero) await Future.delayed(widget.delai);
    if (mounted && essai == _essai) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _courbe,
    builder: (c, child) => widget.builder(c, _courbe.value, child),
    child: widget.child,
  );
}

/// Animation 6 : les blocs d'un écran arrivent l'un après l'autre, en
/// fondu et en montant un peu.
class Apparition extends StatelessWidget {
  const Apparition({super.key, required this.child, this.rang = 0});
  final Widget child;
  final int rang;

  @override
  Widget build(BuildContext context) {
    return Rejoue(
      delai: Duration(milliseconds: 70 * rang.clamp(0, 8)),
      child: child,
      builder: (_, t, child) => Opacity(
        opacity: t.clamp(0, 1),
        child: Transform.translate(offset: Offset(0, 28 * (1 - t)), child: child),
      ),
    );
  }
}

/// Animation 2 : un radar autour du lieu sur la carte. Trois ondes partent
/// du point et s'effacent en s'élargissant.
class Radar extends StatefulWidget {
  const Radar({super.key, this.taille = 110});
  final double taille;

  @override
  State<Radar> createState() => _RadarState();
}

class _RadarState extends State<Radar> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: widget.taille,
      child: Stack(
        alignment: Alignment.center,
        children: [
          RepaintBoundary(
            child: CustomPaint(size: Size.square(widget.taille), painter: _Ondes(_c)),
          ),
          // Le point, au centre exact.
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              gradient: K.degrade,
              shape: BoxShape.circle,
              border: Border.all(color: K.bg, width: 3),
              boxShadow: [BoxShadow(color: K.accent.withValues(alpha: 0.8), blurRadius: 14)],
            ),
          ),
        ],
      ),
    );
  }
}

class _Ondes extends CustomPainter {
  _Ondes(this.t) : super(repaint: t);
  final Animation<double> t;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final max = size.width / 2;
    for (var i = 0; i < 3; i++) {
      final p = (t.value + i / 3) % 1;
      final rayon = 9 + (max - 9) * Curves.easeOutCubic.transform(p);
      final pinceau = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2 * (1 - p) + 0.6
        ..color = K.accent.withValues(alpha: (1 - p) * 0.75);
      canvas.drawCircle(centre, rayon, pinceau);
    }
  }

  @override
  bool shouldRepaint(_Ondes ancien) => false;
}

/// Animation 3 : la jauge d'approche. L'anneau se remplit à mesure qu'on
/// s'approche, sur une échelle logarithmique : de 3 km (vide) à 100 m
/// (plein). La distance au centre défile au lieu de sauter.
class JaugeApproche extends StatelessWidget {
  const JaugeApproche({super.key, required this.distance, this.taille = 112});
  final double distance;
  final double taille;

  static double remplissage(double d) {
    if (d <= rayonValidation) return 1;
    final p = 1 - math.log(d / rayonValidation) / math.log(30);
    return p.clamp(0.04, 1);
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: distance),
      duration: const Duration(milliseconds: 900),
      curve: K.spring,
      builder: (_, d, _) {
        final plein = d <= rayonValidation;
        return SizedBox.square(
          dimension: taille,
          child: CustomPaint(
            painter: _Anneau(remplissage(d)),
            child: Center(
              child: AnimatedSwitcher(
                duration: K.medium,
                transitionBuilder: (enfant, a) => ScaleTransition(
                  scale: a,
                  child: FadeTransition(opacity: a, child: enfant),
                ),
                child: plein
                    ? const Icon(Icons.check_rounded, key: ValueKey('ok'), color: K.accent, size: 40)
                    : Column(
                        key: const ValueKey('d'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_valeur(d), style: K.number(taille * 0.24)),
                          const SizedBox(height: 3),
                          Text(
                            d < 1000 ? 'mètres' : 'km',
                            style: const TextStyle(color: K.muted, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Le nombre seul, l'unité va dessous.
  static String _valeur(double d) {
    if (d < 1000) return '${(d / 10).round() * 10}';
    final km = d / 1000;
    return km < 10 ? km.toStringAsFixed(1).replaceAll('.', ',') : '${km.round()}';
  }
}

class _Anneau extends CustomPainter {
  _Anneau(this.p);
  final double p;

  @override
  void paint(Canvas canvas, Size size) {
    const epaisseur = 7.0;
    final r = Rect.fromLTWH(epaisseur / 2, epaisseur / 2, size.width - epaisseur, size.height - epaisseur);
    canvas.drawArc(
      r,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = epaisseur
        ..color = K.surface3,
    );
    canvas.drawArc(
      r,
      -math.pi / 2,
      math.pi * 2 * p,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = epaisseur
        ..strokeCap = StrokeCap.round
        ..shader = const SweepGradient(
          colors: [K.accentProfond, K.accent, K.accentPale],
          transform: GradientRotation(-math.pi / 2),
        ).createShader(r),
    );
  }

  @override
  bool shouldRepaint(_Anneau ancien) => ancien.p != p;
}

/// Animation 4 : un reflet de lumière qui balaie un bouton, pour dire
/// « c'est à toi ». Il passe, puis laisse le bouton tranquille un moment.
class Reflet extends StatefulWidget {
  const Reflet({super.key, required this.child, this.rayon = K.radius});
  final Widget child;
  final double rayon;

  @override
  State<Reflet> createState() => _RefletState();
}

class _RefletState extends State<Reflet> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.rayon),
      child: Stack(
        children: [
          widget.child,
          Positioned.fill(
            child: IgnorePointer(
              child: LayoutBuilder(
                builder: (context, c) => AnimatedBuilder(
                  animation: _c,
                  builder: (_, _) {
                    // Le balayage occupe le premier tiers du cycle.
                    final p = Curves.easeInOutCubic.transform((_c.value / 0.36).clamp(0, 1));
                    final l = c.maxWidth * 0.32;
                    return Transform.translate(
                      offset: Offset(-l + (c.maxWidth + l) * p, 0),
                      child: Transform(
                        transform: Matrix4.skewX(-0.35),
                        child: Container(
                          width: l,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0),
                                Colors.white.withValues(alpha: 0.55),
                                Colors.white.withValues(alpha: 0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Animation 5, première moitié : la coche de réussite. Le disque se
/// gonfle, puis le trait se dessine de gauche à droite.
class CocheAnimee extends StatelessWidget {
  const CocheAnimee({super.key, required this.t, this.taille = 112});

  /// Progression, de 0 à 1.
  final double t;
  final double taille;

  @override
  Widget build(BuildContext context) {
    final disque = Curves.easeOutBack.transform((t / 0.5).clamp(0, 1));
    final trait = Curves.easeInOutCubic.transform(((t - 0.35) / 0.55).clamp(0, 1));
    return SizedBox.square(
      dimension: taille,
      child: Transform.scale(
        scale: 0.4 + 0.6 * disque,
        child: Opacity(
          opacity: (t / 0.2).clamp(0, 1),
          child: Container(
            decoration: BoxDecoration(
              gradient: K.degrade,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: K.accent.withValues(alpha: 0.55 * disque), blurRadius: 44)],
            ),
            child: CustomPaint(painter: _Coche(trait)),
          ),
        ),
      ),
    );
  }
}

class _Coche extends CustomPainter {
  _Coche(this.p);
  final double p;

  @override
  void paint(Canvas canvas, Size size) {
    if (p <= 0) return;
    final w = size.width;
    final chemin = Path()
      ..moveTo(w * 0.29, w * 0.52)
      ..lineTo(w * 0.44, w * 0.66)
      ..lineTo(w * 0.72, w * 0.37);
    final mesure = chemin.computeMetrics().first;
    canvas.drawPath(
      mesure.extractPath(0, mesure.length * p),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.085
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = K.surAccent,
    );
  }

  @override
  bool shouldRepaint(_Coche ancien) => ancien.p != p;
}

/// Animation 5, seconde moitié : une gerbe de confettis qui part du
/// centre, retombe et s'éteint.
class Confettis extends StatelessWidget {
  const Confettis({super.key, required this.t});

  /// Progression, de 0 à 1.
  final double t;

  static final _eclats = _genere();

  static List<_Eclat> _genere() {
    final h = math.Random(7);
    const couleurs = [K.accent, K.accentPale, K.or, K.flamme, Colors.white];
    return [
      for (var i = 0; i < 46; i++)
        _Eclat(
          angle: -math.pi / 2 + (h.nextDouble() - 0.5) * math.pi * 1.7,
          vitesse: 260 + h.nextDouble() * 320,
          couleur: couleurs[i % couleurs.length],
          largeur: 5 + h.nextDouble() * 5,
          rotation: (h.nextDouble() - 0.5) * 14,
          rond: i % 4 == 0,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: CustomPaint(size: Size.infinite, painter: _PeintConfettis(t, _eclats)),
  );
}

class _Eclat {
  const _Eclat({
    required this.angle,
    required this.vitesse,
    required this.couleur,
    required this.largeur,
    required this.rotation,
    required this.rond,
  });
  final double angle;
  final double vitesse;
  final Color couleur;
  final double largeur;
  final double rotation;
  final bool rond;
}

class _PeintConfettis extends CustomPainter {
  _PeintConfettis(this.t, this.eclats);
  final double t;
  final List<_Eclat> eclats;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final origine = size.center(Offset.zero);
    // Une seconde et demie de vol : élan qui s'essouffle, puis gravité.
    final s = t * 1.5;
    final freinage = (1 - math.exp(-3 * s)) / 3;
    final opacite = t < 0.7 ? 1.0 : (1 - (t - 0.7) / 0.3);
    for (final e in eclats) {
      final pos =
          origine + Offset(math.cos(e.angle), math.sin(e.angle)) * e.vitesse * freinage + Offset(0, 260 * s * s);
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(e.rotation * s);
      final pinceau = Paint()..color = e.couleur.withValues(alpha: opacite);
      if (e.rond) {
        canvas.drawCircle(Offset.zero, e.largeur / 2, pinceau);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: e.largeur, height: e.largeur * 0.45),
            const Radius.circular(1.5),
          ),
          pinceau,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_PeintConfettis ancien) => ancien.t != t;
}
