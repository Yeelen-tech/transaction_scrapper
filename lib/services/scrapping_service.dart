import 'dart:core';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import '../models/transaction.dart';
import 'package:permission_handler/permission_handler.dart';

class ScrappingService {
  List<Transaction> transactions = [];

  static final SmsQuery query = SmsQuery();

  static Future<void> requestSmsPermissions() async {
    var status = await Permission.sms.status;
    if (!status.isGranted) {
      await Permission.sms.request();
    }
  }

  Future<List<Transaction>> readTransactions() async {
    await ScrappingService.requestSmsPermissions();

    // Définir la période d'aujourd'hui
    DateTime now = DateTime.now();
    DateTime todayStart = DateTime(now.year, now.month, now.day, 0, 0, 0);
    DateTime todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    try {
      SmsQuery query = SmsQuery();

      // Récupérer les messages récents
      final orangeMessages = await query.querySms(
        kinds: [SmsQueryKind.inbox],
        count: 500,
        address: "OrangeMoney",
      );

      final moovMessages = await query.querySms(
        kinds: [SmsQueryKind.inbox],
        count: 500,
        address: "Moov Money",
      );

      // Filtrer les messages d'aujourd'hui
      List<SmsMessage> dayOMMessages = filterMessagesByDate(
        orangeMessages,
        todayStart,
        todayEnd,
      );

      List<SmsMessage> dayMVMessages = filterMessagesByDate(
        moovMessages, // Correction: utiliser moovMessages au lieu de orangeMessages
        todayStart,
        todayEnd,
      );

      print(
        'Messages trouvés aujourd\'hui: ${dayOMMessages.length + dayMVMessages.length}',
      );

      // Réinitialiser la liste des transactions
      transactions.clear();

      // Convertir en transactions OrangeMoney
      for (var message in dayOMMessages) {
        Transaction? transaction = _parseOrangeMessageToTransaction(message);
        if (transaction != null) {
          transactions.add(transaction);
        }
      }

      // Convertir en transactions Moov Money
      for (var message in dayMVMessages) {
        Transaction? transaction = _parseMoovMessageToTransaction(message);
        if (transaction != null) {
          transactions.add(transaction);
        }
      }

      // Trier par date décroissante
      transactions.sort((a, b) => b.date.compareTo(a.date));

      return transactions;
    } catch (e) {
      print('Erreur lors de la lecture des SMS: $e');
      return [];
    }
  }

  

  static Transaction? _parseOrangeMessageToTransaction(SmsMessage msg) {
    final body = msg.body ?? '';
    final bodyLower = body.toLowerCase();

    if (!bodyLower.contains('fcfa') && !bodyLower.contains('montant')) {
      return null;
    }

    // Extraire le montant (format OrangeMoney: 1 010,00 FCFA)
    final montantRegex = RegExp(
      r'(\d+(?:[\s]?\d+)*(?:,\d{2})?)\s*(?:FCFA|F\s*CFA|CFA)',
      caseSensitive: false,
    );
    final match = montantRegex.firstMatch(body);

    if (match == null) return null;

    // Nettoyer le montant (enlever espaces, remplacer virgule par point)
    final montantStr = match.group(1)!.replaceAll(' ', '').replaceAll(',', '.');
    final montant = double.tryParse(montantStr) ?? 0;

    if (montant == 0) return null;

    // Déterminer le type de transaction
    final isReceived =
        bodyLower.contains('reçu') ||
        bodyLower.contains('recu') ||
        bodyLower.contains('crédit') ||
        bodyLower.contains('credit');

    final date = msg.date ?? DateTime.now();

    // Extraire le nom du contact
    final contactName = _extractContactNameFromOrange(body, isReceived);

    return Transaction(
      name: contactName,
      date: date,
      amount: montant,
      isIncome: isReceived,
    );
  }

