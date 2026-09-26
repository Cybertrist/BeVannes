<div align="center">

<p>
  <a href="README.md"><img src="docs/langues/fr-off.png" alt="Lire cette page en français" width="150" /></a>
  <img src="docs/langues/en-on.png" alt="English, page shown" width="150" />
</p>

<img src="docs/en/banniere.png" alt="BeVannes, BeReal meets GeoGuessr" width="100%">
<br><br>

**BeReal meets GeoGuessr: one place a day, and you have to go there to score.**

</div>

Every day, the app picks a place in Vannes, the same one for everyone. To score, you have to go there: the photo is only accepted within a hundred metres of the spot, GPS as proof. Each place comes with a short historical note, which quietly turns the game into a guided tour.

The starting idea: we walk past the same streets every day without ever stopping. A playful constraint is sometimes enough to change that.

<img src="docs/en/sections/s00.png" alt="00 Contents" width="100%">

<p align="center">
<a href="#features"><img src="docs/en/sommaire/01.png" alt="01 Features" width="31%"></a>
<a href="#screens"><img src="docs/en/sommaire/02.png" alt="02 The screens" width="31%"></a>
<a href="#install"><img src="docs/en/sommaire/03.png" alt="03 Install" width="31%"></a>
<br>
<a href="#todays-spot"><img src="docs/en/sommaire/04.png" alt="04 Today's spot" width="31%"></a>
<a href="#on-site"><img src="docs/en/sommaire/05.png" alt="05 On site" width="31%"></a>
<a href="#photo"><img src="docs/en/sommaire/06.png" alt="06 The photo" width="31%"></a>
<br>
<a href="#wall"><img src="docs/en/sommaire/07.png" alt="07 The daily wall" width="31%"></a>
<a href="#points"><img src="docs/en/sommaire/08.png" alt="08 Streaks" width="31%"></a>
<a href="#reminder"><img src="docs/en/sommaire/09.png" alt="09 The reminder" width="31%"></a>
<br>
<a href="#rules"><img src="docs/en/sommaire/10.png" alt="10 Firestore rules" width="31%"></a>
<a href="#privacy"><img src="docs/en/sommaire/11.png" alt="11 Privacy" width="31%"></a>
<a href="#architecture"><img src="docs/en/sommaire/12.png" alt="12 Architecture" width="31%"></a>
<br>
<a href="#places"><img src="docs/en/sommaire/13.png" alt="13 Adding places" width="31%"></a>
<a href="#tests"><img src="docs/en/sommaire/14.png" alt="14 The tests" width="31%"></a>
<a href="#versions"><img src="docs/en/sommaire/15.png" alt="15 Versions" width="31%"></a>
</p>

<a id="features"></a>
<img src="docs/en/sections/s01.png" alt="01 Features" width="100%">

<img src="docs/en/schemas/fonctionnalites.svg" alt="The features of BeVannes, in nine cards that light up one after the other. One spot a day, the same for everyone, drawn by each phone. A hundred metres, no more: GPS confirms, a mock location is refused. The photo in 3:4, cropped and slimmed down on the phone. The daily wall, whose photos unlock once yours is posted. Points and streaks: 10 points, +2 per day of streak up to +10. The top hundred leaderboard. The reminder, at a different time every day. The history note of each of the nineteen spots. The demo, with its made-up community and teleporting." width="100%">

Three pieces hold the game together, and each one gets its own part below.

<img src="docs/en/schemas/fonctions.png" alt="The draw: a fixed-seed shuffle, every phone works out the same spot and nobody has to write it to the database. The distance: haversine, a hundred metre radius, a fresh fix when posting, a mock location flagged by Android is rejected. The rules: Firestore recomputes streak and points on every validation, the phone cannot award them to itself." width="100%">

<a id="screens"></a>
<img src="docs/en/sections/s02.png" alt="02 The screens" width="100%">

Three tabs at the bottom, Leaderboard, Today and Profile, and two screens that open on top: the photo, then the validation. Every screenshot comes from the demo build.

<img src="docs/en/schemas/ecrans.svg" alt="Six real BeVannes screens, side by side. Sign in, with an account and a nickname. The spot of the day, with the map and its hundred metre zone. Arriving on site, gauge full. The validation, with points and streak. The leaderboard, with the podium. The profile, with its numbers and the spots found." width="100%">

Every animation has a job: a radar marks the spot on the map, a gauge fills as you get closer, a shine sweeps the button once it becomes useful, and a validation is celebrated with a tick that draws itself and a burst of confetti. Screens settle in block by block, and the podium steps rise.

