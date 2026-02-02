import 'dart:core';
import 'package:flutter/widgets.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:transaction_scraper/services/moov_scrapping_service.dart';
import 'package:transaction_scraper/services/orange_scrapping_service.dart';
import 'package:transaction_scraper/services/telecel_scrapping_service.dart';
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
    transactions.clear();
    try {
      List<Transaction> omTransactions =
          await OrangeScrappingService.readTransactions();
      List<Transaction> mvTransactions =
          await MoovScrappingService.readTransactions();
      List<Transaction> tcTransactions =
          await TelecelScrappingService.readTransactions();

      transactions.addAll(omTransactions);
      transactions.addAll(mvTransactions);
      transactions.addAll(tcTransactions);

      // Trier par date décroissante
      transactions.sort((a, b) => b.date.compareTo(a.date));

      debugPrint('Transactions trouvées: ${transactions.length}');
      return transactions;
    } catch (e) {
      debugPrint(e.toString());
      return [];
    }
  }
}
