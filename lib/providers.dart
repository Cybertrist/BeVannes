/// L'état partagé de l'application.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/depot.dart';
import 'data/position.dart';
import 'data/rappels.dart';
import 'domain/geo.dart';
import 'domain/jour.dart';
import 'domain/lieu.dart';
import 'domain/modeles.dart';

/// Le stockage, en ligne ou en démo. Choisi dans main.dart.
final depotProvider = Provider<Depot>((ref) => throw UnimplementedError('depotProvider doit être fourni'));

/// Les lieux du jeu, chargés dans main.dart avant le premier écran.
final lieuxProvider = Provider<List<Lieu>>((ref) => throw UnimplementedError('lieuxProvider doit être fourni'));

final localisationProvider = Provider<Localisation>((ref) => const Localisation());
final rappelsProvider = Provider<Rappels>((ref) => Rappels());

/// L'identifiant du joueur connecté, ou null.
final sessionProvider = StreamProvider<String?>((ref) => ref.watch(depotProvider).session);

/// Le joueur connecté.
final moiProvider = StreamProvider<Joueur?>((ref) {
  final uid = ref.watch(sessionProvider).value;
  if (uid == null) return Stream.value(null);
  return ref.watch(depotProvider).joueur(uid);
});

/// Le numéro du jour, qui change à minuit sans relancer l'application.
final aujourdhuiProvider = NotifierProvider<Aujourdhui, int>(Aujourdhui.new);

class Aujourdhui extends Notifier<int> {
  Timer? _minuit;

  @override
  int build() {
    ref.onDispose(() => _minuit?.cancel());
    _programmer();
    return numeroDuJour(DateTime.now());
  }

  void _programmer() {
    final maintenant = DateTime.now();
    final demain = DateTime(maintenant.year, maintenant.month, maintenant.day + 1);
    _minuit = Timer(demain.difference(maintenant) + const Duration(seconds: 1), () {
      state = numeroDuJour(DateTime.now());
      _programmer();
    });
  }
}

/// Le lieu du jour.
final lieuDuJourProvider = Provider<Lieu>((ref) {
  final lieux = ref.watch(lieuxProvider);
  return lieux[indexDuLieu(ref.watch(aujourdhuiProvider), lieux.length)];
});

Lieu? lieuParId(List<Lieu> lieux, String id) {
  for (final l in lieux) {
    if (l.id == id) return l;
  }
  return null;
}

final classementProvider = StreamProvider<List<Joueur>>((ref) {
  if (ref.watch(sessionProvider).value == null) return Stream.value(const []);
  return ref.watch(depotProvider).classement();
});

final validationsDuJourProvider = StreamProvider<List<Validation>>((ref) {
  if (ref.watch(sessionProvider).value == null) return Stream.value(const []);
  return ref.watch(depotProvider).validationsDuJour(ref.watch(aujourdhuiProvider));
});

final historiqueProvider = StreamProvider<List<Validation>>((ref) {
  final uid = ref.watch(sessionProvider).value;
  if (uid == null) return Stream.value(const []);
  return ref.watch(depotProvider).historique(uid);
});

/// Ma validation du jour, si elle existe.
final maValidationProvider = Provider<Validation?>((ref) {
  final uid = ref.watch(sessionProvider).value;
  final jour = ref.watch(aujourdhuiProvider);
  for (final v in ref.watch(historiqueProvider).value ?? const <Validation>[]) {
    if (v.uid == uid && v.jour == jour) return v;
  }
  return null;
});

/// En démo seulement : se placer d'un geste sur le lieu du jour, pour
/// essayer la validation sans traverser Vannes.
final simulationProvider = NotifierProvider<Simulation, bool>(Simulation.new);

class Simulation extends Notifier<bool> {
  @override
  bool build() => false;
  void basculer() => state = !state;
}

/// La position de l'appareil, suivie en continu.
final positionProvider = StreamProvider<EtatPosition>((ref) {
  if (ref.watch(simulationProvider)) {
    final lieu = ref.watch(lieuDuJourProvider);
    // Une vingtaine de mètres à côté, comme un vrai GPS en ville.
    return Stream.value(
      PositionConnue(latitude: lieu.latitude + 0.00012, longitude: lieu.longitude - 0.00015, precision: 8),
    );
  }
  return ref.watch(localisationProvider).suivre();
});

/// La distance au lieu du jour, en mètres, si la position est connue.
final distanceProvider = Provider<double?>((ref) {
  final etat = ref.watch(positionProvider).value;
  if (etat is! PositionConnue) return null;
  final lieu = ref.watch(lieuDuJourProvider);
  return distanceMetres(etat.latitude, etat.longitude, lieu.latitude, lieu.longitude);
});
