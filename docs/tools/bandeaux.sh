#!/bin/bash
# Bandeaux de section pour les READMEs de dépôt.
# Même grammaire que ceux du profil : cartouche d'index de largeur fixe,
# titre, puis une règle dont le premier segment reprend l'accent du dépôt.
# L'accent change d'un module à l'autre, le reste ne bouge pas.
D="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$D/langue.sh"
mkdir -p "$D/html$SUF" "$D/sec$SUF"
CH="${CHROME:-/c/Program Files/Google/Chrome/Application/chrome.exe}"
B="$(cd "$D" && pwd -W 2>/dev/null || pwd)"

# sec <clé> <accent> <index> <titre>
sec () {
local key="$1" ac="$2" ix="$3" ti="$4"
cat > "$D/html$SUF/r-$key-$ix.html" <<HTML
<!doctype html><html lang="fr"><head><meta charset="utf-8">
<link href="https://fonts.googleapis.com/css2?family=Syne:wght@800&family=JetBrains+Mono:wght@500&display=swap" rel="stylesheet">
<style>
*{margin:0;padding:0;box-sizing:border-box}
html,body{width:1280px;height:118px;overflow:hidden;background:#0D1117}
.w{width:1280px;height:118px;position:relative;background:#0D1117;
   display:flex;flex-direction:column;justify-content:center;gap:18px;padding:0 60px}
.row{display:flex;align-items:center;gap:20px;height:40px}
.ix{width:52px;height:40px;flex-shrink:0;display:flex;align-items:center;justify-content:center;
    font-family:'JetBrains Mono',monospace;font-size:15px;font-weight:500;letter-spacing:1px;
    color:$ac;border:1.5px solid color-mix(in srgb,$ac 30%,#0D1117);
    background:color-mix(in srgb,$ac 11%,#0D1117);border-radius:6px}
h2{font-family:Syne,sans-serif;font-weight:800;font-size:29px;line-height:40px;letter-spacing:5px;
   color:#F0F4F8;text-transform:uppercase;white-space:nowrap}
.rule{height:2px;display:flex;border-radius:2px;overflow:hidden}
.rule .a{width:52px;flex-shrink:0;background:$ac}
.rule .b{flex:1;background:linear-gradient(90deg,#3A4450 0%,#222A34 42%,transparent 100%)}
</style></head><body>
<div class="w">
  <div class="row"><div class="ix">$ix</div><h2>$ti</h2></div>
  <div class="rule"><i class="a"></i><i class="b"></i></div>
</div></body></html>
HTML
"$CH" --headless=new --disable-gpu --hide-scrollbars --virtual-time-budget=10000 \
  --force-device-scale-factor=2 \
  --screenshot="$B/sec$SUF/r-$key-$ix.png" --window-size=1280,118 "file:///$B/html$SUF/r-$key-$ix.html" >/dev/null 2>&1
}

# rep <clé> <accent> <titre 01> <titre 02> ...
rep () {
local key="$1" ac="$2"; shift 2
local n=1
for t in "$@"; do sec "$key" "$ac" "$(printf '%02d' $n)" "$t"; n=$((n+1)); done
echo "  $key : $(($#)) bandeaux"
}

