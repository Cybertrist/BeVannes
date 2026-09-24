#!/bin/bash
# Toutes les figures du README : la bannière, les cinq bandeaux de section
# et les deux grilles.
#
# Les captures d'écran de docs/captures/ ne passent pas par ici : ce sont
# de vraies captures de l'application, aucun script ne les refait.
#
# Chaque texte porte ses deux langues, t <français> <anglais>. L'anglais
# n'est pas un calque : une tournure qui claque en français tombe à plat
# traduite mot à mot, alors elle est réécrite.
D="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$D/cartes.sh"   >/dev/null 2>&1
source "$D/bandeaux.sh" >/dev/null 2>&1
source "$D/grille.sh"   >/dev/null 2>&1

A="#39D2C0"

# ----------------------------------------------------------- la bannière
# Le cadre néon du logo n'occupe que 77 % du fichier, et son trait réduit
# à la taille de la plaque sortirait crénelé. Le logo est donc cadré
# au-delà de son cadre, à 198 px, et le contour est redessiné en CSS.
ban bevannes "$A" "#A7F3E6" "#04130F" \
"<div class='crop' style='border:1.5px solid #39D2C0C0;box-shadow:0 0 7px #39D2C030, 0 12px 34px rgba(0,0,0,.5)'><img src='file:///$B/../logo.png' style='width:198px;height:198px'></div>" \
'Be<em>Vannes</em>' \
"$(t 'BeReal rencontre GeoGuessr : un lieu tiré au sort chaque jour,' 'BeReal meets GeoGuessr: a spot drawn at random every day,')" \
"$(t 'et la photo ne compte que si le GPS confirme que vous y êtes.' 'and the photo only counts if GPS says you were there.')" \
"$(P 'FLUTTER' 'FIREBASE' "$(t 'GÉOLOCALISATION' 'GEOLOCATION')")" \
"$(C 'MOBILE' "$(t 'GÉOGRAPHIE' 'GEOGRAPHY')" 'PHOTO' "$(t 'JEU' 'GAME')")" ""

# ------------------------------------------------ les bandeaux de section
rep bevannes "$A" \
"$(t 'Fonctionnement' 'How it works')" \
"$(t 'Sous le capot' 'Under the hood')" \
"$(t 'Installation' 'Installation')" \
"$(t 'Ajouter des lieux' 'Adding places')" \
"$(t 'Limites' 'Limits')"

# ------------------------------------------------------ la règle du jeu
grid bv-jeu "$A" 2 \
"$(t 'Le lieu du jour' "Today's spot")|$(t 'Un lieu de Vannes tiré au sort, le même pour tout le monde, renouvelé à minuit. Chacun revient une fois par cycle.' 'A place in Vannes drawn at random, the same for everyone, renewed at midnight. Each one comes up once per cycle.')" \
"$(t 'La validation sur place' 'Proof of presence')|$(t "La photo ne compte qu'à moins de cent mètres du lieu, GPS à l'appui. C'est toute la règle du jeu." 'The photo only counts within a hundred metres of the spot, GPS as proof. That is the whole rule of the game.')" \
"$(t 'Le classement' 'The leaderboard')|$(t 'Dix points par lieu, un bonus pour chaque jour de série. Les photos des autres se dévoilent une fois la sienne publiée.' "Ten points per spot, a bonus for every day in a row. Other players' photos show up once yours is posted.")" \
"$(t 'Le rappel' 'The reminder')|$(t 'Une heure différente chaque jour, la même pour tous, comme BeReal. Calculée sur le téléphone, sans serveur.' 'A different time every day, the same for everyone, like BeReal. Worked out on the phone, no server involved.')"

# ----------------------------------------------------- ce qui tient le jeu
grid bv-fonctions "$A" 3 \
"$(t 'Le tirage' 'The draw')|$(t "Un mélange à graine fixe : chaque téléphone calcule le même lieu, sans que personne ne l'écrive dans la base." 'A fixed-seed shuffle: every phone works out the same spot, and nobody has to write it to the database.')" \
"$(t 'La distance' 'The distance')|$(t 'Haversine, rayon de cent mètres, mesure fraîche au moment de publier. Une position fictive signalée par Android est refusée.' 'Haversine, a hundred metre radius, a fresh fix when posting. A mock location flagged by Android is rejected.')" \
"$(t 'Les règles' 'The rules')|$(t 'Firestore recalcule série et points à chaque validation. Le téléphone ne peut pas se les attribuer.' 'Firestore recomputes streak and points on every validation. The phone cannot award them to itself.')"
