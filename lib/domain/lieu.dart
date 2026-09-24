/// Un lieu à trouver dans Vannes.
class Lieu {
  const Lieu({
    required this.id,
    required this.nom,
    required this.quartier,
    required this.latitude,
    required this.longitude,
    required this.note,
  });

  final String id;
  final String nom;
  final String quartier;
  final double latitude;
  final double longitude;

  /// Le petit texte historique ou culturel qui accompagne le lieu.
  final String note;

  factory Lieu.depuisJson(Map<String, dynamic> j) => Lieu(
    id: j['id'] as String,
    nom: j['nom'] as String,
    quartier: j['quartier'] as String,
    latitude: (j['latitude'] as num).toDouble(),
    longitude: (j['longitude'] as num).toDouble(),
    note: j['note'] as String,
  );
}
