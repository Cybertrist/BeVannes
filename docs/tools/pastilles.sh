#!/bin/bash
# Les deux pastilles de langue, en haut de chaque page.
#
# GitHub retire le JavaScript et le CSS des README : rien ne peut basculer
# la page sur place. Ce sont donc deux liens vers deux fichiers, dessinés
# pour se lire comme un sélecteur. La langue courante est allumée dans
# l'accent du profil, l'autre éteinte, reprenant exactement le cartouche
# gris des cartes de projet, celui qui porte « PRIVÉ ».
#
# Les quatre images servent les deux pages : le français monte fr-on et
# en-off, l'anglais monte en-on et fr-off. Elles ne dépendent donc pas de
# LANGUE, et vivent dans docs/langues/.
#
# Leur fond est opaque : GitHub rend les README sur blanc comme sur noir,
# et un sélecteur qui disparaît sur l'un des deux ne sert à rien.
D="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; mkdir -p "$D/html" "$D/langues"
CH="${CHROME:-/c/Program Files/Google/Chrome/Application/chrome.exe}"
B="$(cd "$D" && pwd -W 2>/dev/null || pwd)"

W=300; H=96

# pastille <clé> <libellé> <allumée|éteinte>
pastille () {
local pt ct bd fd
if [ "$3" = allumee ]; then
  pt='<i></i>'; ct='#F0F4F8'; bd='#4A2029'; fd='#160A0E'
else
  pt='';        ct='#7C8894'; bd='#2A333D';             fd='#0C1117'
fi
cat > "$D/html/lg-$1.html" <<HTML
<!doctype html><html lang="fr"><head><meta charset="utf-8">
<link href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@500&display=swap" rel="stylesheet">
<style>
*{margin:0;padding:0;box-sizing:border-box}
html,body{width:${W}px;height:${H}px;overflow:hidden;background:transparent}
.w{width:${W}px;height:${H}px;display:flex;align-items:center;justify-content:center}
.p{display:flex;align-items:center;gap:11px;height:54px;padding:0 26px;
   border-radius:9px;border:1.5px solid $bd;background:$fd}
.p b{font-family:'JetBrains Mono',monospace;font-weight:500;font-size:19px;
     letter-spacing:3.2px;color:$ct;white-space:nowrap}
/* Le point n'est là que sur la langue affichée : il dit « vous êtes ici »
   sans avoir à l'écrire, et laisse l'autre pastille lisible comme un lien. */
.p i{width:8px;height:8px;border-radius:2px;background:#E23B4E;
     transform:rotate(45deg);flex-shrink:0}
</style></head><body><div class="w"><div class="p">$pt<b>$2</b></div></div></body></html>
HTML
"$CH" --headless=new --disable-gpu --hide-scrollbars --virtual-time-budget=10000 \
  --force-device-scale-factor=3 --default-background-color=00000000 \
  --screenshot="$B/langues/$1.png" --window-size=$W,$H "file:///$B/html/lg-$1.html" >/dev/null 2>&1
echo "  $1.png  à afficher sur 150 px"
}

pastille fr-on  "FRANÇAIS" allumee
pastille fr-off "FRANÇAIS" eteinte
pastille en-on  "ENGLISH"  allumee
pastille en-off "ENGLISH"  eteinte
