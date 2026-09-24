import 'dart:async';
import 'dart:io';

import '../domain/jour.dart';
import '../domain/lieu.dart';
import '../domain/modeles.dart';
import '../domain/score.dart';
import 'depot.dart';

/// Le stockage de démonstration : une petite communauté de joueurs en
/// mémoire, avec un historique crédible, pour essayer l'application sans
/// compte ni serveur. Tout repart de zéro à chaque lancement.
class DemoDepot implements Depot {
  DemoDepot(this._lieux, {DateTime? maintenant}) {
    _aujourdhui = numeroDuJour(maintenant ?? DateTime.now());
    _peupler();
  }

  final List<Lieu> _lieux;
  late final int _aujourdhui;

  static const _moi = 'moi';

  final _joueurs = <String, Joueur>{};
  final _validations = <Validation>[];
  String? _session;

  final _changements = StreamController<void>.broadcast();

  /// Un flux qui donne la valeur actuelle, puis la recalcule à chaque
  /// changement.
  ///
  /// L'abonnement aux changements se fait dès l'écoute : Riverpod met en
  /// pause les flux des onglets cachés, et un générateur async* suspendu sur
  /// son premier yield laissait passer les changements survenus entre-temps.
  Stream<T> _suivre<T>(T Function() lire) => Stream.multi((flux) {
    flux.add(lire());
    final abonnement = _changements.stream.listen((_) => flux.add(lire()));
    flux.onCancel = abonnement.cancel;
  });

  void _notifier() => _changements.add(null);

  Future<void> _latence() => Future.delayed(const Duration(milliseconds: 450));

  // Des Vannetais fictifs, et leurs scores.
  static const _autres = [
    ('Maëlle', 214, 9, 11),
    ('Yann_56', 188, 4, 8),
    ('Nolwenn', 161, 0, 6),
    ('Gwenn.L', 147, 2, 5),
    ('Erwan', 122, 1, 4),
    ('Soazig', 96, 0, 3),
    ('Klervi', 74, 3, 3),
    ('Tugdual', 58, 0, 2),
    ('Ronan K', 41, 1, 2),
    ('Anaïg', 22, 0, 1),
    ('Loïc', 10, 0, 1),
  ];

  void _peupler() {
    for (var i = 0; i < _autres.length; i++) {
      final (pseudo, points, serie, meilleure) = _autres[i];
      final uid = 'j$i';
      _joueurs[uid] = Joueur(
        uid: uid,
        pseudo: pseudo,
        points: points,
        serie: serie,
        meilleureSerie: meilleure,
        validations: points ~/ 11,
        dernierJour: serie > 0 ? _aujourdhui - 1 : _aujourdhui - 4,
      );
    }

    // Le joueur de la démo : une série de trois jours en cours, un trou
    // plus tôt, et le lieu du jour encore à faire.
    final jours = [1, 2, 3, 5, 6, 7, 8, 9, 10, 13];
    var points = 0;
    for (final ecart in jours.reversed) {
      final jour = _aujourdhui - ecart;
      final serie = _serieAu(jours, ecart);
      final gain = gainPour(serie);
      points += gain;
      _validations.add(
        Validation(
          uid: _moi,
          pseudo: 'Tristan',
          jour: jour,
          lieuId: _lieuDu(jour).id,
          distance: 12.0 + (ecart * 7) % 60,
          gain: gain,
          serie: serie,
          moment: dateDuJour(jour).add(Duration(hours: 12 + ecart % 6, minutes: (ecart * 13) % 60)),
        ),
      );
    }
    _joueurs[_moi] = Joueur(
      uid: _moi,
      pseudo: 'Tristan',
      points: points,
      serie: 3,
      meilleureSerie: 6,
      validations: jours.length,
      dernierJour: _aujourdhui - 1,
    );

    // Quatre joueurs sont déjà passés aujourd'hui.
    final lieu = _lieuDu(_aujourdhui);
    final debut = dateDuJour(_aujourdhui);
    for (final (i, heure, minute, distance) in [
      (0, 8, 41, 18.0),
      (1, 9, 17, 34.0),
      (4, 11, 2, 9.0),
      (6, 12, 26, 61.0),
    ]) {
      final j = _joueurs['j$i']!;
      final serie = j.serie + 1;
      final gain = gainPour(serie);
      _joueurs['j$i'] = j.copie(
        points: j.points + gain,
        serie: serie,
        meilleureSerie: serie > j.meilleureSerie ? serie : j.meilleureSerie,
        validations: j.validations + 1,
        dernierJour: _aujourdhui,
      );
      _validations.add(
        Validation(
          uid: 'j$i',
          pseudo: j.pseudo,
          jour: _aujourdhui,
          lieuId: lieu.id,
          distance: distance,
          gain: gain,
          serie: serie,
          moment: DateTime(debut.year, debut.month, debut.day, heure, minute),
        ),
      );
    }
  }