  static Transaction? _parseMoovMessageToTransaction(SmsMessage msg) {
    final body = msg.body ?? '';
    final bodyLower = body.toLowerCase();

    if (!bodyLower.contains('fcfa') && !bodyLower.contains('montant')) {
      return null;
    }

    // Extraire le montant (format Moov: 1,000.00 FCFA)
    final montantRegex = RegExp(
      r'(\d+(?:,\d{3})*(?:\.\d{1,2})?)\s*(?:FCFA|F\s*CFA|CFA)',
      caseSensitive: false,
    );
    final match = montantRegex.firstMatch(body);

    if (match == null) return null;

    // Nettoyer le montant (enlever virgules de séparation milliers)
    final montantStr = match.group(1)!.replaceAll(',', '');
    final montant = double.tryParse(montantStr) ?? 0;

    if (montant == 0) return null;

    // Déterminer le type de transaction
    final isReceived =
        bodyLower.contains('reçu') ||
        bodyLower.contains('recu') ||
        bodyLower.contains('crédit') ||
        bodyLower.contains('credit');

    final date = msg.date ?? DateTime.now();

    // Extraire le nom du contact
    final contactName = _extractContactNameFromMoov(body, isReceived);

    return Transaction(
      name: contactName,
      date: date,
      amount: montant,
      isIncome: isReceived,
    );
  }

  /// Extraire le nom du contact depuis un message OrangeMoney
  static String _extractContactNameFromOrange(String body, bool isReceived) {
    final RegExp nomPattern;

    if (isReceived) {
      // Pour les réceptions: "de [Nom]"
      nomPattern = RegExp(
        r'(?:de|from)\s+([A-Za-zÀ-ÿ\s]+?)(?:\s+(?:Numero|Numéro|Tel|N°|Date|\n)|$)',
        caseSensitive: false,
      );
    } else {
      // Pour les envois: "à [Nom]"
      nomPattern = RegExp(
        r'(?:à|a|to|vers)\s+([A-Za-zÀ-ÿ\s]+?)(?:\s+(?:Numero|Numéro|Tel|N°|Date|\n)|$)',
        caseSensitive: false,
      );
    }

    final match = nomPattern.firstMatch(body);
    if (match != null) {
      return match.group(1)!.trim();
    }

    return 'Contact inconnu';
  }

  /// Extraire le nom du contact depuis un message Moov Money
  /// Format: "du 66978384,NESSAN" ou "au numero 70123456,MARIE"
  static String _extractContactNameFromMoov(String body, bool isReceived) {
    final RegExp nomPattern;

    if (isReceived) {
      // Pour les réceptions: "du 66978384,NESSAN"
      nomPattern = RegExp(
        r'du\s+(\d{8}),\s*([A-Za-zÀ-ÿ\s]+?)(?:\.|Le solde|Trans)',
        caseSensitive: false,
      );
    } else {
      // Pour les envois: "au numero 70123456,PIERRE" ou "vers 70123456,PIERRE"
      nomPattern = RegExp(
        r'(?:au numero|vers)\s+(\d{8}),\s*([A-Za-zÀ-ÿ\s]+?)(?:\.|Le solde|Trans)',
        caseSensitive: false,
      );
    }

    final match = nomPattern.firstMatch(body);
    if (match != null) {
      final numero = match.group(1);
      final nom = match.group(2)?.trim();

      if (nom != null && nom.isNotEmpty) {
        return '$nom ($numero)';
      }
    }

    // Fallback: essayer de trouver juste le nom
    final nomSeulPattern = RegExp(
      r'(?:du|au numero|vers)\s+\d{8},\s*([A-Za-zÀ-ÿ]+)',
      caseSensitive: false,
    );

    final matchNomSeul = nomSeulPattern.firstMatch(body);
    if (matchNomSeul != null) {
      return matchNomSeul.group(1)!.trim();
    }

    return 'Contact inconnu';
  }

  static List<SmsMessage> filterMessagesByDate(
    List<SmsMessage> messages,
    DateTime start,
    DateTime end,
  ) {
    return messages
        .where(
          (message) =>
              message.date != null &&
              message.date!.isAfter(start) &&
              message.date!.isBefore(end.add(Duration(seconds: 1))),
        )
        .toList();
  }
}
