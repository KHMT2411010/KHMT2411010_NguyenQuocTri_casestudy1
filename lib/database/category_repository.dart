import 'package:sqflite/sqflite.dart';

import '../database_helper.dart';

class CategoryRepository {
  CategoryRepository._();

  static final instance = CategoryRepository._();

  final _storage = DatabaseHelper.instance;

  Future<List<String>> getCategories(String type) async {
    final rows = await _storage.getCategories(type: type);
    return rows.map((row) => row['name'] as String).toList();
  }

  Future<void> addCategory(String type, String name) async {
    final value = _validatedName(name);
    final db = await _storage.database;
    await db.transaction((txn) async {
      await _ensureAvailable(txn, type, value);
      await txn.insert('categories', {'name': value, 'type': type});
    });
  }

  Future<void> renameCategory(String type, String oldName, String newName) async {
    final value = _validatedName(newName);
    if (value == oldName) return;

    final db = await _storage.database;
    await db.transaction((txn) async {
      final id = await _editableId(txn, type, oldName);
      await _ensureAvailable(txn, type, value, exceptId: id);
      await txn.update(
        'categories',
        {'name': value},
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  Future<void> deleteCategory(String type, String name) async {
    final db = await _storage.database;
    await db.transaction((txn) async {
      final id = await _editableId(txn, type, name);
      await txn.delete('categories', where: 'id = ?', whereArgs: [id]);
    });
  }

  String _validatedName(String name) {
    final value = name.trim();
    if (value.isEmpty) {
      throw ArgumentError('Tên danh mục không được để trống');
    }
    return value;
  }

  Future<void> _ensureAvailable(
    DatabaseExecutor db,
    String type,
    String name, {
    int? exceptId,
  }) async {
    final rows = await db.query(
      'categories',
      columns: ['id', 'name'],
      where: 'type = ?',
      whereArgs: [type],
    );
    if (rows.any((row) =>
        row['id'] != exceptId &&
        (row['name'] as String).toLowerCase() == name.toLowerCase())) {
      throw StateError('Danh mục đã tồn tại');
    }
  }

  Future<int> _editableId(DatabaseExecutor db, String type, String name) async {
    if (name == 'Khác') {
      throw StateError('Danh mục mặc định được bảo vệ');
    }
    final rows = await db.query(
      'categories',
      columns: ['id'],
      where: 'type = ? AND name = ?',
      whereArgs: [type, name],
      limit: 1,
    );
    if (rows.isEmpty) throw StateError('Không tìm thấy danh mục');

    final id = rows.single['id'] as int;
    final uses = await db.query(
      'transactions',
      columns: ['id'],
      where: 'category_id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (uses.isNotEmpty) {
      throw StateError('Danh mục đang được sử dụng bởi giao dịch');
    }
    return id;
  }
}
