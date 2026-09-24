import 'package:bevannes/domain/jour.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('le numéro du jour suit la date locale, pas l’heure', () {
    expect(numeroDuJour(DateTime(2026, 9, 24, 0, 1)), numeroDuJour(DateTime(2026, 9, 24, 23, 59)));
    expect(numeroDuJour(DateTime(2026, 9, 25)) - numeroDuJour(DateTime(2026, 9, 24)), 1);
    final d = dateDuJour(numeroDuJour(DateTime(2026, 9, 24)));
    expect([d.year, d.month, d.day], [2026, 9, 24]);
  });

  test('le tirage est le même partout : valeurs figées', () {
    // Si ce test casse, tous les téléphones ne verront plus le même lieu
    // que ceux déjà installés : ne pas le « corriger » à la légère.
    expect([for (var j = 20720; j < 20730; j++) indexDuLieu(j, 19)], _attendu);
  });

  test('chaque lieu passe une fois par cycle', () {
    for (final nb in [2, 5, 19, 40]) {
      for (var cycle = 0; cycle < 30; cycle++) {
        final vus = {for (var j = cycle * nb; j < (cycle + 1) * nb; j++) indexDuLieu(j, nb)};
        expect(vus.length, nb, reason: 'nb=$nb cycle=$cycle');
      }
    }
  });

  test('jamais deux fois le même lieu deux jours de suite', () {
    for (final nb in [2, 3, 19]) {
      for (var j = 1; j < 2000; j++) {
        expect(indexDuLieu(j, nb), isNot(indexDuLieu(j - 1, nb)), reason: 'nb=$nb jour=$j');
      }
    }
  });

  test('un seul lieu : toujours lui', () {
    expect(indexDuLieu(12345, 1), 0);
  });

  test('le rappel tombe entre 10 h et 19 h 59, et varie', () {
    final heures = <String>{};
    for (var j = 20000; j < 20365; j++) {
      final (:heure, :minute) = heureDuRappel(j);
      expect(heure, inInclusiveRange(10, 19));
      expect(minute, inInclusiveRange(0, 59));
      heures.add('$heure:$minute');
    }
    expect(heures.length, greaterThan(200));
  });
}

const _attendu = [13, 7, 9, 18, 15, 12, 8, 6, 2, 7];
