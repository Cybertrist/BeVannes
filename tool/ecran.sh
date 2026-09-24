#!/bin/bash
# Pilote l'émulateur pour vérifier l'application écran par écran.
#
#   bash tool/ecran.sh tap 540 1700      toucher un point (pixels réels)
#   bash tool/ecran.sh swipe haut        faire défiler vers le bas du contenu
#   bash tool/ecran.sh shot nom          capturer l'écran dans tool/captures/nom.png
#   bash tool/ecran.sh lancer            relancer l'application à froid
#   bash tool/ecran.sh gps 47.6545 -2.758  placer l'émulateur (latitude, longitude)
#
# Chaque geste attend que l'écran se stabilise avant de rendre la main.
set -e
ADB="${ADB:-/c/src/android/platform-tools/adb}"
D="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$D/captures"

case "$1" in
  tap) "$ADB" shell input tap "$2" "$3"; sleep "${4:-1.2}" ;;
  swipe)
    if [ "$2" = haut ]; then "$ADB" shell input swipe 540 1700 540 600 350
    else "$ADB" shell input swipe 540 600 540 1700 350; fi
    sleep 1 ;;
  shot) "$ADB" exec-out screencap -p > "$D/captures/$2.png"; echo "  tool/captures/$2.png" ;;
  lancer)
    "$ADB" shell am force-stop fr.bevannes.bevannes
    "$ADB" shell am start -n fr.bevannes.bevannes/.MainActivity > /dev/null
    sleep "${2:-6}" ;;
  gps) "$ADB" emu geo fix "$3" "$2" > /dev/null; sleep 1 ;;
  *) echo "usage : ecran.sh tap x y | swipe haut|bas | shot nom | lancer | gps lat lng"; exit 1 ;;
esac
