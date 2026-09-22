#!/bin/bash
# Arborescence dessinée. Les traits de liaison sont calculés, pas écrits à
# la main : pour chaque ligne on regarde s'il reste un frère plus bas, ce
# qui donne le coude, et quels ancêtres ont encore des enfants, ce qui
# donne les gouttières verticales. Ajouter une entrée ne demande donc pas
# de redessiner les branches.
#
# usage : tree <clé> <accent> <racine> "profondeur|nom|description" ...
#         profondeur 1 = enfant direct de la racine
D="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$D/langue.sh"
mkdir -p "$D/html$SUF" "$D/tree$SUF"
CH="${CHROME:-/c/Program Files/Google/Chrome/Application/chrome.exe}"
B="$(cd "$D" && pwd -W 2>/dev/null || pwd)"

ICO_DIR='<svg viewBox="0 0 20 20" fill="none"><path d="M2 5.2c0-.9.7-1.6 1.6-1.6h3.2l1.7 1.9h7.9c.9 0 1.6.7 1.6 1.6v7.7c0 .9-.7 1.6-1.6 1.6H3.6c-.9 0-1.6-.7-1.6-1.6z" stroke="currentColor" stroke-width="1.5" stroke-linejoin="round"/></svg>'
ICO_FILE='<svg viewBox="0 0 20 20" fill="none"><path d="M4.5 3.2h6.3l4.7 4.7v8.9c0 .5-.4.9-.9.9H4.5c-.5 0-.9-.4-.9-.9V4.1c0-.5.4-.9.9-.9z" stroke="currentColor" stroke-width="1.5" stroke-linejoin="round"/><path d="M10.8 3.2v4.7h4.7" stroke="currentColor" stroke-width="1.5" stroke-linejoin="round"/></svg>'

treefig () {
local key="$1" ac="$2" root="$3"; shift 3
local -a dep nam des
local n=0 e d nm ds
for e in "$@"; do
  IFS='|' read -r d nm ds <<< "$e"
  dep[$n]=$d; nam[$n]="$nm"; des[$n]="$ds"; n=$((n+1))
done

local body="" i j k last cont gut elb ico cls
for ((i=0;i<n;i++)); do
  d=${dep[$i]}; nm="${nam[$i]}"; ds="${des[$i]}"

  # Reste-t-il un frère à la même profondeur sous cette ligne ?
  last=1
  for ((j=i+1;j<n;j++)); do
    [ ${dep[$j]} -lt $d ] && break
    [ ${dep[$j]} -eq $d ] && { last=0; break; }
  done

  # Les ancêtres qui ont encore des enfants gardent leur gouttière.
  gut=""
  for ((k=1;k<d;k++)); do
    cont=0
    for ((j=i+1;j<n;j++)); do
      [ ${dep[$j]} -lt $k ] && break
      [ ${dep[$j]} -eq $k ] && { cont=1; break; }
    done
    [ $cont -eq 1 ] && gut+='<i class="v"></i>' || gut+='<i></i>'
  done

  elb='<i class="e"></i>'; [ $last -eq 1 ] && elb='<i class="e l"></i>'
  case "$nm" in
    */) ico="$ICO_DIR"; cls="d" ;;
    *)  ico="$ICO_FILE"; cls="f" ;;
  esac
  body+="<div class=\"r\"><div class=\"lf\">${gut}${elb}<span class=\"ic ${cls}\">${ico}</span><span class=\"nm ${cls}\">${nm}</span></div><div class=\"ds\">${ds}</div></div>"
done

cat > "$D/html$SUF/t-$key.html" <<HTML
<!doctype html><html lang="fr"><head><meta charset="utf-8">
<link href="https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@400&family=JetBrains+Mono:wght@500&display=swap" rel="stylesheet">
<style>
*{margin:0;padding:0;box-sizing:border-box}
html,body{width:1280px;background:#0D1117}
.w{width:1280px;background:#0D1117;padding:24px 56px}
.bx{background:#131A24;border:1px solid #1F2833;border-radius:12px;padding:18px 22px 20px}
.rt{display:flex;align-items:center;gap:10px;padding-bottom:12px;margin-bottom:4px;
    border-bottom:1px solid #1B2430}
.rt .ic{width:20px;height:20px;color:$ac;display:block}
.rt span{font-family:'JetBrains Mono',monospace;font-size:14px;color:#E6EDF5;letter-spacing:.3px}
.r{display:flex;align-items:center;height:38px}
.lf{display:flex;align-items:center;width:330px;flex-shrink:0;height:38px}
/* Gouttières et coudes : une cellule de 26 px par niveau. */
.lf i{width:26px;height:38px;flex-shrink:0;position:relative;display:block}
.lf i.v::before,.lf i.e::before{content:"";position:absolute;left:9px;top:0;bottom:0;width:1.5px;background:#26313E}
.lf i.e.l::before{bottom:19px}
.lf i.e::after{content:"";position:absolute;left:9px;top:19px;width:13px;height:1.5px;background:#26313E}
.ic{width:19px;height:19px;flex-shrink:0;margin:0 9px 0 4px;display:block}
.ic.d{color:$ac}.ic.f{color:#5E6B7B}
.nm{font-family:'JetBrains Mono',monospace;font-size:13.5px;letter-spacing:.2px;white-space:nowrap}
.nm.d{color:#E6EDF5}.nm.f{color:#94A1B0}
.ds{font-family:'Space Grotesk',sans-serif;font-size:13.5px;line-height:1.4;color:#8B97A6}
</style></head><body>
<div class="w"><div class="bx">
  <div class="rt"><span class="ic">$ICO_DIR</span><span>$root</span></div>
  $body
</div></div>
<script>document.fonts.ready.then(()=>{
  document.title='H'+Math.ceil(document.querySelector('.w').getBoundingClientRect().height);});
</script></body></html>
HTML

local H
H="$("$CH" --headless=new --disable-gpu --virtual-time-budget=9000 --dump-dom \
      "file:///$B/html$SUF/t-$key.html" 2>/dev/null | grep -o '<title>H[0-9]*' | grep -o '[0-9]*' | head -1)"
[ -z "$H" ] && { echo "  ECHEC mesure : $key" >&2; return 1; }
"$CH" --headless=new --disable-gpu --hide-scrollbars --virtual-time-budget=9000 \
  --force-device-scale-factor=2 \
  --screenshot="$B/tree$SUF/$key.png" --window-size=1280,$H "file:///$B/html$SUF/t-$key.html" >/dev/null 2>&1
echo "  $key.png  ${H}px"
}
