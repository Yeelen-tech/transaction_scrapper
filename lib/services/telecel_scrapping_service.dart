
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:transaction_scraper/models/operators.dart';
import 'package:transaction_scraper/models/transaction.dart';
import 'package:transaction_scraper/services/permission_service.dart';

class TelecelScrappingService {
  static final SmsQuery query = SmsQuery();

  static Future<List<Transaction>> readTransactions() async {
    await PermissionService.requestSmsPermission();

    try {
      final telecelMessages = await query.querySms(
        kinds: [SmsQueryKind.inbox],
        count: 500,
        address: "TelecelMney", // Assuming "Telecel" is the sender address
      );

      List<Transaction> telecelTransactions = [];
      for (var message in telecelMessages) {
        Transaction? transaction = _parseMessageToTransaction(message);
        if (transaction != null) {
          telecelTransactions.add(transaction);
        }
      }

      return telecelTransactions;
    } catch (e) {
      return [];
    }
  }

  static Transaction? _parseMessageToTransaction(SmsMessage msg) {
    final body = msg.body;
    if (body == null || !body.contains('F CFA')) return null;

    final isReceived = body.toLowerCase().contains('vous avez reçu');
    if (!isReceived) return null; // Only handle incoming transactions for now

    // "Vous avez reçu [Montant] F CFA de [Nom/Numéro] le [Date] à [Heure]. ID transaction : [Numéro]. ..."

    // Regex to extract amount
    final amountRegex = RegExp(r'reçu ([\d\.]+) F CFA');
    final amountMatch = amountRegex.firstMatch(body);
    if (amountMatch == null) return null;

    final amountStr = amountMatch.group(1)!.replaceAll('.', ''); // Assuming dots are thousand separators
    final amount = double.tryParse(amountStr) ?? 0;
    if (amount == 0) return null;

    // Regex to extract sender info (Name/Number)
    final fromRegex = RegExp(r'de (.+?) le');
    final fromMatch = fromRegex.firstMatch(body);
    final fromText = fromMatch?.group(1)?.trim() ?? 'Inconnu';
    
    String name = fromText;
    String phoneNumber = 'Inconnu';

    // Basic check if it's a phone number
    if (RegExp(r'^[\d\s]+$').hasMatch(fromText)) {
      phoneNumber = fromText;
      name = 'Inconnu'; 
    }

    // Regex to extract transaction ID
    final transIdRegex = RegExp(r'ID transaction : ([A-Z0-9]+)\.');
    final transIdMatch = transIdRegex.firstMatch(body);
    final transId = transIdMatch?.group(1) ?? 'Inconnu';

    return Transaction()
      ..name = name
      ..date = msg.date ?? DateTime.now()
      ..amount = amount
      ..isIncome = isReceived
      ..operator = Operators.telecel
      ..phoneNumber = phoneNumber
      ..transId = transId;
  }
}
