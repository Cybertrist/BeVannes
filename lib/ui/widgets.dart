/// Les briques d'interface partagées par les écrans.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/theme.dart';

/// Largeur à partir de laquelle on passe en mise en page large (Fold ouvert,
/// tablette).
const kLarge = 700.0;

/// Largeur maximale du contenu d'une colonne.
const kContenuMax = 620.0;

bool estLarge(BuildContext context) => MediaQuery.sizeOf(context).width >= kLarge;

/// Marge horizontale qui centre le contenu dans [largeur].
double gouttiere(BuildContext context, {double min = 16, double largeur = kContenuMax}) {
  final w = MediaQuery.sizeOf(context).width;
  return w > largeur + 2 * min ? (w - largeur) / 2 : min;
}

/// Le fond : vert nuit, un halo sarcelle en haut à gauche comme sur la
/// bannière.
class Fond extends StatelessWidget {
  const Fond({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: K.bg),
      child: Stack(
        children: [
          Positioned(top: -180, left: -140, child: _halo(460, K.accent.withValues(alpha: 0.16))),
          Positioned(bottom: -220, right: -180, child: _halo(420, K.accentProfond.withValues(alpha: 0.10))),
          Positioned.fill(child: child),
        ],
      ),
    );
  }

  Widget _halo(double taille, Color couleur) => IgnorePointer(
    child: Container(
      width: taille,
      height: taille,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [couleur, couleur.withValues(alpha: 0)]),
      ),
    ),
  );
}

/// Le logo, avec son halo.
class Logo extends StatelessWidget {
  const Logo({super.key, this.taille = 64});
  final double taille;

  @override
  Widget build(BuildContext context) {
    final rayon = BorderRadius.circular(taille * 0.26);
    return Container(
      width: taille,
      height: taille,
      decoration: BoxDecoration(
        borderRadius: rayon,
        border: Border.all(color: K.accent.withValues(alpha: 0.55), width: 1.2),
        boxShadow: [
          BoxShadow(color: K.accent.withValues(alpha: 0.35), blurRadius: taille * 0.5, spreadRadius: -taille * 0.12),
        ],
      ),
      child: ClipRRect(
        borderRadius: rayon,
        child: Image.asset('assets/img/logo.png', fit: BoxFit.cover, filterQuality: FilterQuality.high),
      ),
    );
  }
}

/// Une carte : surface légèrement relevée, filet discret.
class Carte extends StatelessWidget {
  const Carte({super.key, required this.child, this.padding = const EdgeInsets.all(18), this.couleur, this.bordure});
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? couleur;
  final Color? bordure;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: couleur ?? K.surface,
        borderRadius: BorderRadius.circular(K.radiusLg),
        border: Border.all(color: bordure ?? K.border),
      ),
      child: child,
    );
  }
}

/// Un titre de section en petites capitales.
class TitreSection extends StatelessWidget {
  const TitreSection(this.texte, {super.key, this.fin});
  final String texte;
  final Widget? fin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
      child: Row(
        children: [
          Expanded(child: Text(texte.toUpperCase(), style: K.etiquette)),
          ?fin,
        ],
      ),
    );
  }
}

/// Un élément qui s'enfonce légèrement sous le doigt.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.onTap, this.actif = true});
  final Widget child;
  final VoidCallback? onTap;
  final bool actif;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  var _presse = false;

  @override
  Widget build(BuildContext context) {
    final actif = widget.actif && widget.onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: actif ? (_) => setState(() => _presse = true) : null,
      onTapUp: actif ? (_) => setState(() => _presse = false) : null,
      onTapCancel: actif ? () => setState(() => _presse = false) : null,
      onTap: actif
          ? () {
              HapticFeedback.lightImpact();
              widget.onTap!();
            }
          : null,
      child: AnimatedScale(scale: _presse ? 0.97 : 1, duration: K.fast, curve: K.ease, child: widget.child),
    );
  }
}

/// Le bouton principal : dégradé sarcelle, texte sombre.
class BoutonPrincipal extends StatelessWidget {
  const BoutonPrincipal({super.key, required this.texte, this.icone, this.onPressed, this.occupe = false});
  final String texte;
  final IconData? icone;
  final VoidCallback? onPressed;
  final bool occupe;

