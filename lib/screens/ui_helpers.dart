import 'package:flutter/material.dart';
import '../database/expense_database.dart';
import '../models/transaction_model.dart';
import 'transaction_form_page.dart';

const navy = Color(0xFF15233B);
const blue = Color(0xFF1769E8);
const canvasColor = Color(0xFFF6F8FD);

const expenseCategories = ['Ăn uống', 'Mua sắm', 'Đi lại', 'Học tập', 'Giải trí', 'Hóa đơn', 'Khác'];
const incomeCategories = ['Lương', 'Thưởng', 'Kinh doanh', 'Thu nhập khác', 'Khác'];

String money(double amount) {
  final whole = amount.round().abs().toString();
  final formatted = whole.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
  return '${amount < 0 ? '-' : ''}$formatted đ';
}

String displayDate(String value) {
  final date = DateTime.tryParse(value);
  if (date == null) return value;
  String pad(int n) => n.toString().padLeft(2, '0');
  return '${pad(date.day)}/${pad(date.month)}/${date.year}';
}

Color categoryColor(String name) {
  switch (name) {
    case 'Ăn uống': return const Color(0xFFF75D70);
    case 'Mua sắm': return const Color(0xFF14B4E5);
    case 'Lương': return const Color(0xFF20BC71);
    case 'Đi lại': return const Color(0xFF9063EA);
    case 'Học tập': return const Color(0xFF8973ED);
    case 'Giải trí': return const Color(0xFFF19B40);
    default: return const Color(0xFF6283B9);
  }
}

IconData categoryIcon(String name) {
  switch (name) {
    case 'Ăn uống': return Icons.restaurant;
    case 'Mua sắm': return Icons.shopping_cart;
    case 'Lương': return Icons.payments;
    case 'Đi lại': return Icons.directions_car;
    case 'Học tập': return Icons.menu_book;
    case 'Giải trí': return Icons.sports_esports;
    default: return Icons.wallet;
  }
}

void snack(BuildContext context, String message) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

Future<bool> editTransaction(BuildContext context, {TransactionModel? existing}) async {
  final edited = await Navigator.of(context).push<TransactionModel>(
    MaterialPageRoute(builder: (_) => TransactionFormPage(transaction: existing)),
  );
  if (edited == null) return false;
  try {
    if (existing == null) {
      await ExpenseDatabase.instance.insertTransaction(edited);
    } else {
      await ExpenseDatabase.instance.updateTransaction(edited);
    }
    if (context.mounted) snack(context, 'Đã lưu giao dịch');
    return true;
  } catch (e) {
    if (context.mounted) snack(context, 'Không thể lưu: $e');
    return false;
  }
}

Future<bool> removeTransaction(BuildContext context, TransactionModel item) async {
  if (item.id == null) return false;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: const Text('Xóa giao dịch?'),
      content: Text('Bạn muốn xóa "${item.title}"?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Hủy')),
        TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Xóa')),
      ],
    ),
  );
  if (confirmed != true) return false;
  try {
    await ExpenseDatabase.instance.deleteTransaction(item.id!);
    if (context.mounted) snack(context, 'Đã xóa giao dịch');
    return true;
  } catch (e) {
    if (context.mounted) snack(context, 'Không thể xóa: $e');
    return false;
  }
}

class TransactionTile extends StatelessWidget {
  final TransactionModel item;
  final VoidCallback? onTap;
  const TransactionTile({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final incoming = item.type == 'income';
    final category = item.category == 'Khác' ? item.title : item.category;
    final color = categoryColor(category);
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: .15),
        child: Icon(categoryIcon(category), color: color, size: 20),
      ),
      title: Text(category, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(displayDate(item.date), style: const TextStyle(color: Colors.grey, fontSize: 11)),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        Text('${incoming ? '+' : '-'}${money(item.amount)}', style: TextStyle(color: incoming ? Colors.green : const Color(0xFFF45162), fontSize: 12, fontWeight: FontWeight.bold)),
        const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
      ]),
    );
  }
}
