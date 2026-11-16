import 'package:flutter/material.dart';

import '../database/expense_database.dart';
import '../models/transaction_model.dart';
import 'ui_helpers.dart';
import 'filter_page.dart';

class TransactionListPage extends StatefulWidget {
  const TransactionListPage({super.key});

  @override
  State<TransactionListPage> createState() => _TransactionListPageState();
}

class _TransactionListPageState extends State<TransactionListPage> {
  static const Color mainBlue = Color(0xFF1769EB);
  static const Color background = Color(0xFFF6F8FD);
  static const Color darkText = Color(0xFF172033);

  List<TransactionModel> items = [];
  bool loading = true;

  String search = '';
  TransactionFilter extra = const TransactionFilter();

  @override
  void initState() {
    super.initState();
    refresh();
  }

  // ĐỌC GIAO DỊCH TỪ SQLITE
  Future<void> refresh() async {
    try {
      final result = await ExpenseDatabase.instance.getTransactions();

      if (!mounted) return;

      setState(() {
        items = result;
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

  // ĐỊNH DẠNG NGÀY
  String formatDate(String value) {
    final date = DateTime.tryParse(value);

    if (date == null) return value;

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  // KIỂM TRA KHOẢNG THỜI GIAN
  bool inPeriod(TransactionModel item) {
    if (extra.period == 'all') {
      return true;
    }

    final date = DateTime.tryParse(item.date);
    if (date == null) {
      return false;
    }

    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final transactionDay = DateTime(date.year, date.month, date.day);

    switch (extra.period) {
      case 'today':
        return transactionDay == today;

      case 'week':
        final start = today.subtract(const Duration(days: 6));

        return !transactionDay.isBefore(start) &&
            !transactionDay.isAfter(today);

      case 'month':
        return date.year == now.year && date.month == now.month;

      case 'custom':
        final from = extra.fromDate;
        final to = extra.toDate;

        if (from == null || to == null) {
          return false;
        }

        final start = DateTime(from.year, from.month, from.day);

        final end = DateTime(to.year, to.month, to.day);

        return !transactionDay.isBefore(start) && !transactionDay.isAfter(end);

      default:
        return true;
    }
  }

  // TÌM KIẾM VÀ LỌC GIAO DỊCH
  List<TransactionModel> get visible {
    final keyword = search.toLowerCase().trim();

    return items.where((item) {
      final matchType = extra.type == 'all' || extra.type == item.type;

      final matchCategory =
          extra.category == null || extra.category == item.category;

      final matchSearch =
          keyword.isEmpty ||
          item.title.toLowerCase().contains(keyword) ||
          item.category.toLowerCase().contains(keyword) ||
          item.note.toLowerCase().contains(keyword);

      return matchType &&
          matchCategory &&
          inPeriod(item) &&
          matchSearch;
    }).toList();
  }

  // CHỌN ICON THEO DANH MỤC
  IconData categoryIcon(TransactionModel item) {
    final value = '${item.category} ${item.title}'.toLowerCase();

    if (value.contains('ăn') ||
        value.contains('uống') ||
        value.contains('cơm')) {
      return Icons.restaurant;
    }

    if (value.contains('xăng') ||
        value.contains('xe') ||
        value.contains('di chuyển')) {
      return Icons.directions_car;
    }

    if (value.contains('lương') || value.contains('thu nhập')) {
      return Icons.attach_money;
    }

    if (value.contains('mua') || value.contains('sắm')) {
      return Icons.shopping_cart;
    }

    if (value.contains('học') || value.contains('giáo dục')) {
      return Icons.school;
    }

    if (value.contains('giải trí')) {
      return Icons.sports_esports;
    }

    if (item.type == 'income') {
      return Icons.attach_money;
    }

    return Icons.receipt_long;
  }

  // MÀU ICON THEO DANH MỤC
  Color categoryColor(TransactionModel item) {
    final value = '${item.category} ${item.title}'.toLowerCase();

    if (value.contains('ăn') ||
        value.contains('uống') ||
        value.contains('cơm')) {
      return const Color(0xFFFF6537);
    }

    if (value.contains('xăng') ||
        value.contains('xe') ||
        value.contains('di chuyển')) {
      return const Color(0xFF1DB5EA);
    }

    if (value.contains('mua') || value.contains('sắm')) {
      return const Color(0xFFA844EE);
    }

    if (value.contains('học') || value.contains('giáo dục')) {
      return const Color(0xFF9965EA);
    }

    if (item.type == 'income') {
      return const Color(0xFF23B45A);
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
  Future<void> showActions(TransactionModel item) async {
    final selected = await showModalBottomSheet<String>(
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
                subtitle: Text(
                  item.note.isNotEmpty ? item.note : item.category,
                ),
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

    if (selected == 'edit') {
      final updated = await editTransaction(context, existing: item);

      if (!mounted) return;

      if (updated) {
        await refresh();
      }
    } else if (selected == 'delete') {
      final deleted = await removeTransaction(context, item);

      if (!mounted) return;

      if (deleted) {
        await refresh();
      }
    }
  }

  // NÚT LỌC TẤT CẢ / THU NHẬP / CHI TIÊU
  Widget filterTab(String label, String value) {
    final active = extra.type == value;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: OutlinedButton(
          onPressed: () {
            setState(() {
              extra = TransactionFilter(
                type: value,
                period: extra.period,
                fromDate: extra.fromDate,
                toDate: extra.toDate,
                category: value == extra.type ? extra.category : null,
              );
            });
          },
          style: OutlinedButton.styleFrom(
            backgroundColor: active ? mainBlue : Colors.white,
            foregroundColor: active ? Colors.white : darkText,
            side: BorderSide(
              color: active ? mainBlue : const Color(0xFFE5EAF2),
            ),
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  // THANH TÌM KIẾM VÀ NÚT BỘ LỌC
  Widget buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (value) {
                setState(() {
                  search = value;
                });
              },
              style: const TextStyle(fontSize: 13, color: darkText),
              decoration: InputDecoration(
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(0xFF566278),
                  size: 20,
                ),
                hintText: 'Tìm kiếm giao dịch...',
                hintStyle: const TextStyle(
                  color: Color(0xFF8C95A5),
                  fontSize: 12,
                ),
                filled: true,
                fillColor: const Color(0xFFEEF2F8),
                contentPadding: const EdgeInsets.symmetric(vertical: 13),
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 9),
          IconButton.filledTonal(
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFE4EAFE),
              foregroundColor: darkText,
            ),
            tooltip: 'Bộ lọc giao dịch',
            icon: const Icon(Icons.filter_alt_outlined, size: 22),
            onPressed: () async {
              final selected = await Navigator.push<TransactionFilter>(
                context,
                MaterialPageRoute(builder: (_) => FilterPage(initial: extra)),
              );

              if (!mounted) return;

              if (selected != null) {
                setState(() {
                  extra = selected;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  // HIỂN THỊ MỘT GIAO DỊCH
  Widget buildTransactionTile(TransactionModel item) {
    final isIncome = item.type == 'income';

    final amountColor = isIncome
        ? const Color(0xFF1CAA49)
        : const Color(0xFFF23D4E);

    final iconColor = categoryColor(item);

    return InkWell(
      onTap: () => showActions(item),
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        child: Row(
          children: [
            // ICON DANH MỤC
            CircleAvatar(
              radius: 20,
              backgroundColor: iconColor,
              child: Icon(categoryIcon(item), color: Colors.white, size: 21),
            ),

            const SizedBox(width: 12),

            // TÊN VÀ DANH MỤC
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: darkText,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF929AAB),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 5),

            // NGÀY VÀ SỐ TIỀN
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIncome ? '+' : '-'}${money(item.amount.abs())}',
                  style: TextStyle(
                    fontSize: 12,
                    color: amountColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  formatDate(item.date),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF9BA4B3),
                  ),
                ),
              ],
            ),

            const SizedBox(width: 5),
            const Icon(Icons.chevron_right, color: Color(0xFFB3BAC7), size: 17),
          ],
        ),
      ),
    );
  }

  // DANH SÁCH GIAO DỊCH
  Widget buildTransactionList() {
    final rows = visible;

    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (rows.isEmpty) {
      return RefreshIndicator(
        onRefresh: refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 90),
            Icon(
              Icons.receipt_long_outlined,
              color: Color(0xFF9CA8BB),
              size: 48,
            ),
            SizedBox(height: 12),
            Center(
              child: Text(
                'Chưa có giao dịch phù hợp',
                style: TextStyle(color: Color(0xFF7E899B)),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: refresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 100),
        itemCount: rows.length,
        itemBuilder: (context, index) {
          final item = rows[index];

          return Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(index == 0 ? 12 : 0),
                  bottom: Radius.circular(index == rows.length - 1 ? 12 : 0),
                ),
                child: buildTransactionTile(item),
              ),
              if (index < rows.length - 1)
                const Divider(
                  height: 1,
                  thickness: 1,
                  indent: 1,
                  endIndent: 1,
                  color: Color(0xFFE8ECF3),
                ),
            ],
          );
        },
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
            // TIÊU ĐỀ
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 23, 18, 18),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Giao dịch',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: darkText,
                  ),
                ),
              ),
            ),

            // TÌM KIẾM
            buildSearchBar(),

            const SizedBox(height: 12),

            // BA NÚT LỌC
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 11),
              child: Row(
                children: [
                  filterTab('Tất cả', 'all'),
                  filterTab('Thu nhập', 'income'),
                  filterTab('Chi tiêu', 'expense'),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // DANH SÁCH SQLITE
            Expanded(child: buildTransactionList()),
          ],
        ),
      ),

      // NÚT THÊM GIAO DỊCH
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
