import 'dart:core';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:transaction_scraper/models/operators.dart';
import 'package:transaction_scraper/services/permission_service.dart';
import '../models/transaction.dart';

class OrangeScrappingService {
  static final SmsQuery query = SmsQuery();

  static Future<List<Transaction>> readTransactions() async {
    await PermissionService.requestSmsPermission();

    try {
      SmsQuery query = SmsQuery();

      final orangeMessages = await query.querySms(
        kinds: [SmsQueryKind.inbox],
        count: 500,
        address: "OrangeMoney",
      );

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

    final montantRegex = RegExp(r'([\d,]+\.\d{2})\s*fcfa', caseSensitive: false);
    final match = montantRegex.firstMatch(body);

    if (match == null) return null;

    final montantStr = match.group(1)!.replaceAll(',', '');
    final montant = double.tryParse(montantStr) ?? 0;

    if (montant == 0) return null;

    final isReceived = bodyLower.contains('vous avez recu');
    final date = msg.date ?? DateTime.now();

    final fromInfo = _extractFromInfo(body);

    return Transaction(
      name: fromInfo['name']!,
      date: date,
      amount: montant,
      isIncome: isReceived,
      operator: Operators.orange,
      phoneNumber: fromInfo['phone']!,
      transId: _extractTransId(body),
    );
  }

  static Map<String, String> _extractFromInfo(String body) {
    // Handles "du 57833104,RAYENDE..." and "du 66978384,NESSAN"
    final fromPattern = RegExp(r'du\s+(\d+),(.+?)(?=\.\s*Le solde|$)');
    final match = fromPattern.firstMatch(body);
    if (match != null) {
      return {
        'phone': match.group(1)!.trim(),
        'name': match.group(2)!.trim(),
      };
    }
    return {
      'phone': 'Inconnu',
      'name': 'Inconnu',
    };
  }

  static String _extractTransId(String body) {
    // Handles "Trans ID: PP260131.2058.45306212." and "trans id: 123456789"
    final transIdPattern = RegExp(r'trans id:\s*([\w\.]+)', caseSensitive: false);
    final match = transIdPattern.firstMatch(body);
    if (match != null) {
      String transId = match.group(1)!.trim();
      // Remove trailing dot if present
      if (transId.endsWith('.')) {
        transId = transId.substring(0, transId.length - 1);
      }
      return transId;
    }
    return 'Inconnu';
  }
}
