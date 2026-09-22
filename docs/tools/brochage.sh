#!/bin/bash
# Brochage d'un module, dessiné : la carte au centre, ses broches réparties
# de part et d'autre, chacune reliée à ce qu'elle pilote ou à ce qu'elle lit.
# Par convention on met les sorties à gauche et les entrées à droite, pour
# qu'un coup d'oeil suffise à voir ce qui commande et ce qui mesure.
#
# usage : pinout <clé> <accent> <titre carte> <gauche...> -- <droite...>
#         chaque entrée : "GPIO|Nom|Rôle"
D="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$D/langue.sh"
mkdir -p "$D/html$SUF" "$D/pin$SUF"
CH="${CHROME:-/c/Program Files/Google/Chrome/Application/chrome.exe}"
B="$(cd "$D" && pwd -W 2>/dev/null || pwd)"

pinout () {
local key="$1" ac="$2" board="$3" capL="$4" capR="$5"; shift 5
local left=() right=() side=L
for e in "$@"; do
  if [ "$e" = "--" ]; then side=R; continue; fi
  if [ "$side" = L ]; then left+=("$e"); else right+=("$e"); fi
done

local nl=${#left[@]} nr=${#right[@]}
local n=$nl; [ $nr -gt $n ] && n=$nr
local H=$(( n*66 + 114 ))
local boardH=$(( n*66 + 28 ))

# Boîtes et traces, positionnées au pixel : la carte ne bouge pas, les
# lignes partent toujours du même x, seule la hauteur suit le nombre de broches.
local boxes="" traces=""
local i y top
for ((i=0;i<nl;i++)); do
  IFS='|' read -r g nm ro <<< "${left[$i]}"
  y=$(( 107 + i*66 )); top=$(( y - 27 ))
  boxes+="<div class=\"bx l\" style=\"top:${top}px\"><div class=\"nm\">${nm}</div><div class=\"ro\">${ro}</div></div>"
  boxes+="<div class=\"pin l\" style=\"top:$(( y - 12 ))px\">${g}</div>"
  traces+="<path d=\"M386 ${y}h104\"/><circle cx=\"386\" cy=\"${y}\" r=\"3.5\"/>"
done
for ((i=0;i<nr;i++)); do
  IFS='|' read -r g nm ro <<< "${right[$i]}"
  y=$(( 107 + i*66 )); top=$(( y - 27 ))
  boxes+="<div class=\"bx r\" style=\"top:${top}px\"><div class=\"nm\">${nm}</div><div class=\"ro\">${ro}</div></div>"
  boxes+="<div class=\"pin r\" style=\"top:$(( y - 12 ))px\">${g}</div>"
  traces+="<path d=\"M790 ${y}h104\"/><circle cx=\"894\" cy=\"${y}\" r=\"3.5\"/>"
done

cat > "$D/html$SUF/p-$key.html" <<HTML
<!doctype html><html lang="fr"><head><meta charset="utf-8">
<link href="https://fonts.googleapis.com/css2?family=Syne:wght@800&family=Space+Grotesk:wght@400&family=JetBrains+Mono:wght@500&display=swap" rel="stylesheet">
<style>
*{margin:0;padding:0;box-sizing:border-box}
html,body{width:1280px;height:${H}px;overflow:hidden;background:#0D1117}
.w{width:1280px;height:${H}px;background:#0D1117;position:relative}

/* La carte : un rectangle sobre, une trame de cuivre à peine lisible,
   et le nom au centre. Elle n'est pas le sujet, les broches le sont. */
.brd{position:absolute;left:490px;top:60px;width:300px;height:${boardH}px;
     background:linear-gradient(160deg,#18202B 0%,#121922 100%);
     border:1px solid #2A3644;border-radius:14px;
     display:flex;align-items:center;justify-content:center;overflow:hidden}
.brd::before{content:"";position:absolute;inset:0;opacity:.5;
  background-image:linear-gradient(${ac}0A 1px,transparent 1px),linear-gradient(90deg,${ac}0A 1px,transparent 1px);
  background-size:22px 22px}
.brd span{position:relative;font-family:'JetBrains Mono',monospace;font-weight:500;font-size:19px;
  letter-spacing:2.4px;color:#D7E0EA;text-align:center;line-height:1.55}

/* Étiquette de broche, posée sur le bord de la carte. */
.pin{position:absolute;height:24px;min-width:42px;padding:0 9px;display:flex;
     align-items:center;justify-content:center;border-radius:6px;
     font-family:'JetBrains Mono',monospace;font-size:12px;letter-spacing:.6px;
     color:${ac};background:#0D1117;border:1px solid ${ac}45;z-index:2}
.pin.l{left:469px}
.pin.r{right:469px}

.bx{position:absolute;width:330px;height:54px;padding:8px 15px;
    background:#131A24;border:1px solid #1F2833;border-radius:10px;
    display:flex;flex-direction:column;justify-content:center;gap:2px}
.bx.l{left:56px;text-align:right}
.bx.r{right:56px}
.nm{font-family:'Space Grotesk',sans-serif;font-size:14.5px;color:#E2E9F1;line-height:1.2}
.ro{font-family:'Space Grotesk',sans-serif;font-size:12.5px;color:#7F8C9B;line-height:1.2}
.ov{position:absolute;inset:0;pointer-events:none}
.cap{position:absolute;top:26px;width:330px;font-family:'JetBrains Mono',monospace;font-size:10.5px;letter-spacing:1.6px;color:#4E5A68}
.cap.l{left:56px;text-align:right}
.cap.r{right:56px}
</style></head><body><div class="w">
<div class="cap l">${capL}</div><div class="cap r">${capR}</div>
<div class="brd"><span>${board}</span></div>
${boxes}
<svg class="ov" viewBox="0 0 1280 ${H}">
  <g stroke="#2C3644" stroke-width="1.6" fill="#2C3644">${traces}</g>
</svg>
</div></body></html>
HTML
"$CH" --headless=new --disable-gpu --hide-scrollbars --virtual-time-budget=11000 \
  --force-device-scale-factor=2 \
  --screenshot="$B/pin$SUF/$key.png" --window-size=1280,$H "file:///$B/html$SUF/p-$key.html" >/dev/null 2>&1
echo "  $key.png  ${H}px"
}

