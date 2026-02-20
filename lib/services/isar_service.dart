import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:transaction_scraper/models/transaction.dart';

class IsarService {
  static Isar? _isar;

  static Future<Isar> get isar async {
    if (_isar != null) return _isar!;
    
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [TransactionSchema],
      directory: dir.path,
    );
    return _isar!;
  }

  static Future<void> saveTransaction(Transaction transaction) async {
    final db = await isar;
    await db.writeTxn(() async {
      await db.transactions.put(transaction);
    });
  }

  static Future<void> saveTransactions(List<Transaction> transactions) async {
    final db = await isar;
    await db.writeTxn(() async {
      await db.transactions.putAll(transactions);
    });
  }

  static Future<List<Transaction>> getAllTransactions() async {
    final db = await isar;
    return await db.transactions.where().sortByDateDesc().findAll();
  }

  static Future<Transaction?> getTransactionByTransId(String transId) async {
    final db = await isar;
    return await db.transactions.filter().transIdEqualTo(transId).findFirst();
  }

  static Future<void> deleteTransaction(int id) async {
    final db = await isar;
    await db.writeTxn(() async {
      await db.transactions.delete(id);
    });
  }

  static Future<void> deleteAllTransactions() async {
    final db = await isar;
    await db.writeTxn(() async {
      await db.transactions.clear();
    });
  }
}
