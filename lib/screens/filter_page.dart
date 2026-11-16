import 'package:flutter/material.dart';

import '../database/category_repository.dart';
import 'ui_helpers.dart';

class TransactionFilter {
  final String type;
  final String? category;
  final String period;
  final DateTime? fromDate;
  final DateTime? toDate;

  const TransactionFilter({
    this.type = 'all',
    this.category,
    this.period = 'all',
    this.fromDate,
    this.toDate,
  });
}

class FilterPage extends StatefulWidget {
  final TransactionFilter initial;

  const FilterPage({super.key, required this.initial});

  @override
  State<FilterPage> createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> {
  late String type;
  late String? category;
  late String period;
  DateTime? fromDate;
  DateTime? toDate;

  List<String> expenseOptions = [];
  List<String> incomeOptions = [];
  bool loadingCategories = true;
  String? categoryError;

  List<String> get availableCategories {
    final result = <String>{
      if (type != 'income') ...expenseOptions,
      if (type != 'expense') ...incomeOptions,
    }.toList();

    // Giu bo loc danh muc cu cua giao dich lich su.
    if (category != null && !result.contains(category)) {
      result.add(category!);
    }

    return result;
  }

  Future<void> loadCategories() async {
    if (mounted) {
      setState(() {
        loadingCategories = true;
        categoryError = null;
      });
    }

    try {
      final results = await Future.wait<List<String>>([
        CategoryRepository.instance.getCategories('expense'),
        CategoryRepository.instance.getCategories('income'),
      ]);

      if (!mounted) return;

      setState(() {
        expenseOptions = results[0];
        incomeOptions = results[1];
        loadingCategories = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loadingCategories = false;
        categoryError = 'Không tải được danh mục: $e';
      });
    }
  }

  void changeType(String value) {
    setState(() {
      type = value;

      final valid = <String>{
        if (type != 'income') ...expenseOptions,
        if (type != 'expense') ...incomeOptions,
      };

      if (category != null && !valid.contains(category)) {
        category = null;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    type = widget.initial.type;
    category = widget.initial.category;
    period = widget.initial.period;
    fromDate = widget.initial.fromDate;
    toDate = widget.initial.toDate;
    loadCategories();
  }

  String formatDate(DateTime? date) {
    if (date == null) return 'Chọn ngày';

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  Future<void> selectDate(bool isStart) async {
    final initial = isStart
        ? (fromDate ?? DateTime.now())
        : (toDate ?? DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked == null || !mounted) return;

    setState(() {
      if (isStart) {
        fromDate = picked;
      } else {
        toDate = picked;
      }
    });
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: navy,
        ),
      ),
    );
  }

  Widget optionChip({
    required String label,
    required String value,
    required String selected,
    required ValueChanged<String> onSelect,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected == value,
      selectedColor: const Color(0xFFDCE9FF),
      checkmarkColor: blue,
      onSelected: (_) => onSelect(value),
    );
  }

  Widget dateField(String label, DateTime? value, bool start) {
    return Expanded(
      child: InkWell(
        onTap: () => selectDate(start),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Row(
            children: [
              Expanded(child: Text(formatDate(value))),
              const Icon(Icons.calendar_month_outlined, color: blue, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void applyFilter() {
    if (period == 'custom') {
      if (fromDate == null || toDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng chọn đủ ngày bắt đầu và kết thúc'),
          ),
        );
        return;
      }

      if (fromDate!.isAfter(toDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ngày bắt đầu không được sau ngày kết thúc'),
          ),
        );
        return;
      }
    }

    Navigator.pop(
      context,
      TransactionFilter(
        type: type,
        category: category,
        period: period,
        fromDate: period == 'custom' ? fromDate : null,
        toDate: period == 'custom' ? toDate : null,
      ),
    );
  }

  void resetFilter() {
    setState(() {
      type = 'all';
      category = null;
      period = 'all';
      fromDate = null;
      toDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: canvasColor,
      appBar: AppBar(
        title: const Text(
          'Bộ lọc giao dịch',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: canvasColor,
        actions: [
          TextButton(onPressed: resetFilter, child: const Text('Đặt lại')),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            sectionTitle('Loại giao dịch'),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                optionChip(
                  label: 'Tất cả',
                  value: 'all',
                  selected: type,
                  onSelect: changeType,
                ),
                optionChip(
                  label: 'Thu nhập',
                  value: 'income',
                  selected: type,
                  onSelect: changeType,
                ),
                optionChip(
                  label: 'Chi tiêu',
                  value: 'expense',
                  selected: type,
                  onSelect: changeType,
                ),
              ],
            ),
            sectionTitle('Danh mục'),
            if (loadingCategories)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 15),
                child: Row(
                  children: [
                    SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('Đang tải danh mục...'),
                  ],
                ),
              )
            else if (categoryError != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    categoryError!,
                    style: const TextStyle(color: Colors.red),
                  ),
                  TextButton.icon(
                    onPressed: loadCategories,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử lại'),
                  ),
                ],
              )
            else
              DropdownButtonFormField<String>(
                key: ValueKey('filter_${type}_${category ?? '_all'}'),
                initialValue: category ?? '_all',
                isExpanded: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: '_all',
                    child: Text('Tất cả danh mục'),
                  ),
                  ...availableCategories.map(
                    (value) => DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    category = value == '_all' ? null : value;
                  });
                },
              ),
            sectionTitle('Khoảng thời gian'),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final option in [
                  ('all', 'Tất cả'),
                  ('today', 'Hôm nay'),
                  ('week', '7 ngày qua'),
                  ('month', 'Tháng này'),
                  ('custom', 'Tùy chỉnh'),
                ])
                  optionChip(
                    label: option.$2,
                    value: option.$1,
                    selected: period,
                    onSelect: (v) => setState(() => period = v),
                  ),
              ],
            ),
            if (period == 'custom') ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  dateField('Từ ngày', fromDate, true),
                  const SizedBox(width: 10),
                  dateField('Đến ngày', toDate, false),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Khoảng thời gian bao gồm cả ngày bắt đầu và kết thúc.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: loadingCategories || categoryError != null
                    ? null
                    : applyFilter,
                style: FilledButton.styleFrom(
                  backgroundColor: blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Áp dụng bộ lọc',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
