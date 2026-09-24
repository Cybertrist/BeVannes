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
"$(t 'Le spot du jour' "Today's spot")|$(t 'Un lieu tiré au sort dans Vannes et ses environs, le même pour tout le monde, renouvelé chaque jour.' 'A place drawn at random in and around Vannes, the same for everyone, renewed every day.')" \
"$(t 'La validation géolocalisée' 'Location-checked validation')|$(t "La photo ne compte que si le GPS confirme la présence sur place. C'est toute la règle du jeu." 'The photo only counts if GPS confirms you are there. That is the whole rule of the game.')" \
"$(t 'Le classement' 'The leaderboard')|$(t 'Points cumulés, médailles et insignes pour ceux qui sortent vraiment tous les jours.' 'Cumulative points, medals and badges for those who really do go out every day.')" \
"$(t 'Les notifications' 'The notifications')|$(t "Envoyées à une heure aléatoire, comme BeReal. Pas le temps de préparer sa photo." 'Sent at a random time, like BeReal. No time to set up your shot.')"

# ------------------------------------------------------- les trois fonctions
grid bv-fonctions "$A" 3 \
"compareLatLng|$(t "Compare la position de l'utilisateur à celle du spot, avec une tolérance exprimée en mètres." "Compares the user's position to the spot's, with a tolerance expressed in metres.")" \
"sameDay|$(t "Vérifie que la tentative concerne bien le spot du jour en cours." 'Checks that the attempt really is about the current day&#39;s spot.')" \
"dateIsThisDay|$(t "Normalise les dates entre le fuseau de l'appareil et l'horodatage du serveur." "Normalises dates between the device timezone and the server timestamp.")"
