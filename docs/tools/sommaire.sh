#!/bin/bash
# Le sommaire du README : une tuile par section, son icône, son numéro,
# son titre. Une image chacune, pour que chaque tuile mène à sa section.
# Même gabarit que le sommaire de SmartBudget, à l'accent de BeVannes.
D="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$D/langue.sh"
CH="${CHROME:-/c/Program Files/Google/Chrome/Application/chrome.exe}"
B="$(cd "$D" && pwd -W 2>/dev/null || pwd)"
mkdir -p "$D/html$SUF" "$D/som$SUF"
A="#39D2C0"

# tuile <numéro> <icône Material> <titre>
tuile () {
cat > "$D/html$SUF/sommaire-$1.html" <<HTML
<!doctype html><html lang="$LG"><head><meta charset="utf-8">
<link href="https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@600&family=JetBrains+Mono:wght@500&display=swap" rel="stylesheet">
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Rounded:opsz,wght,FILL,GRAD@24,500,1,0" rel="stylesheet">
<style>
*{margin:0;padding:0;box-sizing:border-box}
html,body{width:250px;height:64px;overflow:hidden;background:transparent}
.c{height:64px;display:flex;align-items:center;gap:13px;padding:0 14px;background:#101A1C;border:1px solid #1C2B2D;border-radius:14px}
.ic{font-family:'Material Symbols Rounded';font-size:22px;width:38px;height:38px;flex-shrink:0;border-radius:11px;
  display:flex;align-items:center;justify-content:center;color:$A;background:${A}14;border:1px solid ${A}38;box-shadow:0 0 16px ${A}26}
.n{font-family:'JetBrains Mono',monospace;font-size:11px;color:${A}B0;letter-spacing:1px}
h3{font-family:'Space Grotesk',sans-serif;font-size:14.5px;font-weight:600;line-height:1.2;margin-top:2px;color:#F0F4F8}
</style></head><body>
<div class="c"><span class="ic">$2</span><div><div class="n">$1</div><h3>$3</h3></div></div>
</body></html>
HTML
"$CH" --headless=new --disable-gpu --hide-scrollbars --virtual-time-budget=12000 \
  --force-device-scale-factor=2 --default-background-color=00000000 \
  --screenshot="$B/som$SUF/$1.png" --window-size=250,64 "file:///$B/html$SUF/sommaire-$1.html" >/dev/null 2>&1
}

tuile 01 explore        "$(t 'Fonctionnement' 'How it works')"
tuile 02 memory         "$(t 'Sous le capot' 'Under the hood')"
tuile 03 download       "$(t 'Installation' 'Installation')"
tuile 04 add_location_alt "$(t 'Ajouter des lieux' 'Adding places')"
tuile 05 flag           "$(t 'Limites' 'Limits')"
echo "  sommaire : 5 tuiles"
