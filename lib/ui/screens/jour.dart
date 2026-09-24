/// L'écran du lieu du jour : où aller, à quelle distance on en est, et qui
/// y est déjà passé.
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/env.dart';
import '../../config/theme.dart';
import '../../data/cadrage.dart';
import '../../data/position.dart';
import '../../domain/geo.dart';
import '../../domain/jour.dart';
import '../../domain/lieu.dart';
import '../../domain/modeles.dart';
import '../../providers.dart';
import '../animations.dart';
import '../widgets.dart';

/// Les octets d'une photo, gardés le temps de la session.
final photoProvider = FutureProvider.family<Uint8List?, String>((ref, chemin) async {
  final octets = await ref.watch(depotProvider).photo(chemin);
  return octets == null ? null : Uint8List.fromList(octets);
});

class EcranJour extends ConsumerWidget {
  const EcranJour({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lieu = ref.watch(lieuDuJourProvider);
    final large = estLarge(context);
    final haut = MediaQuery.viewPaddingOf(context).top;
    final bas = MediaQuery.viewPaddingOf(context).bottom + 96;

    final entete = EnTete(
      titre: 'Lieu du jour',
      sousTitre: _dateDuJour(ref.watch(aujourdhuiProvider)),
      fin: modeDemo ? const VignetteDemo() : null,
    );
    final details = [
      Apparition(rang: 2, child: _CarteLieu(lieu: lieu)),
      const SizedBox(height: 14),
      const Apparition(rang: 3, child: _Action()),
      const SizedBox(height: 26),
      const Apparition(rang: 4, child: _Mur()),
    ];

    if (large) {
      // Fold ouvert, tablette : la carte à gauche sur toute la hauteur, le
      // reste à droite. Tout tient sans défiler.
      return Padding(
        padding: EdgeInsets.fromLTRB(20, haut + 12, 20, bas + 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 11,
              child: Apparition(rang: 1, child: _Carte(lieu: lieu)),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 10,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 20),
                children: [
                  Apparition(child: entete),
                  ...details,
                ],
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(gouttiere(context), haut + 8, gouttiere(context), bas),
      children: [
        Apparition(child: entete),
        Apparition(
          rang: 1,
          child: SizedBox(height: 250, child: _Carte(lieu: lieu)),
        ),
        const SizedBox(height: 14),
        ...details,
      ],
    );
  }

  static String _dateDuJour(int jour) {
    final d = dateDuJour(jour);
    final texte = DateFormat('EEEE d MMMM', 'fr_FR').format(DateTime(d.year, d.month, d.day));
    return texte[0].toUpperCase() + texte.substring(1);
  }
}

/// Le nom du lieu, son quartier et sa note.
class _CarteLieu extends StatelessWidget {
  const _CarteLieu({required this.lieu});
  final Lieu lieu;

  @override
  Widget build(BuildContext context) {
    return Carte(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Pastille(texte: lieu.quartier, icone: Icons.place_outlined),
              const Spacer(),
              const _CompteARebours(),
            ],
          ),
          const SizedBox(height: 14),
          Text(lieu.nom, style: K.display(26)),
          const SizedBox(height: 10),
          Text(lieu.note, style: const TextStyle(color: K.textSoft, fontSize: 15, height: 1.5)),
        ],
      ),
    );
  }
}

/// Le temps qui reste avant le prochain lieu.
class _CompteARebours extends StatefulWidget {
  const _CompteARebours();

  @override
  State<_CompteARebours> createState() => _CompteAReboursState();
}

class _CompteAReboursState extends State<_CompteARebours> {
  late final Timer _minute;

