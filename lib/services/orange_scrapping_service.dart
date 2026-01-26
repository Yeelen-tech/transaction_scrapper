import 'dart:core';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:transaction_scraper/services/permission_service.dart';
import '../models/transaction.dart';

class OrangeScrappingService {
  static final SmsQuery query = SmsQuery();

  static Future<List<Transaction>> readTransactions() async {
    await PermissionService.requestSmsPermission();

    // Définir la période d'aujourd'hui
    // DateTime now = DateTime.now();
    // DateTime todayStart = DateTime(now.year, now.month, now.day, 0, 0, 0);
    // DateTime todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    try {
      SmsQuery query = SmsQuery();

      // Récupérer les messages Orange Money
      final orangeMessages = await query.querySms(
        kinds: [SmsQueryKind.inbox],
        count: 500,
        address: "OrangeMoney",
      );

      // Convertir en transactions
      List<Transaction> orangeTransactions = [];
      for (var message in orangeMessages) {
        Transaction? transaction = _parseMessageToTransaction(message);
        if (transaction != null) {
          orangeTransactions.add(transaction);
        }
      }

      return orangeTransactions;
    } catch (e) {
      return [];
    }
  }

  static Transaction? _parseMessageToTransaction(SmsMessage msg) {
    final body = msg.body ?? '';
    final bodyLower = body.toLowerCase();

    if (!bodyLower.contains('fcfa')) return null;

    // Format: "Vous avez recu 1,000.00 FCFA du 66978384,NESSAN"
    final montantRegex = RegExp(
      r'(\d+,\d+\.\d{2})\s*fcfa',
      caseSensitive: false,
    );
    final match = montantRegex.firstMatch(body);

    if (match == null) return null;

    final montantStr = match.group(1)!.replaceAll(',', '');
    final montant = double.tryParse(montantStr) ?? 0;

    if (montant == 0) return null;

    final isReceived = bodyLower.contains('vous avez recu');
    final date = msg.date ?? DateTime.now();
    final contactName = _extractContactName(body);

    return Transaction(
      name: contactName,
      date: date,
      amount: montant,
      isIncome: isReceived,
    );
  }

  static String _extractContactName(String body) {
    // Format: "du 66978384,NESSAN"
    final nomPattern = RegExp(r'du\s+\d{8},([^.]+)', caseSensitive: false);

    final match = nomPattern.firstMatch(body);
    if (match != null) {
      return match.group(1)!.trim();
    }

    return 'Contact inconnu';
  }
}