<img src="docs/en/schemas/vitrine.svg" alt="Animation: a phone scrolls through six real BeVannes screens: sign in, the spot of the day with its map, arriving on site with the gauge full, the validation with its tick and confetti, the leaderboard with its podium, and the profile." width="100%">

The palette fits in one colour: the teal of the logo, `#39D2C0`, on an almost black background. The orange of the flame is kept for streaks.

<a id="install"></a>
<img src="docs/en/sections/s03.png" alt="03 Install" width="100%">

<p align="center">
  <a href="https://github.com/Cybertrist/BeVannes/releases/latest/download/BeVannes.apk"><img src="docs/en/telecharger.png" alt="Download BeVannes, the full version, Android app" width="400"></a>
  <a href="https://github.com/Cybertrist/BeVannes/releases/latest/download/BeVannes-demo.apk"><img src="docs/en/telecharger-demo.png" alt="Try the BeVannes demo, no account, Android app" width="400"></a>
</p>

Two apps, which install side by side without getting in each other's way.

- **BeVannes**, the full version: the real game, connected to the server. One account, with the leaderboard, photos and streaks shared with the other players.
- **BeVannes démo**: a small made-up community, everything stays on the phone, and a "Me téléporter sur le lieu" switch to try validation without crossing Vannes.

Both are signed with the same key; an update installs over the previous one without losing anything. Android 5.0 or later, arm64 processor.

```
# SHA-256 of BeVannes.apk, version 2.1.0
8d25d9ecd2d6d0e5175adf36d63d6e58815335ea5c04ffd7bf8e58b6c87ead7e

# SHA-256 of BeVannes-demo.apk, version 2.1.0
92d5c9d0592950c7ae3c6936ab28e98d11f1b93cf3128b468b4e34d2bfa81eaf

# SHA-256 of the signing certificate, CN=BeVannes, O=Cybertrist
9a8c67645db4e34f4585d84e1db2addf9cbbabc01539bfb4ff57277c0f00feeb
```

**To build it**, you need Flutter. The demo is built with `--dart-define=DEMO=true`, which also gives it its own identifier, `fr.bevannes.bevannes.demo`. An APK built without a Firebase configuration opens in demo mode too: it never starts on an error.

```bash
git clone https://github.com/Cybertrist/BeVannes.git
cd BeVannes
flutter pub get
flutter run --dart-define=DEMO=true
```

**To play for real**, you need a Firebase project. The free plan, Spark, is enough.

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

> Client-side Firebase API keys are not secrets, they can be read from any APK. What protects the data are the **rules** in `firestore.rules`, detailed in part 10.

<a id="todays-spot"></a>
<img src="docs/en/sections/s04.png" alt="04 Today's spot" width="100%">

At midnight, every phone works out the spot of the day. Nobody writes it to the database, nobody gets to pick it, and yet everyone lands on the same one.

<img src="docs/en/schemas/tirage.svg" alt="Animation: a wheel scrolls through the places of Vannes, slows down and stops on Hôtel de Limur. At the same moment, three phones belonging to three players show the same spot: each one redoes the draw itself, no server involved." width="100%">

**The day number** counts the days since 1 January 1970, on the phone's local date: Thursday 24 September 2026 is day 20,720. It changes at midnight, whether the app is open or not.

**The cycle.** With nineteen places, a cycle lasts nineteen days, and each place comes up once. The order of a cycle is a Fisher-Yates shuffle, whose randomness comes from a fixed-seed generator, mulberry32, seeded with the cycle number. It only works on 32 bits: the same maths gives the same result on every phone.

**Never twice in a row.** If the first place of a cycle is the last one of the previous cycle, the first two swap. The `jour_test.dart` test checks over two thousand days that no place comes back the next day.

```dart
int indexDuLieu(int jour, int nb) {
  final cycle = jour ~/ nb;
  final ordre = _ordreDuCycle(cycle, nb);
  final dernierPrecedent = _ordreDuCycle(cycle - 1, nb).last;
  if (ordre.first == dernierPrecedent) {
    ordre[0] = ordre[1];
    ordre[1] = dernierPrecedent;
  }
  return ordre[jour % nb];
}
```

This computation is a contract between every installed phone. A test freezes its results over ten days: if it breaks, older versions and the new one no longer see the same spot.

<a id="on-site"></a>
<img src="docs/en/sections/s05.png" alt="05 On site" width="100%">

The map shows the spot and its hundred metre zone. The ring fills as you get closer, and the button only lights up once you are inside.

