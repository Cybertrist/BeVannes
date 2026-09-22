#!/bin/bash
# Séquence : des étapes qui s'enchaînent, reliées par une flèche. À ne pas
# confondre avec la grille, qui présente des éléments sans ordre entre eux.
# La hauteur est mesurée par Chrome avant la capture, le nombre de cartes
# et la longueur des textes changeant d'un module à l'autre.
#
# usage : seq <clé> <accent> "Titre|Texte" ...
D="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$D/langue.sh"
mkdir -p "$D/html$SUF" "$D/flow$SUF"
CH="${CHROME:-/c/Program Files/Google/Chrome/Application/chrome.exe}"
B="$(cd "$D" && pwd -W 2>/dev/null || pwd)"

seqfig () {
local key="$1" ac="$2"; shift 2
local body="" i=1 first=1
local e ti tx
for e in "$@"; do
  IFS='|' read -r ti tx <<< "$e"
  [ $first -eq 0 ] && body+='<div class="ar"><svg width="24" height="14" viewBox="0 0 26 14" fill="none"><path d="M0 7h22M17 2l5 5-5 5" stroke="#2F3A47" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg></div>'
  first=0
  body+="<div class=\"c\"><div class=\"ix\">$(printf '%02d' $i)</div><h3>${ti}</h3><p>${tx}</p></div>"
  i=$((i+1))
done

cat > "$D/html$SUF/s-$key.html" <<HTML
<!doctype html><html lang="fr"><head><meta charset="utf-8">
<link href="https://fonts.googleapis.com/css2?family=Syne:wght@800&family=Space+Grotesk:wght@400&family=JetBrains+Mono:wght@500&display=swap" rel="stylesheet">
<style>
*{margin:0;padding:0;box-sizing:border-box}
html,body{width:1280px;background:#0D1117}
.w{width:1280px;background:#0D1117;padding:24px 56px;display:flex;align-items:stretch}
.c{flex:1;min-width:0;background:#131A24;border:1px solid #1F2833;border-radius:12px;padding:18px 20px;
   display:grid;grid-template-rows:15px 52px 1fr;row-gap:10px}
.ix{font-family:'JetBrains Mono',monospace;font-size:11.5px;letter-spacing:2px;color:$ac;line-height:15px}
h3{font-family:Syne,sans-serif;font-weight:800;font-size:18px;line-height:26px;color:#F0F4F8;overflow-wrap:break-word}
.c p{font-family:'Space Grotesk',sans-serif;font-size:13.5px;line-height:1.45;color:#8B97A6}
code{font-family:'JetBrains Mono',monospace;font-size:12.5px;color:$ac}
.ar{width:46px;flex-shrink:0;display:flex;align-items:center;justify-content:center}
</style></head><body>
<div class="w">$body</div>
<script>document.fonts.ready.then(()=>{
  document.title='H'+Math.ceil(document.querySelector('.w').getBoundingClientRect().height);});
</script></body></html>
HTML

local H
H="$("$CH" --headless=new --disable-gpu --virtual-time-budget=9000 --dump-dom \
      "file:///$B/html$SUF/s-$key.html" 2>/dev/null | grep -o '<title>H[0-9]*' | grep -o '[0-9]*' | head -1)"
[ -z "$H" ] && { echo "  ECHEC mesure : $key" >&2; return 1; }
"$CH" --headless=new --disable-gpu --hide-scrollbars --virtual-time-budget=9000 \
  --force-device-scale-factor=2 \
  --screenshot="$B/flow$SUF/$key.png" --window-size=1280,$H "file:///$B/html$SUF/s-$key.html" >/dev/null 2>&1
echo "  $key.png  ${H}px"
}
