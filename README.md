<div align="center">

<img src="docs/banniere.png" alt="BeVannes, BeReal rencontre GeoGuessr" width="100%">

</div>

**BeReal rencontre GeoGuessr : un lieu par jour, il faut y aller pour marquer.**

Chaque jour, l'application tire un lieu au sort dans Vannes et ses environs. Pour marquer des points, il faut s'y rendre physiquement : la position GPS est comparée à celle du spot, et la photo n'est validée que si vous y êtes vraiment. Chaque lieu s'accompagne d'une note historique ou culturelle, ce qui transforme la partie en visite guidée sans le vouloir.

L'idée de départ : on passe devant les mêmes rues tous les jours sans jamais s'arrêter. Une contrainte ludique suffit parfois à changer ça.

<img src="docs/sections/s01.png" alt="01 Fonctionnement" width="100%">

<img src="docs/schemas/fonctionnement.png" alt="Le spot du jour : un lieu tiré au sort dans Vannes et ses environs, le même pour tout le monde, renouvelé chaque jour. La validation géolocalisée : la photo ne compte que si le GPS confirme la présence sur place, c'est toute la règle du jeu. Le classement : points cumulés, médailles et insignes pour ceux qui sortent vraiment tous les jours. Les notifications : envoyées à une heure aléatoire, comme BeReal, pas le temps de préparer sa photo." width="100%">

<div align="center">

<img src="docs/captures/spot.png" alt="L'écran du spot du jour : la photo du lieu, sa position sur la carte, et le bouton de prise de vue qui devient une validation une fois sur place" width="70%">

<img src="docs/captures/partage.png" alt="L'écran de partage de la photo prise sur place" width="70%">

<img src="docs/captures/classement.png" alt="Le classement des joueurs" width="70%">

</div>

<img src="docs/sections/s02.png" alt="02 Sous le capot" width="100%">

Développé avec Flutter, prototypé sur FlutterFlow, adossé à Firebase pour l'authentification, la base temps réel et les tâches planifiées.

Trois fonctions maison portent la logique de jeu.

<img src="docs/schemas/fonctions.png" alt="compareLatLng compare la position de l'utilisateur à celle du spot, avec une tolérance exprimée en mètres. sameDay vérifie que la tentative concerne bien le spot du jour en cours. dateIsThisDay normalise les dates entre le fuseau de l'appareil et l'horodatage du serveur." width="100%">

C'est là que tout se joue. Une tolérance trop large et on valide depuis son canapé, trop étroite et le bruit GPS en ville rend le jeu injouable.

<img src="docs/sections/s03.png" alt="03 Installation" width="100%">

<img src="docs/blocs/01.png" alt="Terminal bash : installation" width="100%">

```bash
git clone https://github.com/Cybertrist/BeVannes.git
cd BeVannes
flutter pub get
```

**Firebase.** Le projet a besoin de votre propre projet Firebase : les fichiers de configuration ne sont pas versionnés.

1. Créez un projet sur la [console Firebase](https://console.firebase.google.com/).
2. Activez **Authentication**, **Realtime Database** et **Storage**.
3. Téléchargez `google-services.json` et placez-le dans `android/app/`.
4. Pour iOS, `GoogleService-Info.plist` va dans `ios/Runner/`.

> Les clés d'API Firebase côté client ne sont pas des secrets, elles sont lisibles dans tout APK. Ce qui protège réellement les données, ce sont les **règles de sécurité** Realtime Database et Storage. Configurez-les avant d'ouvrir l'application à qui que ce soit.

<img src="docs/blocs/02.png" alt="Terminal bash : lancer" width="100%">

```bash
flutter run
```

<img src="docs/sections/s04.png" alt="04 Ajouter des lieux" width="100%">

Les spots sont décrits dans `data/spots.json`.

<img src="docs/blocs/03.png" alt="Fichier data/spots.json : ajouter un lieu" width="100%">

```json
{
  "spots": [
    {
      "name": "Les remparts",
      "latitude": 47.6553,
      "longitude": -2.7601,
      "description": "Fortifications médiévales, parmi les mieux conservées de Bretagne."
    }
  ]
}
```

La `description` n'est pas décorative : c'est elle qui fait la différence entre une chasse au trésor et une visite. Elle mérite qu'on la soigne.

<img src="docs/sections/s05.png" alt="05 Limites" width="100%">

Le périmètre couvert est Vannes et ses alentours. Ailleurs, il n'y a rien à découvrir.

La validation repose sur le GPS de l'appareil, qui reste falsifiable par une application de position fictive. Une vérification sérieuse demanderait un recoupement côté serveur, sur l'heure de la prise de vue et la cohérence des déplacements.

Le projet est né d'un prototype FlutterFlow, et une partie du code généré n'a pas été reprise à la main.

Écrit en Flutter et Dart, avec Firebase. Licence MIT.

---

<sub>Projet étudiant · Université Bretagne Sud, Vannes · Tristan Joncour</sub>
