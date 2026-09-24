/// Ce que l'application attend de son stockage, en ligne ou en démo.
library;

import '../domain/lieu.dart';
import '../domain/modeles.dart';

/// Une erreur à montrer telle quelle au joueur.
class ErreurDepot implements Exception {
  const ErreurDepot(this.message);
  final String message;
  @override
  String toString() => message;
}

abstract class Depot {
  /// L'identifiant du joueur connecté, ou null.
  Stream<String?> get session;

  Future<void> connexion({required String email, required String motDePasse});
  Future<void> inscription({required String pseudo, required String email, required String motDePasse});
  Future<void> motDePasseOublie(String email);
  Future<void> deconnexion();

  /// Efface le joueur, ses validations et ses photos, puis le compte.
  Future<void> supprimerCompte();

  Stream<Joueur?> joueur(String uid);
  Future<void> changerPseudo(String uid, String pseudo);

  /// Les meilleurs joueurs, par points décroissants.
  Stream<List<Joueur>> classement();

  /// Les validations d'un jour, de la plus ancienne à la plus récente.
  Stream<List<Validation>> validationsDuJour(int jour);

  /// Les validations d'un joueur, de la plus récente à la plus ancienne.
  Stream<List<Validation>> historique(String uid);

  /// Enregistre la photo et les points, d'un bloc : soit tout passe, soit
  /// rien. Échoue si le lieu du jour est déjà validé.
  Future<Validation> valider({
    required String uid,
    required int jour,
    required Lieu lieu,
    required double distance,
    required String cheminPhoto,
  });

  /// Les octets d'une photo, pour l'afficher. Null si elle est illisible
  /// (en ligne, il faut avoir soi-même validé le jour pour voir celles des
  /// autres).
  Future<List<int>?> photo(String chemin);
}

/// Vérifie un pseudo : 3 à 20 caractères, lettres, chiffres, espace, point,
/// tiret et tiret bas. Même règle que firestore.rules.
String? erreurPseudo(String pseudo) {
  final p = pseudo.trim();
  if (p.length < 3) return 'Au moins 3 caractères';
  if (p.length > 20) return '20 caractères au plus';
  if (!RegExp(r'^[\p{L}\p{N} ._\-]+$', unicode: true).hasMatch(p)) {
    return 'Lettres, chiffres, espaces et . _ - seulement';
  }
  return null;
}
