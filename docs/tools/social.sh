#!/bin/bash
# L'image d'aperçu du dépôt, celle que GitHub, Discord ou LinkedIn montrent
# quand le lien est partagé : 1280 x 640, la taille que GitHub recommande.
# Le logo et le nom à gauche, deux écrans de l'application à droite.
# En français seulement : GitHub n'en accepte qu'une.
#
# À déposer à la main dans Settings > General > Social preview, GitHub ne
# la lit pas depuis le dépôt.
D="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CH="${CHROME:-/c/Program Files/Google/Chrome/Application/chrome.exe}"
B="$(cd "$D" && pwd -W 2>/dev/null || pwd)"
mkdir -p "$D/html"

cat > "$D/html/social.html" <<HTML
<!doctype html><html lang="fr"><head><meta charset="utf-8">
<link href="https://fonts.googleapis.com/css2?family=Syne:wght@800&family=Space+Grotesk:wght@400;500&family=JetBrains+Mono:wght@600&display=swap" rel="stylesheet">
<style>
*{margin:0;padding:0;box-sizing:border-box}
html,body{width:1280px;height:640px;overflow:hidden;background:#04130F}
.w{position:relative;width:1280px;height:640px;overflow:hidden;
   background:radial-gradient(circle at 14% 30%,#0E3B33 0,transparent 42%),
              radial-gradient(circle at 86% 88%,#0B3A34 0,transparent 45%),
              linear-gradient(135deg,#04130F 0%,#04130F 55%,#04060A 100%)}
.grid{position:absolute;inset:0;opacity:.30;
  background-image:linear-gradient(#39D2C014 1px,transparent 1px),linear-gradient(90deg,#39D2C014 1px,transparent 1px);
  background-size:46px 46px;-webkit-mask-image:radial-gradient(60% 90% at 10% 40%,#000 0%,transparent 72%)}
.w::after{content:"";position:absolute;left:0;right:0;bottom:0;height:6px;
          background:linear-gradient(90deg,#39D2C0,#A7F3E6)}
.g{position:absolute;left:84px;top:0;bottom:0;width:620px;display:flex;flex-direction:column;justify-content:center}
.logo{width:132px;height:132px;border-radius:30px;overflow:hidden;position:relative;
      border:1.5px solid #39D2C0C0;box-shadow:0 0 7px #39D2C030,0 0 70px 4px #39D2C040,0 12px 34px rgba(0,0,0,.5)}
.logo img{position:absolute;width:184px;height:184px;left:50%;top:50%;transform:translate(-50%,-50%)}
h1{margin-top:38px;font-family:Syne,sans-serif;font-weight:800;font-size:66px;line-height:1;letter-spacing:-1px;color:#F0F4F8}
h1 em{font-style:normal;color:#39D2C0}
p{margin-top:22px;font-family:'Space Grotesk',sans-serif;font-size:24px;line-height:1.45;color:#A7B0BD}
.c{margin-top:30px;display:flex;gap:12px}
.c span{font-family:'JetBrains Mono',monospace;font-weight:600;font-size:15px;letter-spacing:1.5px;
        color:#39D2C0;padding:10px 16px;border-radius:9px;border:1.5px solid #1D5A50;background:#08221D}
.e{position:absolute;width:236px;border-radius:26px;overflow:hidden;
   border:1.5px solid #1F3F3A;box-shadow:0 40px 80px -20px rgba(0,0,0,.85),0 0 60px -10px #39D2C066}
.e img{width:100%;display:block}
.e1{left:760px;top:96px;transform:rotate(-6deg)}
.e2{left:1004px;top:54px;transform:rotate(5deg)}
</style></head><body><div class="w"><div class="grid"></div>
  <div class="g">
    <div class="logo"><img src="file:///$B/../logo.png"></div>
    <h1>Be<em>Vannes</em></h1>
    <p>BeReal rencontre GeoGuessr : un lieu tiré au sort<br>chaque jour, validé par le GPS.</p>
    <div class="c"><span>FLUTTER</span><span>FIREBASE</span><span>GÉOLOCALISATION</span></div>
  </div>
  <div class="e e1"><img src="file:///$B/vitrine/02.jpg"></div>
  <div class="e e2"><img src="file:///$B/vitrine/04.jpg"></div>
</div></body></html>
HTML

"$CH" --headless=new --disable-gpu --hide-scrollbars --allow-file-access-from-files --virtual-time-budget=15000 \
  --window-size=1280,640 --screenshot="$B/../social-preview.png" \
  "file:///$B/html/social.html" >/dev/null 2>&1
echo "  social-preview.png"
