import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:transaction_scraper/models/transaction.dart';
import 'package:transaction_scraper/services/permission_service.dart';

class MoovScrappingService {
  static final SmsQuery query = SmsQuery();

  static Future<List<Transaction>> readTransactions() async {
    await PermissionService.requestSmsPermission();

    try {
      SmsQuery query = SmsQuery();

      // Récupérer les messages Moov Money
      final moovMessages = await query.querySms(
        kinds: [SmsQueryKind.inbox],
        count: 500,
        address: "Moov Money",
      );

      // Convertir en transactions
      List<Transaction> moovTransactions = [];

      for (var message in moovMessages) {
        Transaction? transaction = _parseMessageToTransaction(message);
        if (transaction != null) {
          moovTransactions.add(transaction);
        }
      }

      return moovTransactions;
    } catch (e) {
      return [];
    }
  }

  static Transaction? _parseMessageToTransaction(SmsMessage msg) {
    final body = msg.body ?? '';
    final bodyLower = body.toLowerCase();

    if (!bodyLower.contains('fcfa')) return null;

    // Format: "Vous avez recu 1 010,00 FCFA de Arnold ouedraogo"
    final montantRegex = RegExp(r'(\d+\s\d+,\d{2})\s*fcfa', caseSensitive: false,);
    final match = montantRegex.firstMatch(body);

    if (match == null) return null;

    final montantStr = match.group(1)!.replaceAll(' ', '').replaceAll(',', '.');
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
      operator: 'Moov',
      phoneNumber: fromInfo['phone']!,
      transId: _extractTransId(body),
    );
  }

  static Map<String, String> _extractFromInfo(String body) {
    final fromPattern = RegExp(r'de\s+(.+)\s+Numero:\s+(\d+)');
    final match = fromPattern.firstMatch(body);
    if (match != null) {
      return {
        'name': match.group(1)!,
        'phone': match.group(2)!,
      };
    }
    return {
      'name': 'Inconnu',
      'phone': 'Inconnu',
    };
  }

  static String _extractTransId(String body) {
    final transIdPattern = RegExp(r'trans id:\s*(\d+)');
    final match = transIdPattern.firstMatch(body);
    if (match != null) {
      return match.group(1)!;
    }
    return 'Inconnu';
  }
}
