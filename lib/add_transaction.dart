
import 'package:flutter/material.dart';
import 'main.dart';
import 'database_helper.dart';

class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({super.key});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  bool isExpense = true;
  String selectedCategory = 'Ăn uống';
  DateTime selectedDate = DateTime.now();

  final amountController = TextEditingController();
  final noteController = TextEditingController();

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


  Future<void> save() async {
    final amount = double.tryParse(
      amountController.text
          .replaceAll('.', '')
          .replaceAll(',', '')
          .trim(),
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
      title: 'Thêm giao dịch',
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

class TransactionForm extends StatelessWidget {
  final String title;
  final bool isExpense;
  final String selectedCategory;
  final List<String> categories;
  final DateTime selectedDate;
  final TextEditingController amountController;
  final TextEditingController noteController;
  final VoidCallback onExpense;
  final VoidCallback onIncome;
  final ValueChanged<String?> onCategoryChanged;
  final VoidCallback onDate;
  final VoidCallback onSave;

  const TransactionForm({
    required this.title,
    required this.isExpense,
    required this.selectedCategory,
    required this.categories,
    required this.selectedDate,
    required this.amountController,
    required this.noteController,
    required this.onExpense,
    required this.onIncome,
    required this.onCategoryChanged,
    required this.onDate,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new, size: 19),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 2, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _typeButton(
                      'Chi tiêu',
                      isExpense,
                      onExpense,
                    ),
                  ),
                  Expanded(
                    child: _typeButton(
                      'Thu nhập',
                      !isExpense,
                      onIncome,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _label('Danh mục'),
              const SizedBox(height: 8),
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: _boxDecoration(),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedCategory,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down),
                    items: categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: isExpense
                                    ? const Color(0xFFFFE8EA)
                                    : const Color(0xFFE8F8F1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                isExpense
                                    ? Icons.restaurant
                                    : Icons.payments,
                                color: isExpense
                                    ? const Color(0xFFFF626B)
                                    : const Color(0xFF19A974),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(category),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: onCategoryChanged,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              _label('Số tiền'),
              const SizedBox(height: 8),
              Container(
                height: 48,
                decoration: _boxDecoration(),
                child: TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Nhập số tiền',
                    suffixText: 'đ',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              _label('Ngày giao dịch'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: onDate,
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 13),
                  decoration: _boxDecoration(),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(formatDate(selectedDate)),
                      ),
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 18,
                        color: Color(0xFF718096),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              _label('Ghi chú'),
              const SizedBox(height: 8),
              Container(
                height: 90,
                decoration: _boxDecoration(),
                child: TextField(
                  controller: noteController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Nhập ghi chú (tùy chọn)',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(13),
                  ),
                ),
              ),
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2176C9),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  child: const Text(
                    'Lưu',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: Color(0xFF273444),
    ),
  );

  Widget _typeButton(
      String text,
      bool selected,
      VoidCallback onTap,
      ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFF626B) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? const Color(0xFFFF626B)
                : const Color(0xFFD7DDE5),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF344054),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      border: Border.all(color: const Color(0xFFD7DDE5)),
      borderRadius: BorderRadius.circular(9),
    );
  }
}
