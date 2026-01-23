# Release Notes - Transaction Scraper

## Version 1.0.0 - Release Initiale

### 🎉 Fonctionnalités

- **Lecture automatique des SMS Orange Money**
  - Analyse et extraction des transactions depuis les SMS
  - Filtrage intelligent des messages Orange Money
  - Détection automatique des montants en FCFA

- **Dashboard interactif**
  - Card récapitulative avec total des entrées (vert) et sorties (rouge)
  - Liste détaillée des transactions avec :
    - Nom du destinataire/expéditeur
    - Date et heure de la transaction
    - Montant en FCFA
    - Indicateur visuel (entrée/sortie)

- **Gestion des permissions**
  - Demande automatique de permission SMS au démarrage
  - Gestion sécurisée des accès

### 🛠️ Technologies

- Flutter SDK 3.10.3+
- Provider pour la gestion d'état
- flutter_sms_inbox pour la lecture des SMS
- permission_handler pour les permissions
- intl pour le formatage des dates

### 📱 Compatibilité

- Android 5.0 (API 21) et supérieur
- Architecture ARM64 et ARMv7

### 📥 Installation

1. Téléchargez le fichier APK
2. Activez "Sources inconnues" dans les paramètres Android
3. Installez l'APK
4. Accordez les permissions SMS lors du premier lancement

### ⚠️ Permissions requises

- `READ_SMS` - Lecture des SMS de transactions
- `RECEIVE_SMS` - Réception des nouveaux SMS

### 🐛 Problèmes connus

Aucun problème connu pour cette version.

### 📝 Notes

- L'application lit uniquement les SMS contenant "Orange" dans l'adresse
- Les montants sont extraits via regex pour détecter le format "XXXX FCFA"
- Les transactions sont classées automatiquement en entrées/sorties

---

**Développé par [@JulesC836](https://github.com/JulesC836)**
