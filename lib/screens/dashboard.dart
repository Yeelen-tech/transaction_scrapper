import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:transaction_scraper/viewmodels/dashboard_viewmodel.dart';

void main() {
  runApp(const DashboardScreen());
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dashboard Transactions',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: const TransactionDashboard(),
    );
  }
}

class TransactionDashboard extends StatefulWidget {
  const TransactionDashboard({super.key});

  @override
  State<TransactionDashboard> createState() => _TransactionDashboardState();
}

class _TransactionDashboardState extends State<TransactionDashboard> {
  String formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  String formatMontant(double amount) {
    return "${amount.toStringAsFixed(0)} FCFA";
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DashboardViewmodel>(context, listen: false).getTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Transactions'), elevation: 0),
      body: Consumer<DashboardViewmodel>(
        builder: (_, vm, _) {
          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final transactions = vm.filteredTransactions;
          final totalEntrees = vm.totalEntrees;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [Colors.green[400]!, Colors.green[600]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.arrow_downward,
                          color: Colors.white,
                          size: 30,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Total Entrées',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          formatMontant(totalEntrees),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterButton(
                        text: "Aujourd'hui",
                        onPressed: () => vm.setFilter(FilterPeriod.today),
                        isSelected: vm.activeFilter == FilterPeriod.today,
                      ),
                      FilterButton(
                        text: "Cette semaine",
                        onPressed: () => vm.setFilter(FilterPeriod.thisWeek),
                        isSelected: vm.activeFilter == FilterPeriod.thisWeek,
                      ),
                      FilterButton(
                        text: "Ce mois",
                        onPressed: () => vm.setFilter(FilterPeriod.thisMonth),
                        isSelected: vm.activeFilter == FilterPeriod.thisMonth,
                      ),
                      FilterButton(
                        text: "Cette année",
                        onPressed: () => vm.setFilter(FilterPeriod.thisYear),
                        isSelected: vm.activeFilter == FilterPeriod.thisYear,
                      ),
                      FilterButton(
                        text: "Tout",
                        onPressed: () => vm.setFilter(FilterPeriod.all),
                        isSelected: vm.activeFilter == FilterPeriod.all,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterButton(
                        text: "Orange",
                        onPressed: () => vm.setOperatorFilter(OperatorFilter.orange),
                        isSelected: vm.activeOperatorFilter == OperatorFilter.orange,
                      ),
                      FilterButton(
                        text: "Moov",
                        onPressed: () => vm.setOperatorFilter(OperatorFilter.moov),
                        isSelected: vm.activeOperatorFilter == OperatorFilter.moov,
                      ),
                      FilterButton(
                        text: "Telecel",
                        onPressed: () => vm.setOperatorFilter(OperatorFilter.telecel),
                        isSelected: vm.activeOperatorFilter == OperatorFilter.telecel,
                      ),
                      FilterButton(
                        text: "Tout",
                        onPressed: () => vm.setOperatorFilter(OperatorFilter.all),
                        isSelected: vm.activeOperatorFilter == OperatorFilter.all,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Historique des transactions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: Colors.green[100],
                          child: Icon(
                            Icons.arrow_downward,
                            color: Colors.green[700],
                          ),
                        ),
                        title: Text(
                          transaction.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(formatDate(transaction.date)),
                            Text(transaction.phoneNumber),
                          ],
                        ),
                        trailing: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "+ ${formatMontant(transaction.amount)}",
                              style: TextStyle(
                                color: Colors.green[700],
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Text(transaction.operator, style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class FilterButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isSelected;

  const FilterButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.blue : Colors.grey[300],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(color: isSelected ? Colors.white : Colors.black),
        ),
      ),
    );
  }
}
