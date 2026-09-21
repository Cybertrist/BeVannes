<div align="center">

# BeVannes

**BeReal rencontre GeoGuessr : un lieu par jour, il faut y aller pour marquer.**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=flat-square&logo=dart&logoColor=white)](https://dart.dev/)
[![Firebase](https://img.shields.io/badge/Firebase-backend-FFCA28?style=flat-square&logo=firebase&logoColor=black)](https://firebase.google.com/)
[![Licence](https://img.shields.io/badge/Licence-MIT-1F6FEB?style=flat-square)](LICENSE)

</div>

---

Chaque jour, l'application tire un lieu au sort dans Vannes et ses environs. Pour marquer des points, il faut s'y rendre physiquement : la position GPS est comparée à celle du spot, et la photo n'est validée que si vous y êtes vraiment. Chaque lieu s'accompagne d'une note historique ou culturelle, ce qui transforme la partie en visite guidée sans le vouloir.

L'idée de départ : on passe devant les mêmes rues tous les jours sans jamais s'arrêter. Une contrainte ludique suffit parfois à changer ça.

## Fonctionnement

| | |
|:--|:--|
| **Spot du jour** | Un lieu tiré au sort, le même pour tout le monde, renouvelé chaque jour |
| **Validation géolocalisée** | La photo ne compte que si le GPS confirme la présence sur place |
| **Classement** | Points cumulés, médailles et insignes pour les plus assidus |
| **Notifications** | Envoyées à une heure aléatoire, comme BeReal, pas le temps de préparer sa photo |

<div align="center">

![Spot du jour](https://github.com/user-attachments/assets/60fa2189-ca66-4503-a74e-9ef0048cd765)
![Partage de photo](https://github.com/user-attachments/assets/46b086a4-64bc-4796-88f6-9940040e50ab)
![Classement](https://github.com/user-attachments/assets/6d221ff1-1401-402e-bd8b-e078556d8c1e)

</div>

## Sous le capot

Développé avec Flutter, prototypé sur FlutterFlow, adossé à Firebase pour l'authentification, la base temps réel et les tâches planifiées.

Trois fonctions maison portent la logique de jeu :

| Fonction | Rôle |
|:--|:--|
| `compareLatLng` | Compare la position de l'utilisateur à celle du spot, avec une tolérance en mètres |
| `sameDay` | Vérifie que la tentative concerne bien le spot du jour en cours |
| `dateIsThisDay` | Normalise les dates entre fuseau de l'appareil et horodatage serveur |

C'est là que tout se joue : une tolérance trop large et on valide depuis son canapé, trop étroite et le bruit GPS en ville rend le jeu injouable.

## Installation

```bash
git clone https://github.com/Cybertrist/BeVannes.git
cd BeVannes
flutter pub get
```

### Firebase

Le projet a besoin de votre propre projet Firebase : les fichiers de configuration ne sont pas versionnés.

1. Créez un projet sur la [console Firebase](https://console.firebase.google.com/).
2. Activez **Authentication**, **Realtime Database** et **Storage**.
3. Téléchargez `google-services.json` et placez-le dans `android/app/`.
4. Pour iOS, `GoogleService-Info.plist` va dans `ios/Runner/`.

> Les clés d'API Firebase côté client ne sont pas des secrets, elles sont lisibles dans tout APK. Ce qui protège réellement les données, ce sont les **règles de sécurité** Realtime Database et Storage. Configurez-les avant d'ouvrir l'application à qui que ce soit.

### Lancement

```bash
flutter run
```

## Ajouter des lieux

Les spots sont décrits dans `data/spots.json` :

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

## Limites

- Le périmètre couvert est Vannes et ses alentours ; ailleurs, il n'y a rien à découvrir.
- La validation repose sur le GPS de l'appareil, qui reste falsifiable par une application de position fictive. Une vérification sérieuse demanderait un recoupement côté serveur.
- Le projet est né d'un prototype FlutterFlow : une partie du code généré n'a pas été reprise à la main.

---

<sub>Projet étudiant · Université Bretagne Sud, Vannes · Tristan Joncour</sub>
