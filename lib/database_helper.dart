
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._internal();

  static final DatabaseHelper instance =
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'quanlychitieu.db');

    return openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            type TEXT NOT NULL
              CHECK (type IN ('income', 'expense')),
            UNIQUE(name, type)
          )
        ''');

        await db.execute('''
          CREATE TABLE transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            amount REAL NOT NULL CHECK (amount > 0),
            type TEXT NOT NULL
              CHECK (type IN ('income', 'expense')),
            category_id INTEGER NOT NULL,
            note TEXT NOT NULL DEFAULT '',
            date TEXT NOT NULL,
            FOREIGN KEY (category_id)
              REFERENCES categories(id)
              ON DELETE RESTRICT
          )
        ''');

        await db.execute('''
          CREATE INDEX idx_transactions_date
          ON transactions(date)
        ''');

        await db.execute('''
          CREATE INDEX idx_transactions_category
          ON transactions(category_id)
        ''');

        await _seedDefaultCategories(db);
      },
    );
  }

  // ==============================
  // 1. DANH MỤC MẶC ĐỊNH
  // ==============================

  Future<void> _seedDefaultCategories(DatabaseExecutor db) async {
    final categories = <Map<String, String>>[
      {'name': 'Lương', 'type': 'income'},
      {'name': 'Thưởng', 'type': 'income'},
      {'name': 'Đầu tư', 'type': 'income'},
      {'name': 'Thu nhập khác', 'type': 'income'},
      {'name': 'Ăn uống', 'type': 'expense'},
      {'name': 'Di chuyển', 'type': 'expense'},
      {'name': 'Mua sắm', 'type': 'expense'},
      {'name': 'Hóa đơn', 'type': 'expense'},
      {'name': 'Giải trí', 'type': 'expense'},
      {'name': 'Học tập', 'type': 'expense'},
      {'name': 'Chi phí khác', 'type': 'expense'},
    ];

    for (final category in categories) {
      await db.insert(
        'categories',
        category,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  // ==============================
  // 2. QUẢN LÝ DANH MỤC
  // ==============================

  Future<int> getOrCreateCategoryId(
      String name,
      String type,
      ) async {
    final db = await database;

    final normalizedName = name.trim();

    if (normalizedName.isEmpty) {
      throw ArgumentError('Tên danh mục không được để trống.');
    }

    if (type != 'income' && type != 'expense') {
      throw ArgumentError('Loại giao dịch không hợp lệ.');
    }

    final existing = await db.query(
      'categories',
      columns: ['id'],
      where: 'name = ? AND type = ?',
      whereArgs: [normalizedName, type],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      return existing.first['id'] as int;
    }

    return db.insert(
      'categories',
      {
        'name': normalizedName,
        'type': type,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    ).then((id) async {
      if (id != 0) return id;

      final result = await db.query(
        'categories',
        columns: ['id'],
        where: 'name = ? AND type = ?',
        whereArgs: [normalizedName, type],
        limit: 1,
      );

      if (result.isEmpty) {
        throw StateError('Không thể tạo danh mục.');
      }

      return result.first['id'] as int;
    });
  }

  Future<List<Map<String, dynamic>>> getCategories({
    String? type,
  }) async {
    final db = await database;

    return db.query(
      'categories',
      where: type == null ? null : 'type = ?',
      whereArgs: type == null ? null : [type],
      orderBy: 'name COLLATE NOCASE ASC',
    );
  }

  // ==============================
  // 3. THÊM GIAO DỊCH
  // ==============================

  Future<int> insertTransaction(
      Map<String, dynamic> transaction,
      ) async {
    final db = await database;

    final amount = _parseAmount(transaction['amount']);
    final type = transaction['type'] as String;
    final category = transaction['category'] as String;
    final note = (transaction['note'] ?? '').toString();

    if (amount <= 0) {
      throw ArgumentError('Số tiền phải lớn hơn 0.');
    }

    if (type != 'income' && type != 'expense') {
      throw ArgumentError('Loại giao dịch không hợp lệ.');
    }

    final categoryId = await getOrCreateCategoryId(
      category,
      type,
    );

    final date = _normalizeDate(transaction['date']);

    return db.insert('transactions', {
      'amount': amount,
      'type': type,
      'category_id': categoryId,
      'note': note,
      'date': date,
    });
  }

  // ==============================
  // 4. LẤY DANH SÁCH GIAO DỊCH
  // ==============================

  Future<List<Map<String, dynamic>>> getTransactions({
    String? type,
    String? startDate,
    String? endDate,
    int? categoryId,
  }) async {
    final db = await database;

    final conditions = <String>[];
    final args = <Object?>[];

    if (type != null) {
      conditions.add('t.type = ?');
      args.add(type);
    }

    if (startDate != null) {
      conditions.add('t.date >= ?');
      args.add(startDate);
    }

    if (endDate != null) {
      conditions.add('t.date <= ?');
      args.add(endDate);
    }

    if (categoryId != null) {
      conditions.add('t.category_id = ?');
      args.add(categoryId);
    }

    final whereClause = conditions.isEmpty
        ? ''
        : 'WHERE ${conditions.join(' AND ')}';

    return db.rawQuery('''
      SELECT
        t.id,
        t.amount,
        t.type,
        t.category_id,
        c.name AS category,
        t.note,
        t.date
      FROM transactions AS t
      INNER JOIN categories AS c
        ON t.category_id = c.id
      $whereClause
      ORDER BY t.date DESC, t.id DESC
    ''', args);
  }

  // ==============================
  // 5. LẤY MỘT GIAO DỊCH THEO ID
  // ==============================

  Future<Map<String, dynamic>?> getTransactionById(
      int id,
      ) async {
    final db = await database;

    final result = await db.rawQuery('''
      SELECT
        t.id,
        t.amount,
        t.type,
        t.category_id,
        c.name AS category,
        t.note,
        t.date
      FROM transactions AS t
      INNER JOIN categories AS c
        ON t.category_id = c.id
      WHERE t.id = ?
      LIMIT 1
    ''', [id]);

    if (result.isEmpty) {
      return null;
    }

    return result.first;
  }

  // ==============================
  // 6. CẬP NHẬT GIAO DỊCH
  // ==============================

  Future<int> updateTransaction(
      int id,
      Map<String, dynamic> transaction,
      ) async {
    final db = await database;

    final amount = _parseAmount(transaction['amount']);
    final type = transaction['type'] as String;
    final category = transaction['category'] as String;
    final note = (transaction['note'] ?? '').toString();

    if (amount <= 0) {
      throw ArgumentError('Số tiền phải lớn hơn 0.');
    }

    if (type != 'income' && type != 'expense') {
      throw ArgumentError('Loại giao dịch không hợp lệ.');
    }

    final categoryId = await getOrCreateCategoryId(
      category,
      type,
    );

    return db.update(
      'transactions',
      {
        'amount': amount,
        'type': type,
        'category_id': categoryId,
        'note': note,
        'date': _normalizeDate(transaction['date']),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==============================
  // 7. XÓA GIAO DỊCH
  // ==============================

  Future<int> deleteTransaction(int id) async {
    final db = await database;

    return db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==============================
  // 8. TÍNH TỔNG THU, CHI, SỐ DƯ
  // ==============================

  Future<Map<String, double>> getSummary({
    String? startDate,
    String? endDate,
  }) async {
    final db = await database;

    final conditions = <String>[];
    final args = <Object?>[];

    if (startDate != null) {
      conditions.add('date >= ?');
      args.add(startDate);
    }

    if (endDate != null) {
      conditions.add('date <= ?');
      args.add(endDate);
    }

    final whereClause = conditions.isEmpty
        ? ''
        : 'WHERE ${conditions.join(' AND ')}';

    final result = await db.rawQuery('''
      SELECT
        COALESCE(
          SUM(CASE WHEN type = 'income'
              THEN amount ELSE 0 END),
          0
        ) AS totalIncome,
        COALESCE(
          SUM(CASE WHEN type = 'expense'
              THEN amount ELSE 0 END),
          0
        ) AS totalExpense
      FROM transactions
      $whereClause
    ''', args);

    final income =
    (result.first['totalIncome'] as num).toDouble();

    final expense =
    (result.first['totalExpense'] as num).toDouble();

    return {
      'totalIncome': income,
      'totalExpense': expense,
      'balance': income - expense,
    };
  }

  // ==============================
  // 9. THỐNG KÊ CHI TIÊU THEO DANH MỤC
  // ==============================

  Future<List<Map<String, dynamic>>> getExpenseByCategory({
    String? startDate,
    String? endDate,
  }) async {
    final db = await database;

    final conditions = <String>["t.type = 'expense'"];
    final args = <Object?>[];

    if (startDate != null) {
      conditions.add('t.date >= ?');
      args.add(startDate);
    }

    if (endDate != null) {
      conditions.add('t.date <= ?');
      args.add(endDate);
    }

    return db.rawQuery('''
      SELECT
        c.id AS category_id,
        c.name AS category,
        SUM(t.amount) AS total
      FROM transactions AS t
      INNER JOIN categories AS c
        ON t.category_id = c.id
      WHERE ${conditions.join(' AND ')}
      GROUP BY c.id, c.name
      ORDER BY total DESC
    ''', args);
  }

  // ==============================
  // 10. XỬ LÝ SỐ TIỀN VÀ NGÀY
  // ==============================

  double _parseAmount(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      final normalized = value
          .replaceAll('₫', '')
          .replaceAll('đ', '')
          .replaceAll('.', '')
          .replaceAll(',', '')
          .replaceAll(' ', '')
          .trim();

      final amount = double.tryParse(normalized);

      if (amount != null) {
        return amount;
      }
    }

    throw ArgumentError('Số tiền không hợp lệ.');
  }

  String _normalizeDate(dynamic value) {
    if (value is DateTime) {
      final date = DateTime(
        value.year,
        value.month,
        value.day,
      );

      return date.toIso8601String();
    }

    if (value is String) {
      final parsed = DateTime.tryParse(value);

      if (parsed != null) {
        final date = DateTime(
          parsed.year,
          parsed.month,
          parsed.day,
        );

        return date.toIso8601String();
      }
    }

    throw ArgumentError('Ngày giao dịch không hợp lệ.');
  }

  // ==============================
  // 11. ĐÓNG DATABASE
  // ==============================

  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}