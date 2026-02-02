class Transaction {
  final String name;
  final DateTime date;
  final double amount;
  final bool isIncome;
  final String operator;
  final String phoneNumber;
  final String transId;

  Transaction({
    required this.name,
    required this.date,
    required this.amount,
    required this.isIncome,
    required this.operator,
    required this.phoneNumber,
    required this.transId,
  });
}
