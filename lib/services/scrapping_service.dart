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
    // Récupérer le timestamp de minuit aujourd'hui
    DateTime now = DateTime.now();
    DateTime todayStart = DateTime(now.year, now.month, now.day);
    int timestamp = todayStart.millisecondsSinceEpoch;

    final messages = await query.querySms(
      start: timestamp, // Filtre les messages après ce timestamp
    );

    List<Transaction> transactions = [];

    for (var msg in messages) {
      if (msg.address?.toLowerCase().contains('orangemoney') ?? false) {
        final transaction = _parseTransaction(msg);
        if (transaction != null) {
          transactions.add(transaction);
        }
      }
    }

    return transactions;
  }

  static Transaction? _parseTransaction(SmsMessage msg) {
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
