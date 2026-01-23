# Transaction Scraper

Application mobile Flutter permettant de récupérer et afficher l'historique des transactions Orange Money depuis les SMS sur un téléphone Android.

## Fonctionnalités

- Lecture automatique des SMS Orange Money
- Affichage du total des entrées et sorties
- Liste détaillée des transactions avec date, heure et montant
- Gestion des permissions SMS
- Interface moderne avec Material Design

## Captures d'écran

L'application affiche :
- Une card en haut avec le total reçu (vert) et le total des sorties (rouge)
- Une liste des transactions avec le nom du destinataire, la date, l'heure et le montant en FCFA

## Installation

### Télécharger l'APK

📥 [Télécharger la dernière version (APK)](build/app/outputs/flutter-apk/app-release.apk)

### Depuis le code source

1. Cloner le repository
```bash
git clone https://github.com/Yeelen-tech/transaction_scrapper.git
cd transaction_scraper
```

2. Installer les dépendances
```bash
flutter pub get
```

3. Lancer l'application
```bash
flutter run
```

4. Compiler l'APK
```bash
flutter build apk --release
```

## Permissions requises

- `READ_SMS` : Pour lire les SMS de transactions
- `RECEIVE_SMS` : Pour recevoir les nouveaux SMS

## Technologies utilisées

- **Flutter** : Framework de développement
- **Provider** : Gestion d'état
- **flutter_sms_inbox** : Lecture des SMS
- **permission_handler** : Gestion des permissions
- **intl** : Formatage des dates

## Structure du projet

```
lib/
├── models/
│   └── transaction.dart          # Modèle de données
├── screens/
│   └── dashboard.dart            # Écran principal
├── services/
│   ├── scrapping_service.dart    # Service de lecture SMS
│   └── permission_service.dart   # Service de permissions
├── viewmodels/
│   └── dashboard_viewmodel.dart  # ViewModel du dashboard
└── main.dart                     # Point d'entrée
```

## Configuration Android

- **Package** : `com.yeelentech.transaction_scraper`
- **Min SDK** : 21
- **Target SDK** : 34

## Auteur

Yeelentech