<img src="docs/en/schemas/approche.svg" alt="Animation: on a map, a player follows a route along the streets, three turns, to the spot of the day surrounded by a hundred metre zone and radar waves. On the right, a circular gauge fills while the distance drops from 620 metres. When the player enters the zone, the gauge is full, a tick appears and the “Take the photo” button unlocks." width="100%">

**A hundred metres.** Wide enough to absorb GPS noise between building fronts, tight enough that nobody validates from the next street. The distance comes from the haversine formula, on an Earth with a 6,371 km radius.

**The gauge** follows a logarithmic scale: full at a hundred metres, nearly empty at three kilometres. The last steps count as much as the first kilometre, and the ring still moves when you turn the corner.

**Two readings.** The position is tracked continuously, every three metres of movement, for the ring and the map. When posting, the app asks for a fresh one, with twenty seconds to get it: that is the one that decides.

**A mock location is refused.** Android flags apps that fake the position; the screen says so and the button stays off. If location is switched off or denied, the same screen offers to open the right setting.

<a id="photo"></a>
<img src="docs/en/sections/s06.png" alt="06 The photo" width="100%">

As in BeReal, every photo has the same frame: 3:4 portrait, whatever the camera.

<img src="docs/en/schemas/cadrage.svg" alt="Animation: a photo taken in 4:3 shows a city gate in the sun. Two dark bands drop on either side, leaving only a 3:4 portrait frame, which then moves to the right: 3:4, 900 × 1200 JPEG, cropped on the phone before upload." width="100%">

The camera returns whatever it likes, 4:3, 16:9 or square. The app first rotates the image according to its EXIF, since a portrait often arrives lying on its side, then crops it in the centre and scales it to 900 × 1200. The JPEG starts at quality 80; above 700 KB, the quality drops in steps of ten, down to 40. In practice a photo weighs between 100 and 250 KB.

The work happens off the main thread: decoding then re-encoding a JPEG takes a second, and the screen must not freeze meanwhile.

**Why Firestore, not Cloud Storage.** Storage is no longer offered on Firebase's free plan. A 900 × 1200 photo fits easily under the size limit of a Firestore document, 1 MB: it is stored as is, as bytes, and the whole game runs without paying anything.

<a id="wall"></a>
<img src="docs/en/sections/s07.png" alt="07 The daily wall" width="100%">

Other players' photos stay locked until you have posted yours.

<img src="docs/en/schemas/mur.svg" alt="Animation: four photos of the day, from Maëlle, Yann, Erwan and Klervi, are locked. A fifth photo, yours, drops into the last slot. The locks then come off one after another and the four photos are revealed. Firestore does the checking, not the app." width="100%">

The list, on the other hand, shows right away: who came by, at what time, how far from the spot, and how many points they earned. Only the pictures wait.

It is not the app that hides the photos, it is the server. The read rule on `photos` only lets an image through if it is your own, or if your own validation for that day exists:

```
allow read: if connecte()
  && (resource.data.uid == request.auth.uid
    || exists(/databases/$(database)/documents/validations/$(string(resource.data.jour) + '_' + request.auth.uid)));
```

A modified app would gain nothing: the database refuses to send the image.

<a id="points"></a>
<img src="docs/en/sections/s08.png" alt="08 Points and streaks" width="100%">

Ten points per spot, two more per day of streak, and the bonus stops at ten.

<img src="docs/en/schemas/serie.svg" alt="Animation: seven bars rise one after another, Monday to Sunday, +10, +12, +14, +16, +18, +20, +20. A flame lights up above every day of the streak, and a line marks the bonus cap. The total climbs to 110 points in one week; miss a day and the streak resets to 1." width="100%">

**The streak** goes on if the last validation was yesterday, and starts again at 1 otherwise. On screen, it drops to zero as soon as a day is missed, without waiting for the next validation. The best streak stays on the profile.

**The cap** is there for newcomers: beyond six days in a row, a validation always pays twenty points, and a player who joined late still has a chance on the leaderboard.

**The leaderboard** shows the top hundred by points, with the podium, your own rank and everyone's current streak.

<a id="reminder"></a>
<img src="docs/en/sections/s09.png" alt="09 The reminder" width="100%">

One notification a day, at a time that changes every day but lands at the same moment for everyone.

<img src="docs/en/schemas/rappel.svg" alt="Animation: a clock's hands jump from one time to the next, Wednesday 17:54, Thursday 14:43, Friday 13:18, Saturday 17:51. At each time, three phones buzz together and the same notification drops down: “It's time!”. The computation happens on each phone, with no server." width="100%">

The time comes out of the same generator as the draw, seeded this time with the day number: one minute out of six hundred, between 10:00 and 19:59. No server sends anything; each phone schedules its own notifications, on Paris time.