  /// Longueur de la série qui se termine [ecart] jours avant aujourd'hui.
  static int _serieAu(List<int> jours, int ecart) {
    var n = 1;
    while (jours.contains(ecart + n)) {
      n++;
    }
    return n;
  }

  Lieu _lieuDu(int jour) => _lieux[indexDuLieu(jour, _lieux.length)];

  @override
  Stream<String?> get session => _suivre(() => _session);

  @override
  Future<void> connexion({required String email, required String motDePasse}) async {
    await _latence();
    if (!email.contains('@')) throw const ErreurDepot('Adresse e-mail invalide.');
    if (motDePasse.length < 6) throw const ErreurDepot('E-mail ou mot de passe incorrect.');
    _session = _moi;
    _notifier();
  }

  @override
  Future<void> inscription({required String pseudo, required String email, required String motDePasse}) async {
    await _latence();
    if (!email.contains('@')) throw const ErreurDepot('Adresse e-mail invalide.');
    if (motDePasse.length < 6) throw const ErreurDepot('Mot de passe trop faible : 6 caractères au moins.');
    // En démo, l'inscription reprend le joueur existant sous le nouveau pseudo.
    _renommer(pseudo.trim());
    _session = _moi;
    _notifier();
  }

  @override
  Future<void> motDePasseOublie(String email) async {
    await _latence();
    if (!email.contains('@')) throw const ErreurDepot('Adresse e-mail invalide.');
  }

  @override
  Future<void> deconnexion() async {
    _session = null;
    _notifier();
  }

  @override
  Future<void> supprimerCompte() async {
    await _latence();
    _session = null;
    _notifier();
  }

  @override
  Stream<Joueur?> joueur(String uid) => _suivre(() => _joueurs[uid]);

  void _renommer(String pseudo) {
    _joueurs[_moi] = _joueurs[_moi]!.copie(pseudo: pseudo);
    for (var i = 0; i < _validations.length; i++) {
      final v = _validations[i];
      if (v.uid == _moi) {
        _validations[i] = Validation(
          uid: v.uid,
          pseudo: pseudo,
          jour: v.jour,
          lieuId: v.lieuId,
          distance: v.distance,
          gain: v.gain,
          serie: v.serie,
          moment: v.moment,
          photo: v.photo,
        );
      }
    }
  }

  @override
  Future<void> changerPseudo(String uid, String pseudo) async {
    await _latence();
    _renommer(pseudo.trim());
    _notifier();
  }

  @override
  Stream<List<Joueur>> classement() =>
      _suivre(() => _joueurs.values.toList()..sort((a, b) => b.points.compareTo(a.points)));

  @override
  Stream<List<Validation>> validationsDuJour(int jour) =>
      _suivre(() => _validations.where((v) => v.jour == jour).toList()..sort((a, b) => a.moment.compareTo(b.moment)));

  @override
  Stream<List<Validation>> historique(String uid) =>
      _suivre(() => _validations.where((v) => v.uid == uid).toList()..sort((a, b) => b.jour.compareTo(a.jour)));

  @override
  Future<Validation> valider({
    required String uid,
    required int jour,
    required Lieu lieu,
    required double distance,
    required String cheminPhoto,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1100));
    if (_validations.any((v) => v.uid == uid && v.jour == jour)) {
      throw const ErreurDepot('Le lieu du jour est déjà validé.');
    }
    final j = _joueurs[uid]!;
    final serie = serieApres(dernierJour: j.dernierJour, serie: j.serie, jour: jour);
    final gain = gainPour(serie);
    final v = Validation(
      uid: uid,
      pseudo: j.pseudo,
      jour: jour,
      lieuId: lieu.id,
      distance: distance,
      gain: gain,
      serie: serie,
      moment: DateTime.now(),
      photo: cheminPhoto,
    );
    _validations.add(v);
    _joueurs[uid] = j.copie(
      points: j.points + gain,
      serie: serie,
      meilleureSerie: serie > j.meilleureSerie ? serie : j.meilleureSerie,
      validations: j.validations + 1,
      dernierJour: jour,
    );
    _notifier();
    return v;
  }

  @override
  Future<List<int>?> photo(String chemin) async {
    final f = File(chemin);
    return await f.exists() ? f.readAsBytes() : null;
  }
}
