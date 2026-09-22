#!/bin/bash
# Étapes verticales reliées par un fil. Pour un parcours long, où chaque
# étape porte deux informations opposées : ce qu'on construit, et ce que
# l'attaque révèle. Un tableau à trois colonnes rendait mal cette tension.
#
# usage : stages <clé> <accent> <libellé A> <libellé B> "Titre|A|B" ...
D="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$D/langue.sh"; mkdir -p "$D/html$SUF" "$D/flow$SUF"
CH="${CHROME:-/c/Program Files/Google/Chrome/Application/chrome.exe}"
B="$(cd "$D" && pwd -W 2>/dev/null || pwd)"

stages () {
local key="$1" ac="$2" la="$3" lb="$4"; shift 4
local body="" i=1 ti a b
for e in "$@"; do
  IFS='|' read -r ti a b <<< "$e"
  body+="<div class=\"st\"><div class=\"ix\">$(printf '%02d' $i)</div><div class=\"bd\">"
  body+="<h3>${ti}</h3>"
  body+="<div class=\"l\"><span class=\"k a\">${la}</span><p>${a}</p></div>"
  body+="<div class=\"l\"><span class=\"k b\">${lb}</span><p>${b}</p></div>"
  body+="</div></div>"
  i=$((i+1))
done

cat > "$D/html$SUF/v-$key.html" <<HTML
<!doctype html><html lang="fr"><head><meta charset="utf-8">
<link href="https://fonts.googleapis.com/css2?family=Syne:wght@800&family=Space+Grotesk:wght@400&family=JetBrains+Mono:wght@500&display=swap" rel="stylesheet">
<style>
*{margin:0;padding:0;box-sizing:border-box}
html,body{width:1280px;background:#0D1117}
.w{width:1280px;background:#0D1117;padding:24px 56px}
.st{display:flex;gap:22px;position:relative;padding-bottom:16px}
.st:last-child{padding-bottom:0}
/* Le fil qui relie les index, interrompu sous le dernier. */
.st:not(:last-child)::before{content:"";position:absolute;left:21px;top:46px;bottom:0;
  width:2px;background:linear-gradient(180deg,${ac}55,${ac}18)}
.ix{width:44px;height:44px;flex-shrink:0;display:flex;align-items:center;justify-content:center;
    font-family:'JetBrains Mono',monospace;font-size:13px;letter-spacing:1px;color:$ac;
    border:1.5px solid ${ac}45;background:${ac}0F;border-radius:10px;z-index:1}
.bd{flex:1;background:#131A24;border:1px solid #1F2833;border-radius:12px;padding:16px 20px;
    display:flex;flex-direction:column;gap:9px;margin-bottom:14px}
h3{font-family:Syne,sans-serif;font-weight:800;font-size:17px;color:#F0F4F8;line-height:1.25}
.l{display:flex;align-items:flex-start;gap:12px}
.k{font-family:'JetBrains Mono',monospace;font-size:10px;letter-spacing:1.3px;
   flex-shrink:0;width:96px;border-radius:5px;padding:4px 0;text-align:center;line-height:1.3;margin-top:1px}
.k.a{color:$ac;background:${ac}14;border:1px solid ${ac}30}
.k.b{color:#E2725F;background:#E2725F12;border:1px solid #E2725F2E}
.l p{font-family:'Space Grotesk',sans-serif;font-size:13.5px;line-height:1.45;color:#8E9BAA}
code{font-family:'JetBrains Mono',monospace;font-size:12.5px;color:#C3CCD7}
</style></head><body>
<div class="w">$body</div>
<script>document.fonts.ready.then(()=>{
  document.title='H'+Math.ceil(document.querySelector('.w').getBoundingClientRect().height);});
</script></body></html>
HTML

local H
H="$("$CH" --headless=new --disable-gpu --virtual-time-budget=9000 --dump-dom \
      "file:///$B/html$SUF/v-$key.html" 2>/dev/null | grep -o '<title>H[0-9]*' | grep -o '[0-9]*' | head -1)"
[ -z "$H" ] && { echo "  ECHEC mesure : $key" >&2; return 1; }
"$CH" --headless=new --disable-gpu --hide-scrollbars --virtual-time-budget=9000 \
  --force-device-scale-factor=2 \
  --screenshot="$B/flow$SUF/$key.png" --window-size=1280,$H "file:///$B/html$SUF/v-$key.html" >/dev/null 2>&1
echo "  $key.png  ${H}px"
}
