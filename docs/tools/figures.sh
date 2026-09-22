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
ban bevannes "$A" "#4B39EF" "#04130F" \
'<svg viewBox="0 0 132 132" fill="none"><circle cx="66" cy="66" r="56" stroke="#F2F6FA" stroke-width="7"/><g stroke="#39D2C0" stroke-width="7" stroke-linecap="round"><path d="M122 66 76.3 85.4"/><path d="M94 114.5 54.3 84.7"/><path d="M38 114.5 44 65.2"/><path d="M10 66 55.7 46.6"/><path d="M38 17.5 77.7 47.3"/><path d="M94 17.5 88 66.8"/></g></svg>' \
'Be<span style="background:#F2F6FA;color:#080808;padding:0 16px 6px;border-radius:12px;margin-left:6px;display:inline-block;line-height:.92">Vannes</span>' \
"$(t 'BeReal rencontre GeoGuessr : un lieu tiré au sort chaque jour,' 'BeReal meets GeoGuessr: a spot drawn at random every day,')" \
"$(t 'et la photo ne compte que si le GPS confirme que vous y êtes.' 'and the photo only counts if GPS says you were there.')" \
"$(P 'FLUTTER' 'FIREBASE' "$(t 'GÉOLOCALISATION' 'GEOLOCATION')")" \
'MOBILE' ""

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
