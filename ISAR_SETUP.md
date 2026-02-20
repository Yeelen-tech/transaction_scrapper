# Configuration de la base de données Isar

## Installation des dépendances

Exécutez la commande suivante pour installer les dépendances :

```bash
flutter pub get
```

## Génération du code Isar

Après l'installation des dépendances, générez les fichiers Isar avec :

```bash
flutter pub run build_runner build
```

Ou pour une génération continue pendant le développement :

```bash
flutter pub run build_runner watch
```

Cela générera le fichier `transaction.g.dart` nécessaire pour Isar.

## Utilisation

Le service `IsarService` fournit les méthodes suivantes :

- `saveTransaction(Transaction)` : Sauvegarder une transaction
- `saveTransactions(List<Transaction>)` : Sauvegarder plusieurs transactions
- `getAllTransactions()` : Récupérer toutes les transactions
- `getTransactionByTransId(String)` : Récupérer une transaction par son ID
- `deleteTransaction(int)` : Supprimer une transaction
- `deleteAllTransactions()` : Supprimer toutes les transactions

Le champ `transId` est défini comme index unique pour éviter les doublons.
