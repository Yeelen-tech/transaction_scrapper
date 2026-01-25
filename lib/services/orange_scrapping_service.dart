import 'dart:core';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:transaction_scraper/services/permission_service.dart';
import '../models/transaction.dart';

class OrangeScrappingService {
  static final SmsQuery query = SmsQuery();

  static Future<List<Transaction>> readTransactions() async {
    await PermissionService.requestSmsPermission();

    // Définir la période d'aujourd'hui
    DateTime now = DateTime.now();
    DateTime todayStart = DateTime(now.year, now.month, now.day, 0, 0, 0);
    DateTime todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    try {
      SmsQuery query = SmsQuery();

      // Récupérer les messages récents
      final allMessages = await query.querySms(
        kinds: [SmsQueryKind.inbox],
        count: 500,
      );

      // Filtrer les messages d'aujourd'hui
      final todayMessages = allMessages.where((msg) {
        if (msg.date == null) return false;

        return msg.date!.isAfter(todayStart) &&
            msg.date!.isBefore(todayEnd.add(Duration(seconds: 1)));
      }).toList();

      print('Messages trouvés aujourd\'hui: ${todayMessages.length}');

      // Convertir en transactions
      List<Transaction> orangeTransactions = [];
      for (var message in todayMessages) {
        Transaction? transaction = _parseMessageToTransaction(message);
        if (transaction != null) {
          orangeTransactions.add(transaction);
        }
      }

      return orangeTransactions;
    } catch (e) {
      print('Erreur lors de la lecture des SMS: $e');
      return [];
    }
  }

  static Transaction? _parseMessageToTransaction(SmsMessage msg) {
    final body = msg.body?.toLowerCase() ?? '';

    if (!body.contains('fcfa') && !body.contains('montant')) return null;

    final montantRegex = RegExp(r'(\d+[\s,.]?\d*)\s*fcfa');
    final match = montantRegex.firstMatch(body);

    if (match == null) return null;

    final montantStr = match.group(1)?.replaceAll(RegExp(r'[\s,]'), '') ?? '0';
    final montant = double.tryParse(montantStr) ?? 0;

    final isReceived =
        body.contains('reçu') ||
        body.contains('recu') ||
        body.contains('crédit');

    final date = msg.date ?? DateTime.now();
    final contactName = _extractContactNameFromOrange(body, isReceived);

    return Transaction(
      name: contactName,
      date: date,
      amount: montant,
      isIncome: isReceived,
    );
  }

  static String _extractContactNameFromOrange(String body, bool isReceived) {
    final RegExp nomPattern;

    if (isReceived) {
      // Pour les réceptions: "de [Nom]"
      nomPattern = RegExp(
        r'(?:du\s\d{8}\b)\s+([A-Za-zÀ-ÿ\s]+?)(?:\s+(?:Numero|Numéro|Tel|N°|Date|\n)|$)',
        caseSensitive: false,
      );
    } else {
      // Pour les envois: "à [Nom]"
      nomPattern = RegExp(
        r'(?:au\snumero\s\d{8}.\b)+([A-Za-zÀ-ÿ\s]+?)(?:\s+(?:Numero|Numéro|Tel|N°|Date|\n)|$)',
        caseSensitive: false,
      );
    }

    final match = nomPattern.firstMatch(body);
    if (match != null) {
      return match.group(1)!.trim();
    }

    return 'Contact inconnu';
  }
}
