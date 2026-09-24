#!/bin/bash
# Le bouton de téléchargement de l'application, dans le README.
#
# Une image et non un vrai bouton : GitHub retire le CSS des README. Elle
# est posée dans un lien vers le dernier APK des Releases, dont l'adresse
# ne change jamais d'une version à l'autre. Seul le texte suit la version,
# lue dans pubspec.yaml, et la taille, lue sur l'APK s'il existe.
#
# Le bouton est opaque, seuls ses coins arrondis sont transparents : GitHub
# rend les README sur blanc comme sur noir.
#
#   bash docs/tools/telecharger.sh              français, docs/telecharger.png
#   LANGUE=en bash docs/tools/telecharger.sh    anglais, docs/en/telecharger.png
#   VARIANTE=demo bash docs/tools/telecharger.sh  le bouton de la démo, telecharger-demo.png
#
# Deux applications, deux boutons : la vraie (BeVannes.apk) et la démo
# (BeVannes-demo.apk), qui s'installent côte à côte.
D="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$D/langue.sh"
mkdir -p "$D/html$SUF"
CH="${CHROME:-/c/Program Files/Google/Chrome/Application/chrome.exe}"
B="$(cd "$D" && pwd -W 2>/dev/null || pwd)"
R="$D/../.."
OUT="$R/docs"; [ "$LG" = en ] && OUT="$R/docs/en"

VERSION="$(grep -m1 '^version:' "$R/pubspec.yaml" | sed 's/version: *//; s/+.*//')"
if [ "$VARIANTE" = demo ]; then
  APK="$R/build/BeVannes-demo.apk"; NOM=telecharger-demo
  TITRE="$(t 'Essayer la démo' 'Try the demo')"; SOUS="$(t 'démo, sans compte' 'demo, no account')"
  FOND='linear-gradient(100deg,#0A1512 0%,#07100E 55%,#050B0A 100%)'; BORD='#24413C'
  FLECHE='background:transparent;border:2px solid #39D2C0'; TRAIT='#39D2C0'
else
  APK="$R/build/BeVannes.apk"; NOM=telecharger
  TITRE="$(t 'Télécharger BeVannes' 'Download BeVannes')"; SOUS="$(t 'version complète' 'full version')"
  FOND='linear-gradient(100deg,#0C2420 0%,#081916 55%,#050F0D 100%)'; BORD='#1C4A43'
  FLECHE='background:linear-gradient(135deg,#A7F3E6,#39D2C0)'; TRAIT='#02221E'
fi
TAILLE=""
if [ -f "$APK" ]; then
  MO=$(( ($(wc -c < "$APK") + 524288) / 1048576 ))
  TAILLE=" · $MO $(t 'Mo' 'MB')"
fi

W=720; H=132
cat > "$D/html$SUF/$NOM.html" <<HTML
<!doctype html><html lang="$LG"><head><meta charset="utf-8">
<link href="https://fonts.googleapis.com/css2?family=Syne:wght@800&family=JetBrains+Mono:wght@500&display=swap" rel="stylesheet">
<style>
*{margin:0;padding:0;box-sizing:border-box}
html,body{width:${W}px;height:${H}px;overflow:hidden;background:transparent}
.w{width:${W}px;height:${H}px;display:flex;align-items:center;gap:22px;padding:0 30px 0 22px;
   border-radius:18px;border:1.5px solid $BORD;
   background:$FOND}
.i{width:84px;height:84px;border-radius:22px;overflow:hidden;flex-shrink:0;
   box-shadow:0 10px 28px -8px rgba(57,210,192,.55)}
.i img{width:100%;height:100%;object-fit:cover}
.t{flex:1;display:flex;flex-direction:column;gap:9px}
.t b{font-family:Syne,sans-serif;font-weight:800;font-size:25px;letter-spacing:.6px;color:#F0F4F8;white-space:nowrap}
.t span{font-family:'JetBrains Mono',monospace;font-size:14px;color:#9AA5B1;letter-spacing:.3px}
.f{width:58px;height:58px;border-radius:16px;flex-shrink:0;display:flex;align-items:center;justify-content:center;
   $FLECHE}
</style></head><body><div class="w">
  <div class="i"><img src="file:///$B/../../assets/icon/icon.png"></div>
  <div class="t">
    <b>$TITRE</b>
    <span>v$VERSION · Android · $SOUS$TAILLE</span>
  </div>
  <div class="f"><svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="$TRAIT"
       stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round">
    <path d="M12 4v12"/><path d="M6 11l6 6 6-6"/><path d="M5 21h14"/></svg></div>
</div></body></html>
HTML
OUTW="$(cd "$OUT" && pwd -W 2>/dev/null || pwd)"
"$CH" --headless=new --disable-gpu --hide-scrollbars --allow-file-access-from-files --virtual-time-budget=10000 \
  --force-device-scale-factor=2 --default-background-color=00000000 --window-size=$W,$H \
  --screenshot="$OUTW/$NOM.png" "file:///$B/html$SUF/$NOM.html" >/dev/null 2>&1
echo "  $NOM.png  v$VERSION$TAILLE"
