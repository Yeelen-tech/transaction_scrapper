import 'package:flutter/material.dart';
import 'package:transaction_scraper/models/transaction.dart';
import 'package:transaction_scraper/services/scrapping_service.dart';

class DashboardViewmodel extends ChangeNotifier {
  final ScrappingService scrappingService = ScrappingService();
  List<Transaction> transactions = [];
  bool isLoading = true;
  String? errorMessage;

  Future<void> getTransactions() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    
    try {
      transactions = await scrappingService.readTransactions();
    } catch (e) {
      errorMessage = 'Erreur: $e';
      transactions = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  double get totalEntrees {
    return transactions
        .where((t) => t.isIncome)
        .fold(0, (sum, t) => sum + t.amount);
  }

  double get totalSorties {
    return transactions
        .where((t) => !t.isIncome)
        .fold(0, (sum, t) => sum + t.amount);
  }
}
