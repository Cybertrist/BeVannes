import 'package:bevannes/domain/score.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('la série continue le lendemain, repart à 1 sinon', () {
    expect(serieApres(dernierJour: 99, serie: 4, jour: 100), 5);
    expect(serieApres(dernierJour: 97, serie: 4, jour: 100), 1);
    expect(serieApres(dernierJour: -1, serie: 0, jour: 100), 1);
  });

  test('gain : 10 points, plus 2 par jour de série, plafonné à +10', () {
    expect(gainPour(1), 10);
    expect(gainPour(2), 12);
    expect(gainPour(6), 20);
    expect(gainPour(30), 20);
  });

  test('la série affichée tombe à zéro après un jour manqué', () {
    expect(serieEnCours(dernierJour: 100, serie: 3, aujourdhui: 100), 3);
    expect(serieEnCours(dernierJour: 99, serie: 3, aujourdhui: 100), 3);
    expect(serieEnCours(dernierJour: 98, serie: 3, aujourdhui: 100), 0);
  });
}
