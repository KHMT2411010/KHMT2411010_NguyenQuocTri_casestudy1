
import 'package:flutter/material.dart';
import 'main.dart';
import 'add_transaction.dart';

class EditTransactionPage extends StatefulWidget {
  final TransactionData transaction;

  const EditTransactionPage({
    super.key,
    required this.transaction,
  });

  @override
  State<EditTransactionPage> createState() => _EditTransactionPageState();
}

class _EditTransactionPageState extends State<EditTransactionPage> {
  late bool isExpense;
  late String selectedCategory;
  late DateTime selectedDate;
  late TextEditingController amountController;
  late TextEditingController noteController;

  final expenseCategories = const [
    'Ăn uống',
    'Mua sắm',
    'Di chuyển',
    'Giải trí',
    'Hóa đơn',
    'Sức khỏe',
    'Giáo dục',
    'Khác',
  ];

  final incomeCategories = const [
    'Thu nhập',
    'Lương',
    'Thưởng',
    'Tiền làm thêm',
    'Đầu tư',
    'Khác',
  ];

  @override
  void initState() {
    super.initState();

    isExpense = widget.transaction.type == TransactionType.expense;
    selectedCategory = widget.transaction.category;
    selectedDate = widget.transaction.date;

    amountController = TextEditingController(
      text: formatMoney(widget.transaction.amount),
    );
    noteController = TextEditingController(
      text: widget.transaction.note,
    );
  }

  List<String> get categories =>
      isExpense ? expenseCategories : incomeCategories;

  @override
  void dispose() {
    amountController.dispose();
    noteController.dispose();
    super.dispose();
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  void save() {
    final amount = double.tryParse(
      amountController.text
          .replaceAll('.', '')
          .replaceAll(',', ''),
    ) ??
        0;

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập số tiền hợp lệ'),
        ),
      );
      return;
    }

    Navigator.pop(
      context,
      TransactionData(
        id: widget.transaction.id,
        type: isExpense
            ? TransactionType.expense
            : TransactionType.income,
        category: selectedCategory,
        amount: amount,
        date: selectedDate,
        note: noteController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TransactionForm(
      title: 'Sửa giao dịch',
      isExpense: isExpense,
      selectedCategory: selectedCategory,
      categories: categories,
      selectedDate: selectedDate,
      amountController: amountController,
      noteController: noteController,
      onExpense: () {
        setState(() {
          isExpense = true;
          if (!categories.contains(selectedCategory)) {
            selectedCategory = categories.first;
          }
        });
      },
      onIncome: () {
        setState(() {
          isExpense = false;
          if (!categories.contains(selectedCategory)) {
            selectedCategory = categories.first;
          }
        });
      },
      onCategoryChanged: (v) {
        if (v != null) setState(() => selectedCategory = v);
      },
      onDate: pickDate,
      onSave: save,
    );
  }
}
