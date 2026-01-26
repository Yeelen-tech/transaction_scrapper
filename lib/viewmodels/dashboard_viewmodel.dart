import 'dart:async';

import 'package:flutter/material.dart';
import 'package:transaction_scraper/models/transaction.dart';
import 'package:transaction_scraper/services/scrapping_service.dart';

class DashboardViewmodel extends ChangeNotifier {
  final ScrappingService scrappingService = ScrappingService();
  List<Transaction> transactions = [];
  bool isLoading = true;
  String? errorMessage;
  Timer? _refreshTimer;
  static const int refreshInterval = 10;

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
      startAutoRefresh();
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

  Future<void> refreshTransactions() async {
    errorMessage = null;

    try {
      transactions = await scrappingService.readTransactions();
      notifyListeners();
    } catch (e) {
      errorMessage = 'Erreur: $e';
      notifyListeners();
    }
  }

  /// Démarrer le rafraîchissement automatique
  void startAutoRefresh() {
    _refreshTimer?.cancel(); // Annuler le timer existant

    _refreshTimer = Timer.periodic(Duration(seconds: refreshInterval), (timer) {
      // Rafraîchir seulement si pas en cours de chargement
      if (!isLoading) {
        refreshTransactions();
      }
    });
  }

  /// Arrêter le rafraîchissement automatique
  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  /// Changer l'intervalle de rafraîchissement
  void setRefreshInterval(int seconds) {
    stopAutoRefresh();
    // refreshInterval = seconds; // Si vous voulez rendre refreshInterval non-final
    _refreshTimer = Timer.periodic(Duration(seconds: seconds), (timer) {
      if (!isLoading) {
        refreshTransactions();
      }
    });
  }
}
