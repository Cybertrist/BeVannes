import 'dart:async';

import 'package:geolocator/geolocator.dart';

/// Où en est la localisation de l'appareil.
sealed class EtatPosition {
  const EtatPosition();
}

class PositionEnAttente extends EtatPosition {
  const PositionEnAttente();
}

/// Pourquoi la position est inaccessible.
enum Blocage { serviceCoupe, refusee, refuseeDefinitivement }

class PositionBloquee extends EtatPosition {
  const PositionBloquee(this.blocage);
  final Blocage blocage;
}

class PositionConnue extends EtatPosition {
  const PositionConnue({
    required this.latitude,
    required this.longitude,
    required this.precision,
    this.fictive = false,
  });
  final double latitude;
  final double longitude;

  /// Rayon d'incertitude annoncé par le GPS, en mètres.
  final double precision;

  /// Position fournie par une application de position fictive : Android le
  /// signale, et le jeu la refuse.
  final bool fictive;
}

/// La position de l'appareil, par le GPS.
class Localisation {
  const Localisation();

  static const _reglages = LocationSettings(accuracy: LocationAccuracy.best, distanceFilter: 3);

  /// Demande l'autorisation si besoin, et dit ce qui bloque sinon.
  Future<PositionBloquee?> _autoriser() async {
    if (!await Geolocator.isLocationServiceEnabled()) return const PositionBloquee(Blocage.serviceCoupe);
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
    return switch (perm) {
      LocationPermission.denied => const PositionBloquee(Blocage.refusee),
      LocationPermission.deniedForever => const PositionBloquee(Blocage.refuseeDefinitivement),
      _ => null,
    };
  }

  static PositionConnue _depuis(Position p) =>
      PositionConnue(latitude: p.latitude, longitude: p.longitude, precision: p.accuracy, fictive: p.isMocked);

  /// Suit la position tant qu'on écoute.
  Stream<EtatPosition> suivre() async* {
    yield const PositionEnAttente();
    final blocage = await _autoriser();
    if (blocage != null) {
      yield blocage;
      return;
    }
    final derniere = await Geolocator.getLastKnownPosition();
    if (derniere != null) yield _depuis(derniere);
    yield* Geolocator.getPositionStream(locationSettings: _reglages).map<EtatPosition>(_depuis);
  }

  /// Une mesure fraîche, pour le moment de la validation.
  Future<EtatPosition> actuelle() async {
    final blocage = await _autoriser();
    if (blocage != null) return blocage;
    final p = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.best, timeLimit: Duration(seconds: 20)),
    );
    return _depuis(p);
  }

  Future<void> ouvrirReglages(Blocage blocage) =>
      blocage == Blocage.serviceCoupe ? Geolocator.openLocationSettings() : Geolocator.openAppSettings();
}
