<div align="center">

<p>
  <a href="README.md"><img src="docs/langues/fr-off.png" alt="Lire cette page en français" width="150" /></a>
  <img src="docs/langues/en-on.png" alt="English, page shown" width="150" />
</p>

<img src="docs/en/banniere.png" alt="BeVannes, BeReal meets GeoGuessr" width="100%">

</div>

**BeReal meets GeoGuessr: one place a day, and you have to go there to score.**

Every day, the app draws a place at random in and around Vannes. To score, you have to physically go there: your GPS position is compared with the spot's, and the photo is only accepted if you really are on site. Each place comes with a historical or cultural note, which quietly turns the game into a guided tour.

The starting idea: we walk past the same streets every day without ever stopping. A playful constraint is sometimes enough to change that.

<img src="docs/en/sections/s01.png" alt="01 How it works" width="100%">

<img src="docs/en/schemas/fonctionnement.png" alt="Today's spot: a place drawn at random in and around Vannes, the same for everyone, renewed every day. Location-checked validation: the photo only counts if GPS confirms you are there, that is the whole rule of the game. The leaderboard: cumulative points, medals and badges for those who really do go out every day. The notifications: sent at a random time, like BeReal, no time to set up your shot." width="100%">

<div align="center">

<img src="docs/captures/spot.png" alt="The spot of the day screen, in French: the photo of the place, its position on the map, and the shutter button that turns into a validation once you are on site" width="70%">

<img src="docs/captures/partage.png" alt="The sharing screen for the photo taken on site, in French" width="70%">

<img src="docs/captures/classement.png" alt="The player leaderboard, in French" width="70%">

</div>

> The screenshots show the app in French, the only language it ships in.

<img src="docs/en/sections/s02.png" alt="02 Under the hood" width="100%">

Built with Flutter, prototyped on FlutterFlow, backed by Firebase for authentication, the realtime database and the scheduled jobs.

Three home-made functions carry the game logic.

<img src="docs/en/schemas/fonctions.png" alt="compareLatLng compares the user's position to the spot's, with a tolerance expressed in metres. sameDay checks that the attempt really is about the current day's spot. dateIsThisDay normalises dates between the device timezone and the server timestamp." width="100%">

That is where it all plays out. Too wide a tolerance and you validate from your sofa; too narrow and GPS noise in town makes the game unplayable.

<img src="docs/en/sections/s03.png" alt="03 Installation" width="100%">

```bash
git clone https://github.com/Cybertrist/BeVannes.git
cd BeVannes
flutter pub get
```

**Firebase.** The project needs your own Firebase project: the configuration files are not in git.

1. Create a project on the [Firebase console](https://console.firebase.google.com/).
2. Enable **Authentication**, **Realtime Database** and **Storage**.
3. Download `google-services.json` and drop it in `android/app/`.
4. For iOS, `GoogleService-Info.plist` goes in `ios/Runner/`.

> Client-side Firebase API keys are not secrets, they are readable in any APK. What actually protects the data are the Realtime Database and Storage **security rules**. Set them up before opening the app to anyone.

```bash
flutter run
```

<img src="docs/en/sections/s04.png" alt="04 Adding places" width="100%">

The spots are described in `data/spots.json`.

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

The `description` is not decoration: it is what separates a treasure hunt from a visit. It deserves some care.

<img src="docs/en/sections/s05.png" alt="05 Limits" width="100%">

The area covered is Vannes and its surroundings. Anywhere else, there is nothing to discover.

Validation rests on the device GPS, which a mock-location app can still fake. A serious check would need server-side cross-referencing, on the time of the shot and the plausibility of the movement.

The project grew out of a FlutterFlow prototype, and part of the generated code was never rewritten by hand.

Written in Flutter and Dart, with Firebase. MIT licence.

---

<sub>Student project · Université Bretagne Sud, Vannes · Tristan Joncour</sub>