  @override
  void initState() {
    super.initState();
    _minute = Timer.periodic(const Duration(seconds: 30), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _minute.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maintenant = DateTime.now();
    final reste = DateTime(maintenant.year, maintenant.month, maintenant.day + 1).difference(maintenant);
    final h = reste.inHours;
    final m = reste.inMinutes % 60;
    final texte = h > 0 ? '$h h ${m.toString().padLeft(2, '0')}' : '$m min';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.schedule_rounded, size: 15, color: K.muted),
        const SizedBox(width: 5),
        Text(
          'Nouveau lieu dans $texte',
          style: const TextStyle(color: K.muted, fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

/// La carte : le lieu, son cercle de validation, et le joueur.
class _Carte extends ConsumerStatefulWidget {
  const _Carte({required this.lieu});
  final Lieu lieu;

  @override
  ConsumerState<_Carte> createState() => _CarteState();
}

class _CarteState extends ConsumerState<_Carte> {
  final _controleur = MapController();

  LatLng get _cible => LatLng(widget.lieu.latitude, widget.lieu.longitude);

  /// Cadre le lieu et le joueur ensemble, ou le lieu seul si le joueur est
  /// trop loin pour que la vue ait un sens.
  void _cadrer() {
    final etat = ref.read(positionProvider).value;
    final distance = ref.read(distanceProvider);
    if (etat is PositionConnue && distance != null && distance < 4000 && distance > 30) {
      _controleur.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds(_cible, LatLng(etat.latitude, etat.longitude)),
          padding: const EdgeInsets.all(56),
        ),
      );
    } else {
      _controleur.move(_cible, 16.5);
    }
  }

  @override
  void didUpdateWidget(covariant _Carte ancien) {
    super.didUpdateWidget(ancien);
    if (ancien.lieu.id != widget.lieu.id) _controleur.move(_cible, 16.5);
  }

  @override
  Widget build(BuildContext context) {
    final etat = ref.watch(positionProvider).value;
    return ClipRRect(
      borderRadius: BorderRadius.circular(K.radiusLg),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: K.surface,
          border: Border.all(color: K.border),
          borderRadius: BorderRadius.circular(K.radiusLg),
        ),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _controleur,
              options: MapOptions(
                initialCenter: _cible,
                initialZoom: 16.5,
                minZoom: 11,
                maxZoom: 19,
                backgroundColor: K.surface,
                interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
              ),
              children: [
                // Les tuiles d'OpenStreetMap, passées en négatif et teintées
                // du vert nuit de l'application.
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'fr.bevannes.bevannes',
                  maxNativeZoom: 19,
                  tileBuilder: (context, tuile, _) => ColorFiltered(colorFilter: _teinteNuit, child: tuile),
                ),
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _cible,
                      radius: rayonValidation,
                      useRadiusInMeter: true,
                      color: K.accent.withValues(alpha: 0.13),
                      borderColor: K.accent.withValues(alpha: 0.7),
                      borderStrokeWidth: 1.5,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    // Centré pile sur le lieu, au cœur de la zone de validation.
                    Marker(point: _cible, width: 110, height: 110, child: const Radar()),
                    if (etat is PositionConnue)
                      Marker(
                        point: LatLng(etat.latitude, etat.longitude),
                        width: 22,
                        height: 22,
                        child: const _PointJoueur(),
                      ),
                  ],
                ),
              ],
            ),
            Positioned(
              right: 10,
              top: 10,
              child: Material(
                color: K.surface2.withValues(alpha: 0.92),
                shape: const CircleBorder(side: BorderSide(color: K.borderStrong)),
                child: IconButton(
                  onPressed: _cadrer,
                  tooltip: 'Recadrer',
                  icon: const Icon(Icons.center_focus_strong_rounded, color: K.text, size: 21),
                ),
              ),
            ),
            Positioned(
              left: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(color: K.bg.withValues(alpha: 0.78), borderRadius: BorderRadius.circular(6)),
                child: const Text(
                  '© les contributeurs d’OpenStreetMap',
                  style: TextStyle(color: K.muted, fontSize: 10.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Luminance inversée, puis teinte : le fond clair d'OSM devient vert nuit,
/// les noms de rues ressortent en sarcelle pâle.
// dart format off
const _teinteNuit = ColorFilter.matrix(<double>[
  -0.1531, -0.5149, -0.0520, 0, 185.60,
  -0.1956, -0.6580, -0.0664, 0, 242.60,
  -0.1828, -0.6151, -0.0621, 0, 226.30,
  0, 0, 0, 1, 0,
]);
// dart format on

class _PointJoueur extends StatelessWidget {
  const _PointJoueur();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF5AA9FF),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [BoxShadow(color: const Color(0xFF5AA9FF).withValues(alpha: 0.6), blurRadius: 12)],
      ),
    );
  }
}

/// Ce que le joueur peut faire maintenant : autoriser le GPS, s'approcher,
/// prendre la photo, ou rien s'il a déjà validé.
class _Action extends ConsumerStatefulWidget {
  const _Action();

  @override
  ConsumerState<_Action> createState() => _ActionState();
}

class _ActionState extends ConsumerState<_Action> {
  var _ouverture = false;

