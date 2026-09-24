<div align="center">

<p>
  <img src="docs/langues/fr-on.png" alt="Français, page affichée" width="150" />
  <a href="README.en.md"><img src="docs/langues/en-off.png" alt="Read this page in English" width="150" /></a>
</p>

<img src="docs/banniere.png" alt="BeVannes, BeReal rencontre GeoGuessr" width="100%">

<a href="https://github.com/Cybertrist/BeVannes/releases/latest/download/BeVannes.apk"><img src="docs/telecharger.png" alt="Télécharger BeVannes, application Android, dernière version, mode démo" width="420"></a>

</div>

**BeReal rencontre GeoGuessr : un lieu par jour, il faut y aller pour marquer.**

Chaque jour, l'application désigne un lieu de Vannes, le même pour tout le monde. Pour marquer des points, il faut s'y rendre : la photo n'est acceptée qu'à moins de cent mètres du lieu, GPS à l'appui. Chaque lieu s'accompagne d'une courte note historique, ce qui transforme la partie en visite guidée sans le vouloir.

L'idée de départ : on passe devant les mêmes rues tous les jours sans jamais s'arrêter. Une contrainte ludique suffit parfois à changer ça.

<img src="docs/sections/s01.png" alt="01 Fonctionnement" width="100%">

<img src="docs/schemas/fonctionnement.png" alt="Le lieu du jour : un lieu de Vannes tiré au sort, le même pour tout le monde, renouvelé à minuit, chacun revient une fois par cycle. La validation sur place : la photo ne compte qu'à moins de cent mètres du lieu, GPS à l'appui, c'est toute la règle du jeu. Le classement : dix points par lieu, un bonus pour chaque jour de série, les photos des autres se dévoilent une fois la sienne publiée. Le rappel : une heure différente chaque jour, la même pour tous, comme BeReal, calculée sur le téléphone, sans serveur." width="100%">

<p align="center">
  <img src="docs/captures/jour.png" alt="Le lieu du jour : la carte avec la zone de validation de cent mètres, le nom du lieu, sa note historique et la distance qui reste à parcourir" width="24%">
  <img src="docs/captures/bravo.png" alt="Après la publication : seize points gagnés et une série de quatre jours" width="24%">
  <img src="docs/captures/classement.png" alt="Le classement : la place du joueur, le podium, puis tous les joueurs avec leur série en cours" width="24%">
  <img src="docs/captures/profil.png" alt="Le profil : points, lieux validés, série en cours, meilleure série et part de Vannes découverte" width="24%">
</p>

<img src="docs/sections/s02.png" alt="02 Sous le capot" width="100%">

Une application Flutter pour Android, avec Firebase derrière : Authentication pour les comptes, Firestore pour les joueurs et les validations, Storage pour les photos. La carte vient d'OpenStreetMap, sans clé d'API.

Trois pièces tiennent le jeu.

<img src="docs/schemas/fonctions.png" alt="Le tirage : un mélange à graine fixe, chaque téléphone calcule le même lieu sans que personne ne l'écrive dans la base. La distance : haversine, rayon de cent mètres, mesure fraîche au moment de publier, une position fictive signalée par Android est refusée. Les règles : Firestore recalcule série et points à chaque validation, le téléphone ne peut pas se les attribuer." width="100%">

Le code est rangé en couches : `lib/domain` pour les règles du jeu, sans Flutter ni Firebase, et testé ; `lib/data` pour le stockage, avec une version Firebase et une version de démonstration en mémoire ; `lib/ui` pour les écrans. Les photos sont recadrées en 3:4 sur le téléphone avant l'envoi, pour que tout le monde voie le même cadre.

<img src="docs/sections/s03.png" alt="03 Installation" width="100%">

**Pour essayer**, le bouton en haut de page installe la version de démonstration : une petite communauté fictive, tout reste sur le téléphone, et un interrupteur place le joueur sur le lieu du jour pour tester la validation sans traverser la ville.

**Pour construire**, il faut Flutter.

```bash
git clone https://github.com/Cybertrist/BeVannes.git
cd BeVannes
flutter pub get
flutter run --dart-define=DEMO=true
```

**Pour jouer pour de vrai**, il faut un projet Firebase.

1. Sur la [console Firebase](https://console.firebase.google.com/), activer **Authentication** (e-mail et mot de passe), **Firestore** et **Storage**, et déclarer une application Android `fr.bevannes.bevannes`.
2. Télécharger son `google-services.json`, puis écrire la configuration de compilation, ignorée par git :

```bash
bash tool/firebase_env.sh chemin/vers/google-services.json
```

3. Déployer les règles et les index du dépôt :

```bash
firebase deploy --only firestore,storage
```

4. Construire :

```bash
flutter build apk --release --dart-define-from-file=firebase.env.json
```

> Les clés d'API Firebase côté client ne sont pas des secrets, elles se lisent dans tout APK. Ce qui protège les données, ce sont les **règles** de `firestore.rules` et `storage.rules` : un joueur n'écrit que ses propres points, recalculés par le serveur, et ne voit les photos d'un jour qu'après avoir validé ce jour-là.

<img src="docs/sections/s04.png" alt="04 Ajouter des lieux" width="100%">

Les lieux vivent dans `assets/lieux.json`, embarqués dans l'application.

```json
{
  "id": "lavoirs-garenne",
  "nom": "Lavoirs de la Garenne",
  "quartier": "Les remparts",
  "latitude": 47.6555828,
  "longitude": -2.7554577,
  "note": "Sous leurs toits d'ardoise, au bord de la Marle, les lavandières rinçaient le linge jusqu'au milieu du XXe siècle."
}
```

Les coordonnées se prennent sur OpenStreetMap, pas à l'œil : à cent mètres près, un lieu mal placé devient impossible à valider. La `note` n'est pas décorative non plus, c'est elle qui fait la différence entre une chasse au trésor et une visite.

L'ordre du fichier entre dans le tirage : ajouter un lieu rebat le cycle en cours. Tous les joueurs doivent donc avoir la même version de l'application pour voir le même lieu.

<img src="docs/sections/s05.png" alt="05 Limites" width="100%">

Le terrain de jeu est Vannes. Ailleurs, il n'y a rien à découvrir.

La position reste celle que le téléphone annonce. Android signale les applications de position fictive, et le jeu les refuse, mais un téléphone modifié peut mentir sans le dire. Les règles Firestore garantissent la cohérence des points, pas la présence sur place.

Les photos ne sont pas modérées, et les tuiles d'OpenStreetMap ne sont pas faites pour un gros trafic : au-delà d'un cercle d'amis, il faudrait un serveur de tuiles à soi.

Écrit en Flutter et Dart, avec Firebase. Licence MIT.

---

<sub>Projet étudiant · Université Bretagne Sud, Vannes · Tristan Joncour</sub>
