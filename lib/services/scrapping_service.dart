import 'dart:core';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import '../models/transaction.dart';
import 'package:permission_handler/permission_handler.dart';

class ScrappingService {
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
      List<Transaction> transactions = [];
      for (var message in todayMessages) {
        Transaction? transaction = _parseMessageToTransaction(message);
        if (transaction != null) {
          transactions.add(transaction);
        }
      }

      return transactions;
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

    return Transaction(
      name: msg.address ?? 'Inconnu',
      date: date,
      amount: montant,
      isIncome: isReceived,
    );
  }
}
