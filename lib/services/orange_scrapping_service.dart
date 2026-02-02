import 'dart:core';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
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

    final montantRegex = RegExp(r'(\d+,\d+\.\d{2})\s*fcfa', caseSensitive: false,);
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
      operator: 'Orange',
      phoneNumber: fromInfo['phone']!,
      transId: _extractTransId(body),
    );
  }

  static Map<String, String> _extractFromInfo(String body) {
    final fromPattern = RegExp(r'du\s+(\d{8}),([^,]+)');
    final match = fromPattern.firstMatch(body);
    if (match != null) {
      return {
        'phone': match.group(1)!,
        'name': match.group(2)!,
      };
    }
    return {
      'phone': 'Inconnu',
      'name': 'Inconnu',
    };
  }

  static String _extractTransId(String body) {
    final transIdPattern = RegExp(r'trans\s*id:\s*(\d+)');
    final match = transIdPattern.firstMatch(body);
    if (match != null) {
      return match.group(1)!;
    }
    return 'Inconnu';
  }
}
