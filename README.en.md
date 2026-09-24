<div align="center">

<p>
  <a href="README.md"><img src="docs/langues/fr-off.png" alt="Lire cette page en français" width="150" /></a>
  <img src="docs/langues/en-on.png" alt="English, page shown" width="150" />
</p>

<img src="docs/en/banniere.png" alt="BeVannes, BeReal meets GeoGuessr" width="100%">
<br><br>

</div>

**BeReal meets GeoGuessr: one place a day, and you have to go there to score.**

Every day, the app picks a place in Vannes, the same one for everyone. To score, you have to go there: the photo is only accepted within a hundred metres of the spot, GPS as proof. Each place comes with a short historical note, which quietly turns the game into a guided tour.

The starting idea: we walk past the same streets every day without ever stopping. A playful constraint is sometimes enough to change that.

<p align="center">
  <a href="https://github.com/Cybertrist/BeVannes/releases/latest/download/BeVannes.apk"><img src="docs/en/telecharger.png" alt="Download BeVannes, the full version, Android app" width="400"></a>
  <a href="https://github.com/Cybertrist/BeVannes/releases/latest/download/BeVannes-demo.apk"><img src="docs/en/telecharger-demo.png" alt="Try the BeVannes demo, no account, Android app" width="400"></a>
</p>

<img src="docs/en/schemas/vitrine.svg" alt="Animation: a phone scrolls through six real BeVannes screens: sign in, the spot of the day with its map, arriving on site with the gauge full, the validation with its tick and confetti, the leaderboard with its podium, and the profile." width="100%">

<img src="docs/en/sections/s01.png" alt="01 How it works" width="100%">

A game plays out in four beats.

**The draw.** At midnight, every phone works out the spot of the day. Nobody writes it to the database, nobody gets to pick it.

<img src="docs/en/schemas/tirage.svg" alt="Animation: a wheel scrolls through the places of Vannes, slows down and stops on Hôtel de Limur. At the same moment, three phones belonging to three players show the same spot: each one redoes the draw itself, no server involved." width="100%">

**On site.** The map shows the spot and its hundred metre zone. The ring fills as you get closer, and the button only lights up once you are inside.

<img src="docs/en/schemas/approche.svg" alt="Animation: on a map, a player follows a route along the streets, three turns, to the spot of the day surrounded by a hundred metre zone and radar waves. On the right, a circular gauge fills while the distance drops from 620 metres. When the player enters the zone, the gauge is full, a tick appears and the " width="100%">

**Today's wall.** Other players' photos stay locked until you have posted yours.

<img src="docs/en/schemas/mur.svg" alt="Animation: four photos of the day, from Maëlle, Yann, Erwan and Klervi, are locked. A fifth photo, yours, drops into the last slot. The locks then come off one after another and the four photos are revealed. Firestore does the checking, not the app." width="100%">

**The reminder.** One notification a day, at a time that changes every day but lands at the same moment for everyone.

<img src="docs/en/schemas/rappel.svg" alt="Animation: a clock's hands jump from one time to the next, Wednesday 17:54, Thursday 14:43, Friday 13:18, Saturday 17:51. At each time, three phones buzz together and the same notification drops down: " width="100%">



<img src="docs/en/sections/s02.png" alt="02 Under the hood" width="100%">

A Flutter app for Android, with Firebase behind it: Authentication for accounts, Firestore for players, validations and photos. The photos fit easily, as 3:4 at 900 × 1200 pixels, and Cloud Storage is no longer offered on Firebase's free plan: the whole game runs without paying anything. The map comes from OpenStreetMap, no API key needed.

Three pieces hold the game together.

<img src="docs/en/schemas/fonctions.png" alt="The draw: a fixed-seed shuffle, every phone works out the same spot and nobody has to write it to the database. The distance: haversine, a hundred metre radius, a fresh fix when posting, a mock location flagged by Android is rejected. The rules: Firestore recomputes streak and points on every validation, the phone cannot award them to itself." width="100%">

A validation goes through five steps, and it all goes through in one block or not at all.

<img src="docs/en/schemas/parcours.svg" alt="Animation: a validation passes through five stations. The phone sends a 3:4 photo taken 20 metres from the spot; the photo goes to photos/20720_toi; Firestore writes the validation and updates the player; the rules recompute the streak, from 3 to 4, and the gain, 10 + 2 × 3 = 16; the leaderboard shows +16 points and 4th place. All or nothing." width="100%">

The phone only proposes its points: Firestore redoes the maths and refuses anything that does not add up.

<img src="docs/en/schemas/triche.svg" alt="Animation: two phones send their points. The first proposes 136 → 152 with a streak going from 3 to 4: the rules redo the maths, 136 + 16 = 152, and accept. The second proposes 136 → 999: 136 + 16 is not 999, the rules refuse with permission-denied." width="100%">

Points are counted by the day: ten per spot, two more per day in a row, and the bonus stops at ten.

