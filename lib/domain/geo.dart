/// Distances à la surface de la Terre.
library;

import 'dart:math' as math;

/// Rayon dans lequel une photo compte : assez large pour absorber le bruit
/// du GPS entre les façades, assez serré pour qu'on ne valide pas depuis
/// la rue d'à côté.
const rayonValidation = 100.0;

const _rayonTerre = 6371000.0;

/// Distance en mètres entre deux points, par la formule de haversine.
double distanceMetres(double lat1, double lng1, double lat2, double lng2) {
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLng = rad(lng2 - lng1);
  final a =
      math.pow(math.sin(dLat / 2), 2) + math.cos(rad(lat1)) * math.cos(rad(lat2)) * math.pow(math.sin(dLng / 2), 2);
  return 2 * _rayonTerre * math.asin(math.min(1, math.sqrt(a)));
}

/// « 40 m », « 850 m », « 1,2 km », « 12 km ».
String distanceLisible(double metres) {
  if (metres < 1000) return '${(metres / 10).round() * 10} m';
  final km = metres / 1000;
  if (km < 10) return '${km.toStringAsFixed(1).replaceAll('.', ',')} km';
  final entier = km.round().toString();
  // Espace fine insécable entre les milliers : « 8 912 km ».
  final groupes = <String>[];
  for (var i = entier.length; i > 0; i -= 3) {
    groupes.insert(0, entier.substring(math.max(0, i - 3), i));
  }
  return '${groupes.join(' ')} km';
}