  @override
  Widget build(BuildContext context) {
    final actif = onPressed != null && !occupe;
    final inactif = onPressed == null && !occupe;
    final encre = inactif ? K.muted : K.surAccent;
    return Pressable(
      actif: actif,
      onTap: onPressed,
      child: AnimatedContainer(
        duration: K.medium,
        curve: K.ease,
        height: 56,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        // Inactif : une surface neutre, lisible, qui ne ressemble pas à un
        // bouton cassé.
        decoration: BoxDecoration(
          gradient: inactif ? null : K.degrade,
          color: inactif ? K.surface2 : null,
          border: inactif ? Border.all(color: K.borderStrong) : null,
          borderRadius: BorderRadius.circular(K.radius),
          boxShadow: [
            if (!inactif)
              BoxShadow(
                color: K.accent.withValues(alpha: 0.45),
                blurRadius: 26,
                offset: const Offset(0, 12),
                spreadRadius: -12,
              ),
          ],
        ),
        alignment: Alignment.center,
        child: AnimatedSwitcher(
          duration: K.fast,
          child: occupe
              ? const SizedBox(
                  key: ValueKey('occupe'),
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4, color: K.surAccent),
                )
              : Row(
                  key: const ValueKey('texte'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icone != null) ...[Icon(icone, color: encre, size: 21), const SizedBox(width: 10)],
                    Flexible(
                      child: Text(
                        texte,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: encre, fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Le bouton secondaire : contour discret.
class BoutonSecondaire extends StatelessWidget {
  const BoutonSecondaire({super.key, required this.texte, this.icone, this.onPressed, this.couleur = K.text});
  final String texte;
  final IconData? icone;
  final VoidCallback? onPressed;
  final Color couleur;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onPressed,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: K.surface2,
          borderRadius: BorderRadius.circular(K.radius),
          border: Border.all(color: K.borderStrong),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icone != null) ...[Icon(icone, color: couleur, size: 19), const SizedBox(width: 8)],
            Flexible(
              child: Text(
                texte,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: couleur, fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Une pastille : icône et texte courts.
class Pastille extends StatelessWidget {
  const Pastille({super.key, required this.texte, this.icone, this.couleur = K.accent, this.fond});
  final String texte;
  final IconData? icone;
  final Color couleur;
  final Color? fond;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: fond ?? couleur.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icone != null) ...[Icon(icone, size: 15, color: couleur), const SizedBox(width: 5)],
          Text(
            texte,
            style: TextStyle(color: couleur, fontWeight: FontWeight.w600, fontSize: 13, height: 1.1),
          ),
        ],
      ),
    );
  }
}

/// Un avatar : les initiales du pseudo sur une couleur tirée du pseudo.
class Avatar extends StatelessWidget {
  const Avatar(this.pseudo, {super.key, this.taille = 40, this.anneau});
  final String pseudo;
  final double taille;
  final Color? anneau;

  static const _teintes = [168.0, 190.0, 150.0, 205.0, 140.0, 178.0, 215.0, 160.0];

  @override
  Widget build(BuildContext context) {
    // Initiales en lettres seulement : « Yann_56 » donne Y, pas Y5.
    final mots = pseudo
        .trim()
        .split(RegExp(r'[\s._\-]+'))
        .where((m) => RegExp(r'^\p{L}', unicode: true).hasMatch(m))
        .toList();
    final initiales = mots.isEmpty
        ? '?'
        : (mots.length == 1 ? mots.first.characters.first : mots[0].characters.first + mots[1].characters.first)
              .toUpperCase();
    final teinte = _teintes[pseudo.codeUnits.fold(0, (a, b) => a + b) % _teintes.length];
    return Container(
      width: taille,
      height: taille,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            HSLColor.fromAHSL(1, teinte, 0.45, 0.30).toColor(),
            HSLColor.fromAHSL(1, teinte, 0.55, 0.18).toColor(),
          ],
        ),
        border: Border.all(color: anneau ?? K.borderStrong, width: anneau == null ? 1 : 2),
      ),
      alignment: Alignment.center,
      child: Text(
        initiales,
        style: TextStyle(color: K.accentPale, fontWeight: FontWeight.w700, fontSize: taille * 0.38),
      ),
    );
  }
}

/// Un nombre qui défile jusqu'à sa valeur.
class Compteur extends StatelessWidget {
  const Compteur(this.valeur, {super.key, required this.style, this.suffixe = ''});
  final int valeur;
  final TextStyle style;
  final String suffixe;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: valeur.toDouble()),
      duration: const Duration(milliseconds: 900),
      curve: K.spring,
      builder: (_, v, _) => Text('${v.round()}$suffixe', style: style),
    );
  }
}

/// Un état vide ou une erreur : une icône, une phrase, une action.
class EtatVide extends StatelessWidget {
  const EtatVide({super.key, required this.icone, required this.titre, this.texte, this.action});
  final IconData icone;
  final String titre;
  final String? texte;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: K.accentSoft, borderRadius: BorderRadius.circular(18)),
            child: Icon(icone, color: K.accent, size: 28),
          ),
          const SizedBox(height: 14),
          Text(
            titre,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16.5),
          ),
          if (texte != null) ...[
            const SizedBox(height: 6),
            Text(
              texte!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: K.muted, height: 1.45),
            ),
          ],
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}

/// Plusieurs écrans empilés, un seul visible, fondu entre les deux.
class FonduEmpile extends StatelessWidget {
  const FonduEmpile({super.key, required this.index, required this.children});
  final int index;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < children.length; i++)
          IgnorePointer(
            ignoring: i != index,
            child: ExcludeFocus(
              excluding: i != index,
              child: AnimatedOpacity(
                opacity: i == index ? 1 : 0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                child: TickerMode(enabled: i == index, child: children[i]),
              ),
            ),
          ),
      ],
    );
  }
}

/// Un message bref en bas de l'écran.
void toast(BuildContext context, String message, {bool erreur = false}) {
  final m = ScaffoldMessenger.of(context);
  m.hideCurrentSnackBar();
  m.showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(
            erreur ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
            color: erreur ? K.danger : K.accent,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    ),
  );
}

/// L'en-tête d'un onglet : titre, sous-titre, et un élément à droite.
class EnTete extends StatelessWidget {
  const EnTete({super.key, required this.titre, required this.sousTitre, this.fin});
  final String titre;
  final String sousTitre;
  final Widget? fin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 10, 4, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titre, style: K.display(28)),
                const SizedBox(height: 4),
                Text(sousTitre, style: const TextStyle(color: K.muted, fontSize: 14.5)),
              ],
            ),
          ),
          ?fin,
        ],
      ),
    );
  }
}

/// La vignette « DÉMO », pour ne jamais confondre avec le vrai jeu.
class VignetteDemo extends StatelessWidget {
  const VignetteDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: K.accent.withValues(alpha: 0.5)),
      ),
      child: const Text(
        'DÉMO',
        style: TextStyle(color: K.accent, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.6),
      ),
    );
  }
}