  Future<void> _photographier() async {
    setState(() => _ouverture = true);
    try {
      final photo = await ImagePicker().pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        maxWidth: 2400,
        maxHeight: 2400,
        imageQuality: 92,
      );
      if (photo == null) return;
      final cadree = await recadrerPhoto(photo.path);
      if (mounted) context.push('/photo', extra: cadree);
    } catch (_) {
      if (mounted) toast(context, 'Impossible d’ouvrir l’appareil photo.', erreur: true);
    } finally {
      if (mounted) setState(() => _ouverture = false);
    }
  }

  Future<void> _itineraire(Lieu lieu) async {
    final geo = Uri.parse('geo:0,0?q=${lieu.latitude},${lieu.longitude}(${Uri.encodeComponent(lieu.nom)})');
    if (await canLaunchUrl(geo) && await launchUrl(geo)) return;
    await launchUrl(
      Uri.parse(
        'https://www.openstreetmap.org/?mlat=${lieu.latitude}&mlon=${lieu.longitude}#map=18/${lieu.latitude}/${lieu.longitude}',
      ),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    final valide = ref.watch(maValidationProvider);
    if (valide != null) return _DejaValide(validation: valide);

    final lieu = ref.watch(lieuDuJourProvider);
    final etat = ref.watch(positionProvider).value ?? const PositionEnAttente();
    final distance = ref.watch(distanceProvider);

    final Widget contenu = switch (etat) {
      PositionEnAttente() => const _Ligne(
        icone: Icons.gps_not_fixed_rounded,
        titre: 'Recherche de ta position…',
        texte: 'Le GPS peut prendre quelques secondes à se caler.',
      ),
      PositionBloquee(:final blocage) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Ligne(
            icone: Icons.location_disabled_rounded,
            couleur: K.danger,
            titre: switch (blocage) {
              Blocage.serviceCoupe => 'La localisation est coupée',
              _ => 'BeVannes n’a pas accès à ta position',
            },
            texte: 'Sans elle, impossible de savoir si tu es sur place. Elle ne quitte jamais ton téléphone.',
          ),
          const SizedBox(height: 14),
          BoutonSecondaire(
            texte: blocage == Blocage.serviceCoupe ? 'Activer la localisation' : 'Autoriser la position',
            icone: Icons.settings_outlined,
            onPressed: () async {
              if (blocage == Blocage.refusee) {
                ref.invalidate(positionProvider);
              } else {
                await ref.read(localisationProvider).ouvrirReglages(blocage);
              }
            },
          ),
        ],
      ),
      PositionConnue(fictive: true) => const _Ligne(
        icone: Icons.gpp_bad_outlined,
        couleur: K.danger,
        titre: 'Position fictive détectée',
        texte: 'Une application simule ta position. Coupe-la pour jouer.',
      ),
      PositionConnue() => _Distance(
        distance: distance!,
        occupe: _ouverture,
        photographier: _photographier,
        itineraire: () => _itineraire(lieu),
      ),
    };

    return Carte(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          contenu,
          if (modeDemo) ...[
            const SizedBox(height: 14),
            const Divider(color: K.border, height: 1),
            const SizedBox(height: 4),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: ref.watch(simulationProvider),
              onChanged: (_) => ref.read(simulationProvider.notifier).basculer(),
              title: const Text('Me téléporter sur le lieu', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Réservé à la démo', style: TextStyle(color: K.muted)),
            ),
          ],
        ],
      ),
    );
  }
}