<img src="docs/en/schemas/serie.svg" alt="Animation: seven bars rise one after another, Monday to Sunday, +10, +12, +14, +16, +18, +20, +20. A flame lights up above every day of the streak, and a line marks the bonus cap. The total climbs to 110 points in one week; miss a day and the streak resets to 1." width="100%">

Photos all share the same format, whatever the camera.

<img src="docs/en/schemas/cadrage.svg" alt="Animation: a photo taken in 4:3 shows a city gate in the sun. Two dark bands drop on either side, leaving only a 3:4 portrait frame, which then moves to the right: 3:4, 1200 × 1600 JPEG, cropped on the phone before upload." width="100%">

The code is layered: `lib/domain` holds the game rules, free of Flutter and Firebase, and tested; `lib/data` holds storage, with a Firebase version and an in-memory demo version; `lib/ui` holds the screens.

On the interface side, every animation has a job: a radar marks the spot on the map, a gauge fills as you get closer, a shine sweeps the button once it becomes useful, and a validation is celebrated with a tick that draws itself and a burst of confetti. Screens settle in block by block, and the podium steps rise.

<img src="docs/en/sections/s03.png" alt="03 Installation" width="100%">

Two apps, which install side by side without getting in each other's way.

- **BeVannes**, the full version: the real game, connected to the server. One account, with the leaderboard, photos and streaks shared with the other players.
- **BeVannes démo**: a small made-up community, everything stays on the phone, and a "Me téléporter sur le lieu" switch to try validation without crossing Vannes.

Both are signed with the same key; an update installs over the previous one without losing anything.

```
# SHA-256 of BeVannes.apk, version 2.1.0
8d25d9ecd2d6d0e5175adf36d63d6e58815335ea5c04ffd7bf8e58b6c87ead7e

# SHA-256 of BeVannes-demo.apk, version 2.1.0
92d5c9d0592950c7ae3c6936ab28e98d11f1b93cf3128b468b4e34d2bfa81eaf

# SHA-256 of the signing certificate, CN=BeVannes, O=Cybertrist
9a8c67645db4e34f4585d84e1db2addf9cbbabc01539bfb4ff57277c0f00feeb
```

**To build it**, you need Flutter. The demo is built with `--dart-define=DEMO=true`, which also gives it its own identifier, `fr.bevannes.bevannes.demo`.

```bash
git clone https://github.com/Cybertrist/BeVannes.git
cd BeVannes
flutter pub get
flutter run --dart-define=DEMO=true
```

**To play for real**, you need a Firebase project.

1. On the [Firebase console](https://console.firebase.google.com/), enable **Authentication** (email and password) and **Firestore**, and register an Android app `fr.bevannes.bevannes`.
2. Download its `google-services.json`, then write the build configuration, which git ignores:

```bash
bash tool/firebase_env.sh path/to/google-services.json
```

3. Deploy the rules and indexes from the repository:

```bash
firebase deploy --only firestore
```

4. Build:

```bash
flutter build apk --release --dart-define-from-file=firebase.env.json
```

> Client-side Firebase API keys are not secrets, they can be read from any APK. What protects the data are the **rules** in `firestore.rules`: a player only writes their own points, recomputed by the server, and only sees a day's photos after validating that day themselves.

<img src="docs/en/sections/s04.png" alt="04 Adding places" width="100%">

Nineteen places today, from the cathedral to the Conleau headland, each coming up once per cycle.

<img src="docs/en/schemas/lieux.svg" alt="Animation: two maps of Vannes, the whole town and a close-up of the centre, show the game's nineteen places at their real position. They light up one by one in the order of the current cycle: Porte Poterne, Pointe de Conleau, Préfecture du Morbihan, Cathédrale Saint-Pierre, Place Gambetta, Porte Saint-Vincent, Église Saint-Patern, Porte Prison, Jardin des remparts, Lavoirs de la Garenne, Hôtel de Limur, La Cohue, Place des Lices, Parc du Golfe, Le port, Hôtel de ville, Vannes et sa femme, Place Henri-IV, Château de l'Hermine." width="100%">

Places live in `assets/lieux.json`, bundled with the app.

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

Take the coordinates from OpenStreetMap, not by eye: with a hundred metre radius, a misplaced spot becomes impossible to validate. The `note` is not decoration either, it is what separates a treasure hunt from a visit.

The order of the file feeds the draw: adding a place reshuffles the current cycle. Every player therefore needs the same app version to see the same spot.

<img src="docs/en/sections/s05.png" alt="05 Limits" width="100%">

The playing field is Vannes. Anywhere else, there is nothing to discover.

The position is whatever the phone reports. Android flags mock-location apps, and the game rejects them, but a modified phone can lie without saying so. The Firestore rules guarantee that points add up, not that the player was there.

Photos are not moderated, and OpenStreetMap's tiles are not meant for heavy traffic: beyond a circle of friends, it would take a tile server of your own.

Written in Flutter and Dart, with Firebase. MIT licence.

---

<sub>Student project · Université Bretagne Sud, Vannes · Tristan Joncour</sub>
