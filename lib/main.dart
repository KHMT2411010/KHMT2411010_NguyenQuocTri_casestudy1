
import 'package:flutter/material.dart';
import 'add_transaction.dart';
import 'edit_transaction.dart';
import 'database_helper.dart';

void main() {
  runApp(const ExpenseManagerApp());
}

class ExpenseManagerApp extends StatelessWidget {
  const ExpenseManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Quản lý thu chi',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Arial',
        scaffoldBackgroundColor: const Color(0xFFF7F9FC),
      ),
      home: const StartPage(),
    );
  }
}

// ============================================================
// MODEL - kept in main.dart as requested
// ============================================================

enum TransactionType { expense, income }

class TransactionData {
  final int? id;
  final TransactionType type;
  final String category;
  final double amount;
  final DateTime date;
  final String note;

  const TransactionData({
    this.id,
    required this.type,
    required this.category,
    required this.amount,
    required this.date,
    required this.note,
  });
}

// ============================================================
// START PAGE
// ============================================================

class StartPage extends StatelessWidget {
  const StartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Color(0xFF2176C9),
                  size: 50,
                ),
              ),
              const SizedBox(height: 26),
              const Text(
                'Expense Manager',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF172B4D),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Quản lý chi tiêu cá nhân\nđơn giản và hiệu quả',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Color(0xFF667085),
                ),
              ),
              const Spacer(flex: 2),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HomePage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2176C9),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Bắt đầu',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// HOME PAGE