Every time it opens, the app schedules the next seven days, skipping a day already validated. The notification names the spot: *"Le lieu du jour : Hôtel de Limur. Sois-y avant minuit."* The reminder can be switched off on the profile.

<a id="rules"></a>
<img src="docs/en/sections/s10.png" alt="10 The Firestore rules" width="100%">

A validation passes through five stations, and it all goes through in one block, or not at all.

<img src="docs/en/schemas/parcours.svg" alt="Animation: a validation passes through five stations. The phone sends a 3:4 photo taken 20 metres from the spot; the photo goes to photos/20720_toi; Firestore writes the validation and updates the player; the rules recompute the streak, from 3 to 4, and the gain, 10 + 2 × 3 = 16; the leaderboard shows +16 points and 4th place. All or nothing." width="100%">

The phone writes three documents in a single transaction: the validation, the photo and the updated player. It only proposes: `firestore.rules` redoes the maths of `lib/domain/score.dart` and refuses anything that does not add up.

<img src="docs/en/schemas/triche.svg" alt="Animation: two phones send their points. The first proposes 136 → 152 with a streak going from 3 to 4: the rules redo the maths, 136 + 16 = 152, and accept. The second proposes 136 → 999: 136 + 16 is not 999, the rules refuse with permission-denied." width="100%">

What the rules check, write by write:

- **The day** must be today, on Paris time: no catching up on yesterday, no getting ahead.
- **The id** of a validation is `{jour}_{uid}`: one per player and per day, with no index and no query.
- **The distance** stored lies between 0 and 100 metres.
- **The photo** carries the same id, weighs under 900 KB, and only exists alongside its validation, written in the same transaction.
- **The points**: streak, gain, total, best streak and validation count are recomputed from the player's previous state.
- **The nickname**: 3 to 20 characters, accented letters included, the same rule as in the app.

A validation is never modified, and only its author can delete it, together with their account.

<a id="privacy"></a>
<img src="docs/en/sections/s11.png" alt="11 Privacy and limits" width="100%">

<img src="docs/en/schemas/confidentialite.svg" alt="Animation: in the middle, the phone. On the left, what never leaves it: the exact position, of which only the rounded distance goes out; the original photo, of which only the 3:4 version is sent; the draw of the spot, computed on the phone; the reminder time, a local notification. On the right, four packets leave for Firebase: e-mail and password in Authentication, read by nobody else; nickname, points and streak in joueurs, read by signed-in players; spot, distance and time in validations; the JPEG in photos, readable only by those who validated that day. Deleting your account erases everything." width="100%">

Coordinates never leave the phone: only the distance to the spot, rounded to the metre, is stored. The e-mail stays in Authentication, invisible to other players, who only see a nickname.

Deleting your account asks for the password again, then erases your photos, your validations, your player and finally the account. The password comes first: the server refuses to delete an account whose sign-in is not recent, and it is better to know that before erasing anything.

**The limits**, stated plainly:

- The playing field is Vannes. Anywhere else, there is nothing to discover.
- The position is whatever the phone reports. Android flags mock-location apps, and the game rejects them, but a modified phone can lie without saying so. The Firestore rules guarantee that points add up, not that the player was there.
- Photos are not moderated.
- OpenStreetMap's tiles are not meant for heavy traffic: beyond a circle of friends, it would take a tile server of your own.

<a id="architecture"></a>
<img src="docs/en/sections/s12.png" alt="12 Architecture" width="100%">

A Flutter app for Android, with Firebase behind it: Authentication for accounts, Firestore for players, validations and photos. The map comes from OpenStreetMap, no API key needed, and the fonts are bundled: no request to Google Fonts.

<img src="docs/en/schemas/stack.svg" alt="Animation: the BeVannes stack builds up package by package, from the base to the server. Flutter 3.47 and Dart 3.13 for the whole app. flutter_riverpod 3.4 for state: day, spot, position, distance. go_router 18 for the screens and the signed-out redirect. flutter_map 8.3 and OpenStreetMap for the map, with no API key. geolocator 14 for the position and the mocked-location flag. image_picker and image for the camera and the 3:4 crop. flutter_local_notifications for the reminder, scheduled seven days ahead. firebase_auth for the account, cloud_firestore for players, validations and photos." width="100%">

The code is layered. `lib/domain` holds the game rules, in plain Dart, free of Flutter and Firebase: that is what the tests target. `lib/data` talks to the outside world, and `lib/ui` draws.

