import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/lieu.dart';
import '../domain/modeles.dart';
import '../domain/score.dart';
import 'depot.dart';

/// Le stockage en ligne : Firebase Authentication et Firestore.
///
/// Collections :
///   joueurs/{uid}             pseudo, points, série, validations, dernier jour
///   validations/{jour}_{uid}  une par joueur et par jour, id imposé par les règles
///   photos/{jour}_{uid}       le JPEG de la validation, lisible seulement par
///                             ceux qui ont eux-mêmes validé ce jour-là
///
/// Les photos vivent dans Firestore et non dans Cloud Storage : Storage
/// n'est plus offert sur le forfait gratuit de Firebase, et une photo 3:4
/// de 900 × 1200 tient largement sous la limite de 1 Mo d'un document.
class FirebaseDepot implements Depot {
  FirebaseDepot();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _joueurs => _db.collection('joueurs');
  CollectionReference<Map<String, dynamic>> get _validations => _db.collection('validations');
  CollectionReference<Map<String, dynamic>> get _photos => _db.collection('photos');

  @override
  Stream<String?> get session => _auth.authStateChanges().map((u) => u?.uid);

  @override
  Future<void> connexion({required String email, required String motDePasse}) =>
      _traduire(() => _auth.signInWithEmailAndPassword(email: email.trim(), password: motDePasse));