// ============================================================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedTab = 0;
  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final rows =
    await DatabaseHelper.instance.getTransactions();

    final loadedTransactions = rows.map((row) {
      return TransactionData(
        id: row['id'] as int,
        type: row['type'] == 'income'
            ? TransactionType.income
            : TransactionType.expense,
        category: row['category'] as String,
        amount: (row['amount'] as num).toDouble(),
        date: DateTime.parse(row['date'] as String),
        note: (row['note'] ?? '').toString(),
      );
    }).toList();

    if (!mounted) return;

    setState(() {
      transactions = loadedTransactions;
    });
}
  List<TransactionData> transactions = [
  ];

  double get income => transactions
      .where((e) => e.type == TransactionType.income)
      .fold(0.0, (sum, e) => sum + e.amount);

  double get expense => transactions
      .where((e) => e.type == TransactionType.expense)
      .fold(0.0, (sum, e) => sum + e.amount);

  double get balance => income - expense;

  Future<void> addTransaction() async {
    final result = await Navigator.push<TransactionData>(
      context,
      MaterialPageRoute(
        builder: (_) => const AddTransactionPage(),
      ),
    );

    if (!mounted || result == null) return;

    await DatabaseHelper.instance.insertTransaction({
      'type': result.type == TransactionType.income
          ? 'income'
          : 'expense',
      'category': result.category,
      'amount': result.amount,
      'date': result.date,
      'note': result.note,
    });

    await _loadTransactions();
  }

  Future<void> editTransaction(int index) async {
    final original = transactions[index];

    final result = await Navigator.push<TransactionData>(
      context,
      MaterialPageRoute(
        builder: (_) => EditTransactionPage(
          transaction: original,
        ),
      ),
    );

    if (!mounted || result == null) return;

    if (original.id == null) {
      throw StateError(
        'Giao dịch chưa có ID trong database.',
      );
    }

    await DatabaseHelper.instance.updateTransaction(
      original.id!,
      {
        'type': result.type == TransactionType.income
            ? 'income'
            : 'expense',
        'category': result.category,
        'amount': result.amount,
        'date': result.date,
        'note': result.note,
      },
    );

    await _loadTransactions();
  }

  String money(double value) {
    return '${value.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (m) => '.',
    )} đ';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: IndexedStack(
          index: selectedTab,
          children: [
            _homeTab(),
            _transactionTab(),
            _statisticsTab(),
          ],
        ),
      ),
      bottomNavigationBar: _bottomBar(),
      floatingActionButton: selectedTab == 0 || selectedTab == 1
          ? FloatingActionButton(
        onPressed: addTransaction,
        backgroundColor: const Color(0xFF2878EA),
        foregroundColor: Colors.white,
        elevation: 5,
        child: const Icon(Icons.add, size: 31),
      )
          : null,
    );
  }

  Widget _homeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 90),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _topBar(),
          const SizedBox(height: 18),
          _balanceCard(),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _summaryCard(
                  title: 'TỔNG THU NHẬP',
                  value: income,
                  color: const Color(0xFF4DBB67),
                  lightColor: const Color(0xFFE9F7EC),
                  icon: Icons.arrow_downward_rounded,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _summaryCard(
                  title: 'TỔNG CHI TIÊU',
                  value: expense,
                  color: const Color(0xFFF05B65),
                  lightColor: const Color(0xFFFFEAEC),
                  icon: Icons.arrow_upward_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Giao dịch gần đây',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => selectedTab = 1),
                child: const Text(
                  'Xem tất cả',
                  style: TextStyle(
                    color: Color(0xFF2477E8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _transactionList(),
        ],
      ),
    );
  }

  Widget _topBar() {
    return Row(
      children: [
        const Icon(Icons.menu, size: 24, color: Color(0xFF202733)),
        const SizedBox(width: 22),
        const Expanded(
          child: Text(
            'Quản lý thu chi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF202733),
            ),
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(
              Icons.notifications_none_rounded,
              size: 26,
              color: Color(0xFF202733),
            ),
            Positioned(
              right: -3,
              top: -5,
              child: Container(
                width: 15,
                height: 15,
                decoration: const BoxDecoration(
                  color: Color(0xFFF0445C),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text(
                  '3',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _balanceCard() {
    return Container(
      height: 135,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF4B83F4),
            Color(0xFF1761DF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Stack(
        children: [
          const Positioned(
            left: 0,
            right: 0,
            top: 32,
            child: Center(
              child: Text(
                'SỐ DƯ HIỆN TẠI   ◉',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 57,
            child: Center(
              child: Text(
                money(balance),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 29,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Positioned(
            right: 14,
            top: 25,
            child: SizedBox(
              width: 72,
              height: 78,
              child: Stack(
                children: [
                  Positioned(
                    top: 13,
                    left: 12,
                    child: Transform.rotate(
                      angle: 0.14,
                      child: Container(
                        width: 49,
                        height: 34,
                        decoration: BoxDecoration(
                          color: const Color(0xFF70C983),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Icon(
                          Icons.attach_money,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 29,
                    left: 4,
                    child: Container(
                      width: 57,
                      height: 45,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4D76AE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet,
                        color: Color(0xFF263F66),
                        size: 32,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 1,
                    bottom: 2,
                    child: Container(
                      width: 27,
                      height: 27,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFC43D),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.attach_money,
                        color: Color(0xFFD48B00),
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Positioned(
            bottom: 9,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Dot(active: true),
                _Dot(active: false),
                _Dot(active: false),
                _Dot(active: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard({
    required String title,
    required double value,
    required Color color,
    required Color lightColor,
    required IconData icon,
  }) {
    return Container(
      height: 59,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: lightColor,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          Container(
            width: 31,
            height: 31,
            decoration: BoxDecoration(
              color: color.withOpacity(.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 8,
                    color: Color(0xFF667085),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  money(value),
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _transactionList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFE9EDF2)),
      ),
      child: Column(
        children: List.generate(
          transactions.length,
              (index) => _transactionTile(index),
        ),
      ),
    );
  }

  Widget _transactionTile(int index) {
    final t = transactions[index];
    final isIncome = t.type == TransactionType.income;

    final iconData = {
      'Ăn uống': Icons.restaurant,
      'Di chuyển': Icons.directions_car,
      'Thu nhập': Icons.attach_money,
      'Mua sắm': Icons.shopping_cart,
      'Giáo dục': Icons.school,
      'Giải trí': Icons.sports_esports,
      'Hóa đơn': Icons.receipt,
      'Sức khỏe': Icons.favorite,
    }[t.category] ??
        Icons.category;

    final iconColor = {
      'Ăn uống': const Color(0xFFFF762F),
      'Di chuyển': const Color(0xFF2995F5),
      'Thu nhập': const Color(0xFF21A33A),
      'Mua sắm': const Color(0xFFA54AF3),
      'Giáo dục': const Color(0xFF13A1A0),
    }[t.category] ??
        const Color(0xFF2878EA);

    return InkWell(
      onTap: () => editTransaction(index),
      child: Container(
        height: 59,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Color(0xFFEEF1F5),
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(.14),
                shape: BoxShape.circle,
              ),
              child: Icon(
                iconData,
                color: iconColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.note.isEmpty ? t.category : t.note,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF263238),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        t.category,
                        style: const TextStyle(
                          fontSize: 9,
                          color: Color(0xFF8B95A1),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Text(
                        formatDate(t.date),
                        style: const TextStyle(
                          fontSize: 9,
                          color: Color(0xFF8B95A1),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              '${isIncome ? '+' : '-'}${money(t.amount)}',
              style: TextStyle(
                color: isIncome
                    ? const Color(0xFF20A63A)
                    : const Color(0xFFF04455),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _transactionTab() {
    return Column(
      children: [
        const SizedBox(height: 18),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Giao dịch',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 90),
            itemCount: transactions.length,
            itemBuilder: (_, index) {
              return _transactionTile(index);
            },
          ),
        ),
      ],
    );
  }

  Widget _statisticsTab() {
    return const Center(
      child: Text(
        'Thống kê',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _bottomBar() {
    return BottomNavigationBar(
      currentIndex: selectedTab,
      onTap: (index) {
        setState(() {
          selectedTab = index;
        });
      },
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFF2176E8),
      unselectedItemColor: const Color(0xFF667085),
      selectedFontSize: 10,
      unselectedFontSize: 10,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Trang chủ',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long_outlined),
          activeIcon: Icon(Icons.receipt_long),
          label: 'Giao dịch',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.pie_chart_outline),
          activeIcon: Icon(Icons.pie_chart),
          label: 'Thống kê',
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  final bool active;

  const _Dot({required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: active ? 11 : 5,
      height: 4,
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.white54,
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}

// ============================================================
// HELPERS
// ============================================================

String formatDate(DateTime date) {
  final d = date.day.toString().padLeft(2, '0');
  final m = date.month.toString().padLeft(2, '0');
  return '$d/$m/${date.year}';
}

String formatMoney(double value) {
  return value.toStringAsFixed(0).replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (m) => '.',
  );
}
