import 'dart:async';

import 'package:flutter/material.dart';
import 'package:transaction_scraper/models/transaction.dart';
import 'package:transaction_scraper/services/scrapping_service.dart';

enum FilterPeriod {
  today,
  thisWeek,
  thisMonth,
  thisYear,
  all,
}

enum OperatorFilter {
  orange,
  moov,
  telecel,
  all,
}

class DashboardViewmodel extends ChangeNotifier {
  final ScrappingService scrappingService = ScrappingService();
  List<Transaction> _allTransactions = [];
  List<Transaction> filteredTransactions = [];
  FilterPeriod _activeFilter = FilterPeriod.all;
  OperatorFilter _activeOperatorFilter = OperatorFilter.all;

  FilterPeriod get activeFilter => _activeFilter;
  OperatorFilter get activeOperatorFilter => _activeOperatorFilter;

  bool isLoading = true;
  String? errorMessage;
  Timer? _refreshTimer;
  static const int refreshInterval = 10;

  Future<void> getTransactions() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      _allTransactions = await scrappingService.readTransactions();
      _allTransactions = _allTransactions.where((t) => t.isIncome).toList();
      applyFilter();
    } catch (e) {
      errorMessage = 'Erreur: $e';
      _allTransactions = [];
      filteredTransactions = [];
    } finally {
      isLoading = false;
      notifyListeners();
      startAutoRefresh();
    }
  }

  void applyFilter() {
    List<Transaction> periodFiltered;
    final now = DateTime.now();
    switch (_activeFilter) {
      case FilterPeriod.today:
        periodFiltered = _allTransactions.where((t) {
          return t.date.year == now.year &&
              t.date.month == now.month &&
              t.date.day == now.day;
        }).toList();
        break;
      case FilterPeriod.thisWeek:
        periodFiltered = _allTransactions.where((t) {
          final weekStart = now.subtract(Duration(days: now.weekday - 1));
          final weekEnd = weekStart.add(const Duration(days: 6));
          return t.date.isAfter(weekStart) && t.date.isBefore(weekEnd);
        }).toList();
        break;
      case FilterPeriod.thisMonth:
        periodFiltered = _allTransactions.where((t) {
          return t.date.year == now.year && t.date.month == now.month;
        }).toList();
        break;
      case FilterPeriod.thisYear:
        periodFiltered = _allTransactions.where((t) {
          return t.date.year == now.year;
        }).toList();
        break;
      case FilterPeriod.all:
        periodFiltered = List.from(_allTransactions);
        break;
    }

    if (_activeOperatorFilter == OperatorFilter.all) {
      filteredTransactions = periodFiltered;
    } else {
      String operatorToFilter = '';
      switch (_activeOperatorFilter) {
        case OperatorFilter.orange:
          operatorToFilter = 'orange';
          break;
        case OperatorFilter.moov:
          operatorToFilter = 'moov';
          break;
        case OperatorFilter.telecel:
          operatorToFilter = 'telecel';
          break;
        case OperatorFilter.all:
          break;
      }
      filteredTransactions = periodFiltered
          .where((t) => t.operator.toLowerCase() == operatorToFilter)
          .toList();
    }

    notifyListeners();
  }

  void setFilter(FilterPeriod filter) {
    _activeFilter = filter;
    applyFilter();
  }

  void setOperatorFilter(OperatorFilter filter) {
    _activeOperatorFilter = filter;
    applyFilter();
  }

  double get totalEntrees {
    return filteredTransactions.fold(0, (sum, t) => sum + t.amount);
  }

  Future<void> refreshTransactions() async {
    errorMessage = null;

    try {
      _allTransactions = await scrappingService.readTransactions();
      _allTransactions = _allTransactions.where((t) => t.isIncome).toList();
      applyFilter();
      notifyListeners();
    } catch (e) {
      errorMessage = 'Erreur: $e';
      notifyListeners();
    }
  }

  void startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(Duration(seconds: refreshInterval), (timer) {
      if (!isLoading) {
        refreshTransactions();
      }
    });
  }

  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  void setRefreshInterval(int seconds) {
    stopAutoRefresh();
    _refreshTimer = Timer.periodic(Duration(seconds: seconds), (timer) {
      if (!isLoading) {
        refreshTransactions();
      }
    });
  }
}
