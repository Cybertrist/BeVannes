/// Le calendrier du jeu : quel lieu tombe quel jour, et à quelle heure
/// sonne le rappel.
///
/// Tout est déterministe : chaque téléphone calcule le même lieu pour le
/// même jour, sans que personne n'ait à l'écrire dans la base.
library;

/// Numéro du jour : nombre de jours écoulés depuis le 1er janvier 1970,
/// pris sur la date locale de l'appareil.
int numeroDuJour(DateTime t) =>
    DateTime.utc(t.year, t.month, t.day).millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;

/// La date civile d'un numéro de jour.
DateTime dateDuJour(int jour) => DateTime.fromMillisecondsSinceEpoch(jour * Duration.millisecondsPerDay, isUtc: true);

/// Générateur pseudo-aléatoire graine fixe (mulberry32), identique sur
/// toutes les plateformes car il ne travaille que sur 32 bits.
class _Hasard {
  _Hasard(int graine) : _etat = graine & 0xFFFFFFFF;
  int _etat;

  int suivant() {
    _etat = (_etat + 0x6D2B79F5) & 0xFFFFFFFF;
    var t = _etat;
    t = _mul(t ^ (t >> 15), t | 1);
    t ^= (t + _mul(t ^ (t >> 7), t | 61)) & 0xFFFFFFFF;
    return (t ^ (t >> 14)) & 0xFFFFFFFF;
  }

  static int _mul(int a, int b) => (a * b) & 0xFFFFFFFF;

  int sous(int n) => suivant() % n;
}

/// L'ordre de passage des lieux pendant un cycle : chaque lieu une fois,
/// dans un ordre mélangé propre au cycle.
List<int> _ordreDuCycle(int cycle, int nb) {
  final ordre = List<int>.generate(nb, (i) => i);
  final hasard = _Hasard(cycle * 2654435761);
  for (var i = nb - 1; i > 0; i--) {
    final j = hasard.sous(i + 1);
    final t = ordre[i];
    ordre[i] = ordre[j];
    ordre[j] = t;
  }
  return ordre;
}

/// Index du lieu du jour parmi [nb] lieux.
///
/// Les lieux passent tous une fois par cycle de [nb] jours, et jamais le
/// même deux jours de suite, même à la jonction entre deux cycles.
int indexDuLieu(int jour, int nb) {
  assert(nb > 0);
  if (nb == 1) return 0;
  // À deux, la seule suite sans répétition est l'alternance.
  if (nb == 2) return jour % 2;
  final cycle = jour ~/ nb;
  final ordre = _ordreDuCycle(cycle, nb);
  // Dès trois lieux, l'échange des deux premiers ne touche pas au dernier :
  // le dernier du cycle précédent se lit donc sans le corriger.
  final dernierPrecedent = _ordreDuCycle(cycle - 1, nb).last;
  if (ordre.first == dernierPrecedent) {
    ordre[0] = ordre[1];
    ordre[1] = dernierPrecedent;
  }
  return ordre[jour % nb];
}

/// L'heure du rappel d'un jour donné, entre 10 h et 19 h 59, comme BeReal :
/// la même pour tout le monde, jamais la même d'un jour à l'autre.
({int heure, int minute}) heureDuRappel(int jour) {
  final hasard = _Hasard(jour * 40503 + 7);
  final minutes = hasard.sous(10 * 60);
  return (heure: 10 + minutes ~/ 60, minute: minutes % 60);
}
