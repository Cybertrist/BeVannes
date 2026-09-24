/// Réglages choisis à la compilation, par --dart-define.
///
///   flutter build apk --dart-define-from-file=firebase.env.json
///   flutter build apk --dart-define=DEMO=true
///
/// firebase.env.json (ignoré par git) se génère depuis google-services.json
/// avec tool/firebase_env.sh.
library;

const _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
const _appId = String.fromEnvironment('FIREBASE_APP_ID');
const _senderId = String.fromEnvironment('FIREBASE_SENDER_ID');
const _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
const _storageBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');

/// Les identifiants du projet Firebase, ou null s'ils n'ont pas été fournis.
({String apiKey, String appId, String senderId, String projectId, String storageBucket})? get configFirebase =>
    _apiKey.isEmpty || _appId.isEmpty || _projectId.isEmpty
    ? null
    : (apiKey: _apiKey, appId: _appId, senderId: _senderId, projectId: _projectId, storageBucket: _storageBucket);

/// Mode démo : des joueurs en mémoire, sans compte ni réseau (sauf les
/// tuiles de la carte). Actif avec DEMO=true, ou faute de configuration
/// Firebase, pour qu'un APK construit sans rien ne s'ouvre jamais sur une
/// erreur.
final modeDemo = const bool.fromEnvironment('DEMO') || configFirebase == null;
