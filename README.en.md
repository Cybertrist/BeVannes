<div align="center">

<p>
  <a href="README.md"><img src="docs/langues/fr-off.png" alt="Lire cette page en français" width="150" /></a>
  <img src="docs/langues/en-on.png" alt="English, page shown" width="150" />
</p>

<img src="docs/en/banniere.png" alt="BeVannes, BeReal meets GeoGuessr" width="100%">

<a href="https://github.com/Cybertrist/BeVannes/releases/latest/download/BeVannes.apk"><img src="docs/en/telecharger.png" alt="Download BeVannes, Android app, latest version, demo mode" width="420"></a>

</div>

**BeReal meets GeoGuessr: one place a day, and you have to go there to score.**

Every day, the app picks a place in Vannes, the same one for everyone. To score, you have to go there: the photo is only accepted within a hundred metres of the spot, GPS as proof. Each place comes with a short historical note, which quietly turns the game into a guided tour.

The starting idea: we walk past the same streets every day without ever stopping. A playful constraint is sometimes enough to change that.

<img src="docs/en/sections/s01.png" alt="01 How it works" width="100%">

A game plays out in four beats.

**The draw.** At midnight, every phone works out the spot of the day. Nobody writes it to the database, nobody gets to pick it.

<img src="docs/en/schemas/tirage.svg" alt="Animation: a wheel scrolls through the places of Vannes, slows down and stops on Hôtel de Limur. At the same moment, three phones belonging to three players show the same spot: each one redoes the draw itself, no server involved." width="100%">

**On site.** The map shows the spot and its hundred metre zone. The ring fills as you get closer, and the button only lights up once you are inside.

<img src="docs/en/schemas/approche.svg" alt="Animation: on a map, a player walks towards the spot of the day, surrounded by a hundred metre zone and radar waves. On the right, a circular gauge fills up while the distance drops, 1.2 km, 640 m, 310 m, 150 m. When the player enters the zone, the gauge is full, a tick appears and the " width="100%">

**Today's wall.** Other players' photos stay locked until you have posted yours.

<img src="docs/en/schemas/mur.svg" alt="Animation: four photos of the day, from Maëlle, Yann, Erwan and Klervi, are locked. A fifth photo, yours, drops into the last slot. The locks then come off one after another and the four photos are revealed. Storage does the checking, not the app." width="100%">

**The reminder.** One notification a day, at a time that changes every day but lands at the same moment for everyone.

<img src="docs/en/schemas/rappel.svg" alt="Animation: a clock's hands jump from one time to the next, Wednesday 17:54, Thursday 14:43, Friday 13:18, Saturday 17:51. At each time, three phones buzz together and the same notification drops down: " width="100%">

<p align="center">
  <img src="docs/captures/jour.png" alt="On site, in French: the approach gauge is full and the Take the photo button lights up" width="24%">
  <img src="docs/captures/bravo.png" alt="After posting, in French: the tick draws itself, confetti bursts out, sixteen points and a four day streak" width="24%">
  <img src="docs/captures/classement.png" alt="The leaderboard, in French: the player's rank, the podium, then every player with their current streak" width="24%">
  <img src="docs/captures/profil.png" alt="The profile, in French: points, places validated, current streak, best streak and how much of Vannes has been found" width="24%">
</p>

> The screenshots show the app in French, the only language it ships in.

<img src="docs/en/sections/s02.png" alt="02 Under the hood" width="100%">

A Flutter app for Android, with Firebase behind it: Authentication for accounts, Firestore for players and validations, Storage for photos. The map comes from OpenStreetMap, no API key needed.

Three pieces hold the game together.

<img src="docs/en/schemas/fonctions.png" alt="The draw: a fixed-seed shuffle, every phone works out the same spot and nobody has to write it to the database. The distance: haversine, a hundred metre radius, a fresh fix when posting, a mock location flagged by Android is rejected. The rules: Firestore recomputes streak and points on every validation, the phone cannot award them to itself." width="100%">

Points are counted by the day: ten per spot, two more per day in a row, and the bonus stops at ten.

<img src="docs/en/schemas/serie.svg" alt="Animation: seven bars rise one after another, Monday to Sunday, +10, +12, +14, +16, +18, +20, +20. A flame lights up above every day of the streak, and a line marks the bonus cap. The total climbs to 110 points in one week; miss a day and the streak resets to 1." width="100%">

Photos all share the same format, whatever the camera.

<img src="docs/en/schemas/cadrage.svg" alt="Animation: a photo taken in 4:3 shows a city gate in the sun. Two dark bands drop on either side, leaving only a 3:4 portrait frame, which then moves to the right: 3:4, 1200 × 1600 JPEG, cropped on the phone before upload." width="100%">

The code is layered: `lib/domain` holds the game rules, free of Flutter and Firebase, and tested; `lib/data` holds storage, with a Firebase version and an in-memory demo version; `lib/ui` holds the screens.

On the interface side, every animation has a job: a radar marks the spot on the map, a gauge fills as you get closer, a shine sweeps the button once it becomes useful, and a validation is celebrated with a tick that draws itself and a burst of confetti. Screens settle in block by block, and the podium steps rise.

<img src="docs/en/sections/s03.png" alt="03 Installation" width="100%">

**To try it**, the button at the top installs the demo build: a small made-up community, everything stays on the phone, and a switch puts the player on today's spot to test validation without crossing town.

**To build it**, you need Flutter.

```bash
git clone https://github.com/Cybertrist/BeVannes.git
cd BeVannes
flutter pub get
flutter run --dart-define=DEMO=true
```

**To play for real**, you need a Firebase project.

1. On the [Firebase console](https://console.firebase.google.com/), enable **Authentication** (email and password), **Firestore** and **Storage**, and register an Android app `fr.bevannes.bevannes`.
2. Download its `google-services.json`, then write the build configuration, which git ignores:

```bash
bash tool/firebase_env.sh path/to/google-services.json
```

3. Deploy the rules and indexes from the repository:

```bash
firebase deploy --only firestore,storage
```

4. Build:

```bash
flutter build apk --release --dart-define-from-file=firebase.env.json
```

> Client-side Firebase API keys are not secrets, they can be read from any APK. What protects the data are the **rules** in `firestore.rules` and `storage.rules`: a player only writes their own points, recomputed by the server, and only sees a day's photos after validating that day themselves.

<img src="docs/en/sections/s04.png" alt="04 Adding places" width="100%">

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
