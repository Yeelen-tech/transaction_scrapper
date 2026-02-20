import 'package:isar/isar.dart';
import 'package:transaction_scraper/models/operators.dart';

part 'transaction.g.dart';

@collection
class Transaction {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String transId;

  late String name;
  late DateTime date;
  late double amount;
  late bool isIncome;
  
  @enumerated
  late Operators operator;
  
  late String phoneNumber;
}