  @override
  Future<void> inscription({required String pseudo, required String email, required String motDePasse}) =>
      _traduire(() async {
        final cred = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: motDePasse);
        await _joueurs.doc(cred.user!.uid).set({
          'pseudo': pseudo.trim(),
          'points': 0,
          'serie': 0,
          'meilleureSerie': 0,
          'validations': 0,
          'dernierJour': -1,
          'creeLe': FieldValue.serverTimestamp(),
        });
      });

  @override
  Future<void> motDePasseOublie(String email) => _traduire(() => _auth.sendPasswordResetEmail(email: email.trim()));

  @override
  Future<void> deconnexion() => _auth.signOut();

  @override
  Future<void> supprimerCompte(String motDePasse) => _traduire(() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await user.reauthenticateWithCredential(EmailAuthProvider.credential(email: user.email!, password: motDePasse));
    final mes = await _validations.where('uid', isEqualTo: user.uid).get();
    for (final v in mes.docs) {
      await _photos.doc(v.id).delete();
      await v.reference.delete();
    }
    await _joueurs.doc(user.uid).delete();
    await user.delete();
  });

  @override
  Stream<Joueur?> joueur(String uid) =>
      _joueurs.doc(uid).snapshots().map((d) => d.exists ? _joueurDepuis(d.id, d.data()!) : null);

  @override
  Future<void> changerPseudo(String uid, String pseudo) =>
      _traduire(() => _joueurs.doc(uid).update({'pseudo': pseudo.trim()}));

  @override
  Stream<List<Joueur>> classement() => _joueurs
      .orderBy('points', descending: true)
      .limit(100)
      .snapshots()
      .map((q) => [for (final d in q.docs) _joueurDepuis(d.id, d.data())]);

  @override
  // Filtre simple et tri ici : aucun index composé à créer dans la console.
  Stream<List<Validation>> validationsDuJour(int jour) => _validations
      .where('jour', isEqualTo: jour)
      .snapshots()
      .map((q) => [for (final d in q.docs) _validationDepuis(d.data())]..sort((a, b) => a.moment.compareTo(b.moment)));

  @override
  // Un joueur n'a qu'une validation par jour : la liste reste courte, le
  // tri se fait ici plutôt que par un index composé.
  Stream<List<Validation>> historique(String uid) => _validations
      .where('uid', isEqualTo: uid)
      .snapshots()
      .map((q) => [for (final d in q.docs) _validationDepuis(d.data())]..sort((a, b) => b.jour.compareTo(a.jour)));

  @override
  Future<Validation> valider({
    required String uid,
    required int jour,
    required Lieu lieu,
    required double distance,
    required String cheminPhoto,
  }) => _traduire(() async {
    // La photo, la validation et les points partent dans une même
    // transaction : les règles vérifient chacun par les autres (getAfter,
    // existsAfter), et rien n'est écrit si l'un d'eux est refusé.
    final octets = await File(cheminPhoto).readAsBytes();
    final id = '${jour}_$uid';
    final chemin = 'photos/$id';
    final refJoueur = _joueurs.doc(uid);
    final refValidation = _validations.doc(id);
    final refPhoto = _photos.doc(id);
    return _db.runTransaction((tx) async {
      final deja = await tx.get(refValidation);
      if (deja.exists) throw const ErreurDepot('Le lieu du jour est déjà validé.');
      final snap = await tx.get(refJoueur);
      if (!snap.exists) throw const ErreurDepot('Profil introuvable.');
      final j = _joueurDepuis(uid, snap.data()!);

      final serie = serieApres(dernierJour: j.dernierJour, serie: j.serie, jour: jour);
      final gain = gainPour(serie);
      tx.set(refValidation, {
        'uid': uid,
        'pseudo': j.pseudo,
        'jour': jour,
        'lieu': lieu.id,
        'distance': distance.roundToDouble(),
        'gain': gain,
        'serie': serie,
        'photo': chemin,
        'moment': FieldValue.serverTimestamp(),
      });
      tx.set(refPhoto, {'uid': uid, 'jour': jour, 'jpeg': Blob(octets)});
      tx.update(refJoueur, {
        'points': j.points + gain,
        'serie': serie,
        'meilleureSerie': serie > j.meilleureSerie ? serie : j.meilleureSerie,
        'validations': j.validations + 1,
        'dernierJour': jour,
      });
      return Validation(
        uid: uid,
        pseudo: j.pseudo,
        jour: jour,
        lieuId: lieu.id,
        distance: distance,
        gain: gain,
        serie: serie,
        moment: DateTime.now(),
        photo: chemin,
      );
    });
  });

  @override
  Future<List<int>?> photo(String chemin) async {
    try {
      final doc = await _db.doc(chemin).get();
      return (doc.data()?['jpeg'] as Blob?)?.bytes;
    } on FirebaseException {
      // Refusée tant qu'on n'a pas validé soi-même ce jour-là.
      return null;
    }
  }

  static Joueur _joueurDepuis(String uid, Map<String, dynamic> d) => Joueur(
    uid: uid,
    pseudo: d['pseudo'] as String? ?? '?',
    points: (d['points'] as num?)?.toInt() ?? 0,
    serie: (d['serie'] as num?)?.toInt() ?? 0,
    meilleureSerie: (d['meilleureSerie'] as num?)?.toInt() ?? 0,
    validations: (d['validations'] as num?)?.toInt() ?? 0,
    dernierJour: (d['dernierJour'] as num?)?.toInt() ?? -1,
  );

  static Validation _validationDepuis(Map<String, dynamic> d) => Validation(
    uid: d['uid'] as String,
    pseudo: d['pseudo'] as String? ?? '?',
    jour: (d['jour'] as num).toInt(),
    lieuId: d['lieu'] as String? ?? '',
    distance: (d['distance'] as num?)?.toDouble() ?? 0,
    gain: (d['gain'] as num?)?.toInt() ?? 0,
    serie: (d['serie'] as num?)?.toInt() ?? 1,
    // Null le temps que le serveur pose son horodatage.
    moment: (d['moment'] as Timestamp?)?.toDate() ?? DateTime.now(),
    photo: d['photo'] as String?,
  );

  /// Remplace les erreurs Firebase par des messages lisibles.
  static Future<T> _traduire<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseAuthException catch (e) {
      throw ErreurDepot(switch (e.code) {
        'invalid-email' => 'Adresse e-mail invalide.',
        'user-disabled' => 'Ce compte est désactivé.',
        'user-not-found' || 'wrong-password' || 'invalid-credential' => 'E-mail ou mot de passe incorrect.',
        'email-already-in-use' => 'Un compte existe déjà avec cette adresse.',
        'weak-password' => 'Mot de passe trop faible : 6 caractères au moins.',
        'too-many-requests' => 'Trop de tentatives, réessaie dans quelques minutes.',
        'network-request-failed' => 'Pas de connexion à Internet.',
        'requires-recent-login' => 'Reconnecte-toi, puis recommence.',
        'missing-password' => 'Indique ton mot de passe.',
        _ => 'Erreur de connexion (${e.code}).',
      });
    } on FirebaseException catch (e) {
      throw ErreurDepot(switch (e.code) {
        'permission-denied' => 'Refusé par le serveur.',
        'unavailable' => 'Serveur injoignable, vérifie ta connexion.',
        _ => 'Erreur du serveur (${e.code}).',
      });
    }
  }
}
