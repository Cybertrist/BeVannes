/// Ce que la base garde : les joueurs et leurs validations.
library;

/// Un joueur, tel qu'il apparaît au classement.
class Joueur {
  const Joueur({
    required this.uid,
    required this.pseudo,
    this.points = 0,
    this.serie = 0,
    this.meilleureSerie = 0,
    this.validations = 0,
    this.dernierJour = -1,
  });

  final String uid;
  final String pseudo;
  final int points;
  final int serie;
  final int meilleureSerie;
  final int validations;

  /// Numéro du dernier jour validé, -1 si aucun.
  final int dernierJour;

  Joueur copie({String? pseudo, int? points, int? serie, int? meilleureSerie, int? validations, int? dernierJour}) =>
      Joueur(
        uid: uid,
        pseudo: pseudo ?? this.pseudo,
        points: points ?? this.points,
        serie: serie ?? this.serie,
        meilleureSerie: meilleureSerie ?? this.meilleureSerie,
        validations: validations ?? this.validations,
        dernierJour: dernierJour ?? this.dernierJour,
      );
}

/// Une photo prise sur place, qui a rapporté des points.
class Validation {
  const Validation({
    required this.uid,
    required this.pseudo,
    required this.jour,
    required this.lieuId,
    required this.distance,
    required this.gain,
    required this.serie,
    required this.moment,
    this.photo,
  });

  final String uid;
  final String pseudo;
  final int jour;
  final String lieuId;

  /// Distance au lieu au moment de la photo, en mètres.
  final double distance;
  final int gain;
  final int serie;
  final DateTime moment;

  /// Chemin de la photo : dans Storage en ligne, sur l'appareil en démo.
  final String? photo;
}