/// Une ligne d'état : icône, titre, explication.
class _Ligne extends StatelessWidget {
  const _Ligne({required this.icone, required this.titre, required this.texte, this.couleur = K.accent});
  final IconData icone;
  final String titre;
  final String texte;
  final Color couleur;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(color: couleur.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(13)),
          child: Icon(icone, color: couleur, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titre, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 3),
              Text(texte, style: const TextStyle(color: K.muted, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}

/// La distance au lieu, en jauge, et le bouton qui s'allume une fois sur
/// place.
class _Distance extends StatelessWidget {
  const _Distance({
    required this.distance,
    required this.occupe,
    required this.photographier,
    required this.itineraire,
  });
  final double distance;
  final bool occupe;
  final VoidCallback photographier;
  final VoidCallback itineraire;

  @override
  Widget build(BuildContext context) {
    final surPlace = distance <= rayonValidation;
    final bouton = BoutonPrincipal(
      texte: surPlace ? 'Prendre la photo' : 'Photo possible à moins de ${rayonValidation.round()} m',
      icone: surPlace ? Icons.photo_camera_rounded : Icons.lock_outline_rounded,
      occupe: occupe,
      onPressed: surPlace ? photographier : null,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            JaugeApproche(distance: distance),
            const SizedBox(width: 18),
            Expanded(
              child: AnimatedSwitcher(
                duration: K.medium,
                child: Column(
                  key: ValueKey(surPlace),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(surPlace ? 'SUR PLACE' : 'EN ROUTE', style: K.etiquette),
                    const SizedBox(height: 6),
                    Text(
                      surPlace ? 'Tu y es.' : 'Encore ${distanceLisible(distance)}',
                      // Pas de Syne ici : ses chiffres sont mauvais.
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                        color: surPlace ? K.accent : K.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      surPlace ? 'Cadre le lieu et déclenche.' : 'À vol d’oiseau.',
                      style: const TextStyle(color: K.muted, height: 1.4, fontSize: 13.5),
                    ),
                    if (!surPlace) ...[
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: itineraire,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.directions_walk_rounded, color: K.accent, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Itinéraire',
                              style: TextStyle(color: K.accent, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        surPlace && !occupe ? Reflet(child: bouton) : bouton,
      ],
    );
  }
}

/// Le lieu est validé : l'heure, les points, et la photo.
class _DejaValide extends ConsumerWidget {
  const _DejaValide({required this.validation});
  final Validation validation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Carte(
      bordure: K.accent.withValues(alpha: 0.4),
      child: Row(
        children: [
          if (validation.photo != null) ...[
            SizedBox(width: 78, height: 104, child: Vignette(chemin: validation.photo!, visible: true)),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.verified_rounded, color: K.accent, size: 20),
                    SizedBox(width: 6),
                    Text('Lieu validé', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16.5)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Photo prise à ${DateFormat.Hm('fr_FR').format(validation.moment)}, à ${distanceLisible(validation.distance)} du lieu. '
                  'Le prochain tombe à minuit.',
                  style: const TextStyle(color: K.muted, height: 1.4),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Pastille(texte: '+${validation.gain} points', icone: Icons.bolt_rounded),
                    if (validation.serie > 1)
                      Pastille(
                        texte: '${validation.serie} jours',
                        icone: Icons.local_fire_department_rounded,
                        couleur: K.flamme,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Une photo de validation. Celles des autres restent floutées tant qu'on
/// n'a pas validé soi-même, comme dans BeReal.
class Vignette extends ConsumerWidget {
  const Vignette({super.key, required this.chemin, required this.visible});
  final String chemin;
  final bool visible;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Widget contenu = !visible
        ? const ColoredBox(
            color: K.surface3,
            child: Center(child: Icon(Icons.lock_outline_rounded, color: K.muted, size: 20)),
          )
        : switch (ref.watch(photoProvider(chemin))) {
            AsyncData(value: final octets?) => Image.memory(octets, fit: BoxFit.cover, gaplessPlayback: true),
            AsyncLoading() => const ColoredBox(color: K.surface3),
            _ => const ColoredBox(
              color: K.surface3,
              child: Center(child: Icon(Icons.image_not_supported_outlined, color: K.faint, size: 20)),
            ),
          };
    return ClipRRect(borderRadius: BorderRadius.circular(12), child: contenu);
  }
}

/// Le mur du jour : les joueurs déjà passés, dans l'ordre d'arrivée.
class _Mur extends ConsumerWidget {
  const _Mur();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final validations = ref.watch(validationsDuJourProvider).value ?? const <Validation>[];
    final moi = ref.watch(sessionProvider).value;
    final jaiValide = ref.watch(maValidationProvider) != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TitreSection(
          'Déjà passés aujourd’hui',
          fin: validations.isEmpty ? null : Text('${validations.length}', style: K.number(14, color: K.muted)),
        ),
        if (validations.isEmpty)
          const Carte(
            child: EtatVide(
              icone: Icons.directions_run_rounded,
              titre: 'Personne encore',
              texte: 'Sois le premier ou la première sur place aujourd’hui.',
            ),
          )
        else
          Carte(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Column(
              children: [
                for (final (i, v) in validations.indexed) ...[
                  if (i > 0) const Divider(color: K.border, height: 1),
                  _LigneMur(validation: v, rang: i + 1, moi: v.uid == moi, photoVisible: jaiValide),
                ],
              ],
            ),
          ),
        // Seulement s'il y a des photos à cacher (en démo, les autres joueurs n'en ont pas).
        if (!jaiValide && validations.any((v) => v.photo != null && v.uid != moi))
          const Padding(
            padding: EdgeInsets.only(top: 10, left: 4, right: 4),
            child: Text(
              'Les photos se dévoilent une fois ta propre photo publiée.',
              style: TextStyle(color: K.faint, fontSize: 13),
            ),
          ),
      ],
    );
  }
}

class _LigneMur extends StatelessWidget {
  const _LigneMur({required this.validation, required this.rang, required this.moi, required this.photoVisible});
  final Validation validation;
  final int rang;
  final bool moi;
  final bool photoVisible;

  @override
  Widget build(BuildContext context) {
    final v = validation;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Avatar(v.pseudo, taille: 40, anneau: moi ? K.accent : null),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        moi ? '${v.pseudo} (toi)' : v.pseudo,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                    ),
                    if (rang == 1) ...[const SizedBox(width: 6), const Icon(Icons.bolt_rounded, color: K.or, size: 17)],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${DateFormat.Hm('fr_FR').format(v.moment)} · à ${distanceLisible(v.distance)}',
                  style: const TextStyle(color: K.muted, fontSize: 13),
                ),
              ],
            ),
          ),
          Text('+${v.gain}', style: K.number(15, color: K.accent)),
          if (v.photo != null) ...[
            const SizedBox(width: 12),
            SizedBox(
              width: 40,
              height: 50,
              child: Vignette(chemin: v.photo!, visible: photoVisible || moi),
            ),
          ],
        ],
      ),
    );
  }
}
