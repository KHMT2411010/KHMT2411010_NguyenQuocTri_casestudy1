import 'package:sqflite/sqflite.dart';

import '../database_helper.dart';
import '../models/transaction_model.dart';

class ExpenseDatabase {
  ExpenseDatabase._();

  static final instance = ExpenseDatabase._();

  final _storage = DatabaseHelper.instance;

  Future<List<TransactionModel>> getTransactions() async {
    final rows = await _storage.getTransactions();
    return rows.map((row) {
      final category = row['category'] as String;
      final note = row['note'] as String;
      return TransactionModel(
        id: row['id'] as int,
        title: note.isEmpty ? category : note,
        amount: (row['amount'] as num).toDouble(),
        type: row['type'] as String,
        date: row['date'] as String,
        category: category,
        note: note,
      );
    }).toList();
  }

  Future<int> insertTransaction(TransactionModel item) =>
      _storage.insertTransaction(item.toMap());

  Future<int> updateTransaction(TransactionModel item) =>
      _storage.updateTransaction(item.id!, item.toMap());

  Future<int> deleteTransaction(int id) => _storage.deleteTransaction(id);

  Future<String?> getSetting(String key) async {
    final db = await _storage.database;
    final rows = await db.query(
      'app_settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.single['value'] as String;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await _storage.database;
    await db.insert(
      'app_settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
