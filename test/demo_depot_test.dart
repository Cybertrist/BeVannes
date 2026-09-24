import 'package:bevannes/data/demo_depot.dart';
import 'package:bevannes/data/depot.dart';
import 'package:bevannes/domain/jour.dart';
import 'package:bevannes/domain/lieu.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final lieux = [
    for (var i = 0; i < 5; i++)
      Lieu(id: 'l$i', nom: 'Lieu $i', quartier: 'Q', latitude: 47.65, longitude: -2.75, note: ''),
  ];
  final maintenant = DateTime(2026, 9, 24, 15);
  final jour = numeroDuJour(maintenant);

  test('valider rapporte les points de la série, une seule fois par jour', () async {
    final depot = DemoDepot(lieux, maintenant: maintenant);
    await depot.connexion(email: 'a@b.fr', motDePasse: 'secret');
    final avant = (await depot.joueur('moi').first)!;
    expect(avant.serie, 3);

    final v = await depot.valider(uid: 'moi', jour: jour, lieu: lieux.first, distance: 20, cheminPhoto: '/x.jpg');
    expect(v.serie, 4);
    expect(v.gain, 16);

    final apres = (await depot.joueur('moi').first)!;
    expect(apres.points, avant.points + 16);
    expect(apres.dernierJour, jour);

    expect(
      () => depot.valider(uid: 'moi', jour: jour, lieu: lieux.first, distance: 20, cheminPhoto: '/x.jpg'),
      throwsA(isA<ErreurDepot>()),
    );
  });

  test('le classement est trié par points', () async {
    final depot = DemoDepot(lieux, maintenant: maintenant);
    final classement = await depot.classement().first;
    for (var i = 1; i < classement.length; i++) {
      expect(classement[i - 1].points, greaterThanOrEqualTo(classement[i].points));
    }
  });

  test('pseudos', () {
    expect(erreurPseudo('Maëlle'), isNull);
    expect(erreurPseudo('Yann_56'), isNull);
    expect(erreurPseudo('ab'), isNotNull);
    expect(erreurPseudo('<script>'), isNotNull);
  });
}
