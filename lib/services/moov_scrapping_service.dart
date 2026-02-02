import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:transaction_scraper/models/operators.dart';
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

    final isReceived = bodyLower.contains('vous avez recu');
    if (!isReceived) return null;

    // Regex to capture amount like "500.00" or "1 010,00"
    final amountRegex = RegExp(r'recu\s+([\d\s,.]+)\s*FCFA', caseSensitive: false);
    final match = amountRegex.firstMatch(body);

    if (match == null) return null;

    final montantStr = match.group(1)!.replaceAll(' ', '').replaceAll(',', '.');
    final montant = double.tryParse(montantStr) ?? 0;

    if (montant == 0) return null;

    final date = msg.date ?? DateTime.now();
    final fromInfo = _extractFromInfo(body);

    return Transaction(
      name: fromInfo['name']!,
      date: date,
      amount: montant,
      isIncome: isReceived,
      operator: Operators.moov,
      phoneNumber: fromInfo['phone']!,
      transId: _extractTransId(body),
    );
  }

  static Map<String, String> _extractFromInfo(String body) {
    // Handles "du 57833104,RAYENDE..."
    final pattern1 = RegExp(r'du\s+(\d+),(.+?)(?=\.\s*Le solde|$)');
    final match1 = pattern1.firstMatch(body);
    if (match1 != null) {
      return {
        'phone': match1.group(1)!.trim(),
        'name': match1.group(2)!.trim(),
      };
    }

    // Handles "de Arnold ouedraogo Numero 22673537382"
    final pattern2 = RegExp(r'de\s+(.+?)\s+Numero\s+(\d+)');
    final match2 = pattern2.firstMatch(body);
    if (match2 != null) {
      return {
        'name': match2.group(1)!.trim(),
        'phone': match2.group(2)!.trim(),
      };
    }
    
    // Fallback for just "de Arnold ouedraogo"
    final pattern3 = RegExp(r'de\s+(.+?)(?=\s*Numero|\s*Date|\s*Solde|\.|$)');
    final match3 = pattern3.firstMatch(body);
     if (match3 != null) {
      return {
        'name': match3.group(1)!.trim(),
        'phone': 'Inconnu',
      };
    }

    return {'phone': 'Inconnu', 'name': 'Inconnu'};
  }

  static String _extractTransId(String body) {
    // Handles "Trans ID: PP..." and "TID: PP..."
    final transIdPattern = RegExp(r'(?:trans id|tid):\s*([\w\.]+)', caseSensitive: false);
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
