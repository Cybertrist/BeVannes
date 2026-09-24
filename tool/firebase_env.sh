#!/bin/bash
# Écrit firebase.env.json (ignoré par git) à partir du google-services.json
# téléchargé sur la console Firebase, pour construire la version en ligne :
#
#   bash tool/firebase_env.sh chemin/vers/google-services.json
#   flutter build apk --dart-define-from-file=firebase.env.json
set -e
SOURCE="${1:-android/app/google-services.json}"
D="$(cd "$(dirname "$0")/.." && pwd)"
[ -f "$SOURCE" ] || { echo "introuvable : $SOURCE"; exit 1; }
node -e '
const g = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"));
const c = g.client[0];
const env = {
  FIREBASE_API_KEY: c.api_key[0].current_key,
  FIREBASE_APP_ID: c.client_info.mobilesdk_app_id,
  FIREBASE_SENDER_ID: g.project_info.project_number,
  FIREBASE_PROJECT_ID: g.project_info.project_id,
  FIREBASE_STORAGE_BUCKET: g.project_info.storage_bucket,
};
require("fs").writeFileSync(process.argv[2], JSON.stringify(env, null, 2) + "\n");
console.log("firebase.env.json écrit pour le projet " + env.FIREBASE_PROJECT_ID);
' "$SOURCE" "$D/firebase.env.json"
