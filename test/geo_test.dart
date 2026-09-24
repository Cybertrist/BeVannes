import 'package:bevannes/domain/geo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('distance nulle sur place', () {
    expect(distanceMetres(47.6578, -2.7569, 47.6578, -2.7569), 0);
  });

  test('cathédrale ↔ porte Saint-Vincent : environ 380 m', () {
    final d = distanceMetres(47.657778, -2.756944, 47.6545, -2.75804);
    expect(d, closeTo(373, 10));
  });

  test('Vannes ↔ Rennes : environ 100 km à vol d’oiseau', () {
    expect(distanceMetres(47.6559, -2.7603, 48.1173, -1.6778) / 1000, closeTo(98, 3));
  });

  test('distances lisibles', () {
    expect(distanceLisible(42), '40 m');
    expect(distanceLisible(847), '850 m');
    expect(distanceLisible(1234), '1,2 km');
    expect(distanceLisible(12400), '12 km');
    expect(distanceLisible(8912000), '8 912 km');
  });
}
