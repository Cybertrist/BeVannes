/// Les points et les séries.
///
/// Les règles Firestore (firestore.rules) refont exactement ce calcul :
/// toute modification ici doit y être reportée.
library;

/// Points de base pour un lieu validé.
const pointsParLieu = 10;

/// Bonus par jour de série, plafonné pour que les nouveaux venus gardent
/// une chance au classement.
const bonusParJourDeSerie = 2;
const bonusSerieMax = 5;

/// La série après une validation le jour [jour], quand la dernière datait
/// de [dernierJour] (-1 si jamais).
int serieApres({required int dernierJour, required int serie, required int jour}) =>
    dernierJour == jour - 1 ? serie + 1 : 1;

/// Les points gagnés avec une série de [serie] jours (validation comprise).
int gainPour(int serie) {
  final jours = serie - 1;
  return pointsParLieu + bonusParJourDeSerie * (jours > bonusSerieMax ? bonusSerieMax : jours);
}

/// La série affichée : elle tombe à zéro dès qu'un jour a été manqué.
int serieEnCours({required int dernierJour, required int serie, required int aujourdhui}) =>
    dernierJour >= aujourdhui - 1 ? serie : 0;
