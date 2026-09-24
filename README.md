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

Une partie tient en quatre temps.

**Le tirage.** À minuit, chaque téléphone calcule le lieu du jour. Personne ne l'écrit dans la base, personne ne peut le choisir.

<img src="docs/schemas/tirage.svg" alt="Animation : une roulette fait défiler les lieux de Vannes, ralentit et s'arrête sur l'Hôtel de Limur. Au même instant, trois téléphones de trois joueurs affichent le même lieu : chacun refait le tirage lui-même, aucun serveur n'intervient." width="100%">

**Sur place.** La carte montre le lieu et sa zone de cent mètres. L'anneau se remplit à mesure qu'on approche, et le bouton ne s'allume qu'une fois dedans.

<img src="docs/schemas/approche.svg" alt="Animation : sur une carte, un joueur marche vers le lieu du jour, entouré d'une zone de cent mètres et d'ondes de radar. À droite, une jauge circulaire se remplit pendant que la distance descend, 1,2 km, 640 m, 310 m, 150 m. Quand le joueur entre dans la zone, la jauge est pleine, une coche apparaît et le bouton « Prendre la photo » se déverrouille." width="100%">

**Le mur du jour.** Les photos des autres restent verrouillées tant qu'on n'a pas publié la sienne.

<img src="docs/schemas/mur.svg" alt="Animation : quatre photos du jour, de Maëlle, Yann, Erwan et Klervi, sont verrouillées. Une cinquième photo, la tienne, arrive dans la dernière case. Les verrous sautent alors l'un après l'autre et les quatre photos se dévoilent. C'est Storage qui vérifie, pas l'application." width="100%">

**Le rappel.** Une notification par jour, à une heure qui change tous les jours mais tombe au même moment pour tout le monde.

<img src="docs/schemas/rappel.svg" alt="Animation : les aiguilles d'une horloge sautent d'une heure à l'autre, mercredi 17 h 54, jeudi 14 h 43, vendredi 13 h 18, samedi 17 h 51. À chaque heure, trois téléphones vibrent en même temps et la même notification descend : « C'est l'heure ! ». Le calcul se fait sur chaque téléphone, sans serveur." width="100%">

<p align="center">
  <img src="docs/captures/jour.png" alt="Sur place : la jauge d’approche est pleine, et le bouton « Prendre la photo » s’allume" width="24%">
  <img src="docs/captures/bravo.png" alt="Après la publication : la coche se dessine, les confettis partent, seize points et une série de quatre jours" width="24%">
  <img src="docs/captures/classement.png" alt="Le classement : la place du joueur, le podium, puis tous les joueurs avec leur série en cours" width="24%">
  <img src="docs/captures/profil.png" alt="Le profil : points, lieux validés, série en cours, meilleure série et part de Vannes découverte" width="24%">
</p>

<img src="docs/sections/s02.png" alt="02 Sous le capot" width="100%">

Une application Flutter pour Android, avec Firebase derrière : Authentication pour les comptes, Firestore pour les joueurs et les validations, Storage pour les photos. La carte vient d'OpenStreetMap, sans clé d'API.

Trois pièces tiennent le jeu.

<img src="docs/schemas/fonctions.png" alt="Le tirage : un mélange à graine fixe, chaque téléphone calcule le même lieu sans que personne ne l'écrive dans la base. La distance : haversine, rayon de cent mètres, mesure fraîche au moment de publier, une position fictive signalée par Android est refusée. Les règles : Firestore recalcule série et points à chaque validation, le téléphone ne peut pas se les attribuer." width="100%">

Les points se calculent au jour près : dix par lieu, deux de plus par jour de série, et le bonus s'arrête à dix.

<img src="docs/schemas/serie.svg" alt="Animation : sept barres montent l'une après l'autre, du lundi au dimanche, +10, +12, +14, +16, +18, +20, +20. Une flamme s'allume au-dessus de chaque jour de série, et un trait marque le plafond du bonus. Le total grimpe jusqu'à 110 points en une semaine ; un jour manqué, la série repart à 1." width="100%">

Les photos, elles, sont toutes au même format, quel que soit l'appareil.

<img src="docs/schemas/cadrage.svg" alt="Animation : une photo prise en 4:3 montre une porte de ville sous le soleil. Deux bandes sombres tombent de chaque côté et ne laissent qu'un cadre 3:4 en portrait, qui part ensuite vers la droite : 3:4, 1200 × 1600 en JPEG, recadrée sur le téléphone avant l'envoi." width="100%">

Le code est rangé en couches : `lib/domain` pour les règles du jeu, sans Flutter ni Firebase, et testé ; `lib/data` pour le stockage, avec une version Firebase et une version de démonstration en mémoire ; `lib/ui` pour les écrans.

Côté interface, chaque animation a un rôle : un radar marque le lieu sur la carte, une jauge se remplit en approchant, un reflet passe sur le bouton quand il devient utile, et la validation se fête avec une coche qui se dessine et une gerbe de confettis. Les écrans s'installent bloc par bloc, et les marches du podium montent.

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