<img src="docs/en/schemas/couches.svg" alt="Animation: the four BeVannes layers, lib/ui, providers.dart, lib/data and lib/domain, crossed by a tap on “Take the photo”. The token leaves EcranPhoto, goes through positionProvider, asks Localisation.actuelle for a fresh fix, goes down to the domain for distanceMetres, 20 metres out of 100 allowed, back up for recadrerPhoto in 3:4, down again for serieApres and gainPour, streak 4 and +16, and ends in FirebaseDepot.valider, a single transaction. The domain, 5 files and 233 lines of plain Dart, is the layer tested on its own." width="100%">

**One storage, two versions.** The `Depot` interface describes everything the app expects from its database. `FirebaseDepot` fills it with the real server, `DemoDepot` with eleven made-up Vannes locals in memory, who start from scratch at every launch. `main.dart` picks one or the other, and no screen knows which one it is using.

<img src="docs/en/schemas/modele.svg" alt="Animation: the BeVannes data model. Authentication keeps the uid, the e-mail and the hashed password. joueurs/{uid}: nickname, points, streak, best streak, validations, last day and creation date. validations/{jour}_{uid}: uid, nickname, day, spot, distance from 0 to 100, gain, streak, photo path and moment. photos/{jour}_{uid}: uid, day and the JPEG as bytes, under 900 KB. Links join the uids and the photo. The {jour}_{uid} id enforces a single validation per player and per day." width="100%">

```
lib/
├── domain/      jour, geo, score, lieu, modeles: the rules, in plain Dart
├── data/        depot, firebase_depot, demo_depot, position, cadrage, rappels, lieux
├── ui/          screens/ (ouverture, connexion, coquille, jour, photo, classement, profil)
│                widgets.dart, animations.dart
├── config/      theme.dart, env.dart
├── providers.dart
├── app.dart     the routes, and the redirect to sign-in
└── main.dart    Firebase or demo, the places, the first screen
```

<a id="places"></a>
<img src="docs/en/sections/s13.png" alt="13 Adding places" width="100%">

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

<a id="tests"></a>
<img src="docs/en/sections/s14.png" alt="14 The tests" width="100%">

<img src="docs/en/schemas/tests.svg" alt="Animation: flutter test, 16 tests turning green one by one. jour_test: the day number follows the local date, the draw is the same everywhere with frozen values, each spot comes once per cycle, never the same spot two days running, a single spot always comes back, the reminder falls between 10:00 and 19:59. geo_test: zero distance on the spot, 380 metres from the cathedral to Porte Saint-Vincent, 100 kilometres to Rennes, readable distances. score_test: the streak goes on or back to 1, the capped gain, the streak drops to zero after a missed day. demo_depot_test: one validation a day, the sorted leaderboard, nicknames." width="100%">

The tests target what cannot be forgiven: a draw that differs from one phone to another, a streak counted wrong, a wrong distance. They run with no device and no server, in two seconds.

```bash
flutter test
```

The Firestore rules, for their part, were checked against the real server: sign-up, validation, the daily wall and account deletion.

<a id="versions"></a>
<img src="docs/en/sections/s15.png" alt="15 Versions and licence" width="100%">

<img src="docs/en/schemas/versions.svg" alt="Animation: the three BeVannes versions, released on 24 September 2026, fall onto one another, the way they install over each other on the phone. At the bottom, the base never moves: the same signing key, certificate SHA-256 9a8c6764…0f00feeb. 2.0.0 at 11:43: the Flutter rewrite, replacing the FlutterFlow prototype, in demo mode. 2.0.1 at 12:34: the animations, radar, gauge, shine, tick and confetti. 2.1.0 at 17:27, the current version: two apps, the real game wired to Firebase and the demo next to it." width="100%">

Every Release, with its notes and SHA-256 fingerprints: [github.com/Cybertrist/BeVannes/releases](https://github.com/Cybertrist/BeVannes/releases).

The code is released under the [MIT](LICENSE) licence: free to read, reuse and modify, as long as the copyright notice stays. The Syne and Space Grotesk fonts are under the SIL Open Font licence, map tiles © OpenStreetMap contributors.

**What will never be in this repository:** the APK signing key and the Firebase configuration. `.gitignore` refuses `key.properties`, `.p12`, `.jks` and `.keystore` files, `google-services.json` and `firebase.env.json`.

<br>

<sub>Student project · Université Bretagne Sud, Vannes · Tristan Joncour. The images on this page come out of no drawing software: HTML pages captured by Chrome, and eighteen SVGs written by <code>anime.js</code>, seventeen of them animated. It is all in <a href="docs/tools/">docs/tools</a>.</sub>
