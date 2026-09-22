#!/bin/bash
# Grille de cartes : ce que les tableaux à deux ou trois colonnes disaient.
# Une commande, un paramètre, une variable d'environnement se lisent comme
# une fiche, pas comme une ligne. La carte donne au nom la place d'être vu.
#
# La hauteur dépend du nombre de cartes et du repli des textes : Chrome la
# mesure d'abord, la capture arrive ensuite.
#
# usage : grid <clé> <accent> <colonnes> <entrées...>
#         entrée : "NOM|description"  ou  "NOM|badge|description"
#
# Le nom et le badge sont échappés : « /ban <user> » s'écrit tel quel, ses
# chevrons ne sont pas pris pour une balise. La description, elle, reste du
# HTML, c'est là que vit <code>.
D="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$D/langue.sh"
mkdir -p "$D/html$SUF" "$D/grid$SUF"
CH="${CHROME:-/c/Program Files/Google/Chrome/Application/chrome.exe}"
B="$(cd "$D" && pwd -W 2>/dev/null || pwd)"

# Les chevrons deviennent des entités. Le & n'est pas touché, pour qu'un
# appelant qui écrit déjà &lt; ne se retrouve pas avec &amp;lt;.
#
# Le passage par sed n'est pas un détour : depuis bash 5.2, un & nu dans le
# remplacement de ${var//motif/remplacement} désigne le texte trouvé, et
# &lt; y devient <lt;.
esc () { printf '%s' "$1" | sed -e 's/</\&lt;/g' -e 's/>/\&gt;/g'; }

grid () {
local key="$1" ac="$2" cols="$3"; shift 3
local cards=""
local e nm bd tx
for e in "$@"; do
  IFS='|' read -r a b c <<< "$e"
  if [ -n "$c" ]; then nm="$a"; bd="$b"; tx="$c"; else nm="$a"; bd=""; tx="$b"; fi
  nm="$(esc "$nm")"; bd="$(esc "$bd")"
  cards+="<div class=\"c\"><div class=\"hd\"><span class=\"nm\">${nm}</span>"
  [ -n "$bd" ] && cards+="<span class=\"bd\">${bd}</span>"
  cards+="</div><p>${tx}</p></div>"
done

cat > "$D/html$SUF/g-$key.html" <<HTML
<!doctype html><html lang="fr"><head><meta charset="utf-8">
<link href="https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@400&family=JetBrains+Mono:wght@500&display=swap" rel="stylesheet">
<style>
*{margin:0;padding:0;box-sizing:border-box}
html,body{width:1280px;background:#0D1117}
.w{width:1280px;background:#0D1117;padding:22px 56px;
   display:grid;grid-template-columns:repeat($cols,1fr);gap:14px}
.c{background:#131A24;border:1px solid #1F2833;border-radius:11px;padding:15px 17px;
   display:flex;flex-direction:column;gap:7px}
.hd{display:flex;align-items:center;gap:9px;flex-wrap:wrap}
.nm{font-family:'JetBrains Mono',monospace;font-size:13.5px;letter-spacing:.3px;color:$ac}
.bd{font-family:'JetBrains Mono',monospace;font-size:10px;letter-spacing:1.2px;text-transform:uppercase;
    color:#6E7B8A;border:1px solid #273140;border-radius:4px;padding:2.5px 7px}
.c p{font-family:'Space Grotesk',sans-serif;font-size:13.5px;line-height:1.45;color:#8E9BAA}
code{font-family:'JetBrains Mono',monospace;font-size:12.5px;color:#C3CCD7}
</style></head><body>
<div class="w">$cards</div>
<script>document.fonts.ready.then(()=>{
  document.title='H'+Math.ceil(document.querySelector('.w').getBoundingClientRect().height);});
</script></body></html>
HTML

local H
H="$("$CH" --headless=new --disable-gpu --virtual-time-budget=9000 --dump-dom \
      "file:///$B/html$SUF/g-$key.html" 2>/dev/null | grep -o '<title>H[0-9]*' | grep -o '[0-9]*' | head -1)"
[ -z "$H" ] && { echo "  ECHEC mesure : $key" >&2; return 1; }
"$CH" --headless=new --disable-gpu --hide-scrollbars --virtual-time-budget=9000 \
  --force-device-scale-factor=2 \
  --screenshot="$B/grid$SUF/$key.png" --window-size=1280,$H "file:///$B/html$SUF/g-$key.html" >/dev/null 2>&1
echo "  $key.png  ${H}px"
}
