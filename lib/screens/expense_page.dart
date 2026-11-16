import 'package:flutter/material.dart';

import '../database/expense_database.dart';
import '../models/transaction_model.dart';
import 'ui_helpers.dart';

class ExpensePage extends StatefulWidget {
  final VoidCallback? onViewAll;

  const ExpensePage({super.key, this.onViewAll});

  @override
  State<ExpensePage> createState() => _ExpensePageState();
}

class _ExpensePageState extends State<ExpensePage> {
  static const Color mainBlue = Color(0xFF1769EB);
  static const Color background = Color(0xFFF6F8FD);
  static const Color darkText = Color(0xFF172033);

  List<TransactionModel> items = [];
  bool loading = true;
  bool showBalance = true;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  // ĐỌC DỮ LIỆU TỪ SQLITE
  Future<void> refresh() async {
    try {
      final data = await ExpenseDatabase.instance.getTransactions();

      if (!mounted) return;

      setState(() {
        items = data;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      snack(context, 'Lỗi SQLite: $e');
    }
  }

  // TỔNG THU NHẬP
  double get income {
    return items
        .where((item) => item.type == 'income')
        .fold<double>(0, (sum, item) => sum + item.amount);
  }

  // TỔNG CHI TIÊU
  double get expense {
    return items
        .where((item) => item.type == 'expense')
        .fold<double>(0, (sum, item) => sum + item.amount);
  }

  // ĐỊNH DẠNG NGÀY
  String formatDate(String value) {
    try {
      final date = DateTime.parse(value);

      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');

      return '$day/$month/${date.year}';
    } catch (_) {
      return value;
    }
  }

  // ICON THEO DANH MỤC
  IconData categoryIcon(TransactionModel item) {
    final text = '${item.category} ${item.title}'.toLowerCase();

    if (text.contains('ăn') || text.contains('uống') || text.contains('cơm')) {
      return Icons.restaurant;
    }

    if (text.contains('xe') ||
        text.contains('xăng') ||
        text.contains('di chuyển')) {
      return Icons.directions_car;
    }

    if (text.contains('lương') || text.contains('thu nhập')) {
      return Icons.attach_money;
    }

    if (text.contains('mua') || text.contains('sắm')) {
      return Icons.shopping_cart;
    }

    if (text.contains('học') || text.contains('giáo dục')) {
      return Icons.school;
    }

    if (text.contains('giải trí')) {
      return Icons.sports_esports;
    }

    if (item.type == 'income') {
      return Icons.attach_money;
    }

    return Icons.receipt_long;
  }

  // MÀU SẮC THEO DANH MỤC
  Color categoryColor(TransactionModel item) {
    final text = '${item.category} ${item.title}'.toLowerCase();

    if (text.contains('ăn') || text.contains('uống') || text.contains('cơm')) {
      return const Color(0xFFFF6B24);
    }

    if (text.contains('xe') ||
        text.contains('xăng') ||
        text.contains('di chuyển')) {
      return const Color(0xFF2196F3);
    }

    if (text.contains('mua') || text.contains('sắm')) {
      return const Color(0xFFA83CF5);
    }

    if (text.contains('học') || text.contains('giáo dục')) {
      return const Color(0xFF009C96);
    }

    if (item.type == 'income') {
      return const Color(0xFF26A53C);
    }

    return mainBlue;
  }

  // THÊM GIAO DỊCH
  Future<void> addTransaction() async {
    final added = await editTransaction(context);

    if (!mounted) return;

    if (added) {
      await refresh();
    }
  }

  // SỬA HOẶC XÓA GIAO DỊCH
  Future<void> transactionActions(TransactionModel item) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(item.category),
              ),
              ListTile(
                leading: const Icon(Icons.edit, color: mainBlue),
                title: const Text('Sửa giao dịch'),
                onTap: () {
                  Navigator.pop(sheetContext, 'edit');
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Xóa giao dịch'),
                onTap: () {
                  Navigator.pop(sheetContext, 'delete');
                },
              ),
            ],
          ),
        );
      },
    );

    if (!mounted) return;

    if (action == 'edit') {
      final updated = await editTransaction(context, existing: item);

      if (!mounted) return;

      if (updated) {
        await refresh();
      }
    }

    if (action == 'delete') {
      if (!mounted) return;

      final deleted = await removeTransaction(context, item);

      if (!mounted) return;

      if (deleted) {
        await refresh();
      }
    }
  }

  // THANH TIÊU ĐỀ TRẮNG
  Widget buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu),
            color: darkText,
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                builder: (sheetContext) {
                  return SafeArea(
                    child: ListTile(
                      leading: const Icon(Icons.receipt_long, color: mainBlue),
                      title: const Text('Tất cả giao dịch'),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        widget.onViewAll?.call();
                      },
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(width: 7),
          const Expanded(
            child: Text(
              'Quản lý thu chi',
              style: TextStyle(
                color: darkText,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none, size: 26),
            onPressed: () {
              snack(context, 'Chưa có thông báo mới');
            },
          ),
        ],
      ),
    );
  }

  // THẺ SỐ DƯ MÀU XANH
  Widget buildBalanceCard() {
    final balance = income - expense;

    return Container(
      height: 146,
      margin: const EdgeInsets.fromLTRB(14, 14, 14, 11),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF418AFF), Color(0xFF0753D8)],
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: mainBlue.withValues(alpha: 0.16),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -48,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),

          Positioned(
            right: 6,
            bottom: 4,
            child: SizedBox(
              width: 120,
              height: 112,
              child: Stack(
                children: [
                  Positioned(
                    right: 23,
                    top: 4,
                    child: Transform.rotate(
                      angle: -0.18,
                      child: const Icon(
                        Icons.payments,
                        color: Color(0xFF79DC91),
                        size: 64,
                      ),
                    ),
                  ),
                  const Positioned(
                    right: 7,
                    bottom: 10,
                    child: Icon(
                      Icons.account_balance_wallet,
                      color: Color(0xFF123B9F),
                      size: 87,
                    ),
                  ),
                  const Positioned(
                    right: 13,
                    bottom: 3,
                    child: Icon(
                      Icons.monetization_on,
                      color: Color(0xFFFFCB38),
                      size: 36,
                    ),
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 25, 110, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Flexible(
                      child: Text(
                        'SỐ DƯ HIỆN TẠI',
                        maxLines: 1,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 3),
                    InkWell(
                      onTap: () {
                        setState(() {
                          showBalance = !showBalance;
                        });
                      },
                      child: Icon(
                        showBalance
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.white,
                        size: 17,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    showBalance ? money(balance) : '••••••••',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            bottom: 9,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 13,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                const SizedBox(width: 5),
                ...List.generate(
                  3,
                  (index) => Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Ô THU NHẬP VÀ CHI TIÊU
  Widget summaryCard({
    required String title,
    required double amount,
    required Color color,
    required Color backgroundColor,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        height: 85,
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: color,
              child: Icon(icon, color: Colors.white, size: 21),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    style: const TextStyle(
                      color: Color(0xFF596270),
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      money(amount),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSummary() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          summaryCard(
            title: 'TỔNG THU NHẬP',
            amount: income,
            color: const Color(0xFF28A745),
            backgroundColor: const Color(0xFFE7F6EA),
            icon: Icons.arrow_downward,
          ),
          const SizedBox(width: 9),
          summaryCard(
            title: 'TỔNG CHI TIÊU',
            amount: expense,
            color: const Color(0xFFEF4F5E),
            backgroundColor: const Color(0xFFFFE9EC),
            icon: Icons.arrow_upward,
          ),
        ],
      ),
    );
  }

  // TIÊU ĐỀ GIAO DỊCH GẦN ĐÂY
  Widget buildRecentHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 19, 14, 7),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Giao dịch gần đây',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: darkText,
              ),
            ),
          ),
          TextButton(
            onPressed: widget.onViewAll,
            style: TextButton.styleFrom(
              foregroundColor: mainBlue,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
            child: const Text(
              'Xem tất cả',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // MỘT DÒNG GIAO DỊCH
  Widget buildTransactionRow(TransactionModel item) {
    final isIncome = item.type == 'income';
    final color = categoryColor(item);
    final amountColor = isIncome
        ? const Color(0xFF20A444)
        : const Color(0xFFEF3349);

    return InkWell(
      onTap: () => transactionActions(item),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 11),
        child: Row(
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: color,
              child: Icon(categoryIcon(item), color: Colors.white, size: 21),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: darkText,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF88909E),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 5),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIncome ? '+' : '-'}${money(item.amount.abs())}',
                  style: TextStyle(
                    color: amountColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  formatDate(item.date),
                  style: const TextStyle(
                    color: Color(0xFF9DA5B3),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // DANH SÁCH GIAO DỊCH
  Widget buildRecentTransactions() {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.all(30),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final recent = items.take(5).toList();

    if (recent.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 14),
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
        ),
        child: const Center(child: Text('Chưa có giao dịch nào')),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFEAEFF6)),
      ),
      child: Column(
        children: [
          for (int i = 0; i < recent.length; i++) ...[
            buildTransactionRow(recent[i]),
            if (i < recent.length - 1)
              const Divider(
                height: 1,
                indent: 10,
                endIndent: 10,
                color: Color(0xFFECEFF4),
              ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            buildHeader(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: refresh,
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 95),
                  children: [
                    buildBalanceCard(),
                    buildSummary(),
                    buildRecentHeader(),
                    buildRecentTransactions(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addTransaction,
        backgroundColor: mainBlue,
        foregroundColor: Colors.white,
        elevation: 5,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 30),
      ),
    );
  }
}
