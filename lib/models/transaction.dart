class Transaction {
  final String name;
  final DateTime date;
  final double amount;
  final bool isIncome;

  Transaction({
    required this.name,
    required this.date,
    required this.amount,
    required this.isIncome,
  });
}
