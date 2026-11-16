import 'package:flutter/material.dart';

import '../database/category_repository.dart';
import '../models/transaction_model.dart';
import 'ui_helpers.dart';

class TransactionFormPage extends StatefulWidget {
  final TransactionModel? transaction;

  const TransactionFormPage({super.key, this.transaction});

  @override
  State<TransactionFormPage> createState() => _TransactionFormPageState();
}

class _TransactionFormPageState extends State<TransactionFormPage> {
  final _form = GlobalKey<FormState>();

  late final TextEditingController _amount;
  late final TextEditingController _note;

  late String _type;
  late String _category;
  late DateTime _date;

  List<String> _categories = [];
  bool _loadingCategories = true;
  String? _categoryError;
  int _loadVersion = 0;

  @override
  void initState() {
    super.initState();

    final item = widget.transaction;

    _type = item?.type ?? 'expense';
    _category = item?.category ?? '';

    _date = DateTime.tryParse(item?.date ?? '') ?? DateTime.now();

    _amount = TextEditingController(
      text: item == null ? '' : item.amount.toString().replaceFirst(RegExp(r'\.0$'), ''),
    );

    _note = TextEditingController(text: item?.note ?? '');

    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final version = ++_loadVersion;
    final requestedType = _type;

    setState(() {
      _loadingCategories = true;
      _categoryError = null;
    });

    try {
      final values = await CategoryRepository.instance.getCategories(
        requestedType,
      );

      if (!mounted || version != _loadVersion) return;

      final updated = List<String>.from(values);

      // Khi sua giao dich, van cho phep hien thi danh muc cu
      // neu danh muc khong con nam trong danh sach hien tai.
      final original = widget.transaction;

      if (original != null &&
          original.type == requestedType &&
          original.category.isNotEmpty &&
          !updated.contains(original.category)) {
        updated.add(original.category);
      }

      if (updated.isEmpty) {
        setState(() {
          _categories = [];
          _category = '';
          _loadingCategories = false;
          _categoryError = 'Chưa có danh mục để lựa chọn';
        });
        return;
      }

      final selected = updated.contains(_category) ? _category : updated.first;

      setState(() {
        _categories = updated;
        _category = selected;
        _loadingCategories = false;
      });
    } catch (e) {
      if (!mounted || version != _loadVersion) return;

      setState(() {
        _categories = [];
        _category = '';
        _loadingCategories = false;
        _categoryError = 'Không tải được danh mục: $e';
      });
    }
  }

  void _changeType(String type) {
    if (type == _type) return;

    setState(() {
      _type = type;
      _category = '';
      _categories = [];
      _loadingCategories = true;
      _categoryError = null;
    });

    _loadCategories();
  }

  @override
  void dispose() {
    _loadVersion++;
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _save() {
    if (_loadingCategories || _categoryError != null) {
      snack(context, 'Vui lòng kiểm tra danh mục trước khi lưu');
      return;
    }

    if (_category.isEmpty || !_categories.contains(_category)) {
      snack(context, 'Vui lòng chọn danh mục');
      return;
    }

    if (!_form.currentState!.validate()) return;

    final amount = double.parse(_amount.text.trim().replaceAll(',', '.'));

    final note = _note.text.trim();

    Navigator.pop(
      context,
      TransactionModel(
        id: widget.transaction?.id,
        title: note.isEmpty ? _category : note,
        amount: amount,
        type: _type,
        date: _date.toIso8601String(),
        category: _category,
        note: note,
      ),
    );
  }

  InputDecoration decoration({String? hint, IconData? suffix}) {
    return InputDecoration(
      hintText: hint,
      suffixIcon: suffix == null ? null : Icon(suffix, size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDFE5EE)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }

  Widget label(String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        value,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: navy,
        ),
      ),
    );
  }

  Widget categoryField() {
    if (_loadingCategories) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Đang tải danh mục...'),
          ],
        ),
      );
    }

    if (_categoryError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_categoryError!, style: const TextStyle(color: Colors.red)),
          TextButton.icon(
            onPressed: _loadCategories,
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
          ),
        ],
      );
    }

    return DropdownButtonFormField<String>(
      key: ValueKey('category_$_type'),
      initialValue: _category,
      isExpanded: true,
      decoration: decoration(),
      items: _categories
          .map(
            (value) => DropdownMenuItem<String>(
              value: value,
              child: Text(value, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _category = value);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final edit = widget.transaction != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          edit ? 'Sửa giao dịch' : 'Thêm giao dịch',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  for (final option in ['expense', 'income'])
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: OutlinedButton(
                          onPressed: () => _changeType(option),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _type == option
                                ? Colors.white
                                : navy,
                            backgroundColor: _type == option
                                ? (option == 'expense'
                                      ? const Color(0xFFFF5E6C)
                                      : blue)
                                : Colors.white,
                            side: BorderSide(
                              color: _type == option
                                  ? Colors.transparent
                                  : const Color(0xFFE1E6F0),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            option == 'expense' ? 'Chi tiêu' : 'Thu nhập',
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 23),
              label('Danh mục'),
              categoryField(),
              const SizedBox(height: 20),
              label('Số tiền'),
              TextFormField(
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: decoration(hint: 'Nhập số tiền')
                    .copyWith(suffixText: 'đ'),
                validator: (value) {
                  final number = double.tryParse(
                    (value ?? '').trim().replaceAll(',', '.'),
                  );

                  if (number == null || !number.isFinite || number <= 0) {
                    return 'Nhập số tiền hợp lệ (ví dụ: 100000)';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 20),
              label('Ngày giao dịch'),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: _date.isBefore(DateTime(2000)) ? _date : DateTime(2000),
                    lastDate: _date.isAfter(DateTime(2100)) ? _date : DateTime(2100),
                  );

                  if (date != null && mounted) {
                    setState(() => _date = date);
                  }
                },
                child: InputDecorator(
                  decoration: decoration(suffix: Icons.calendar_month),
                  child: Text(displayDate(_date.toIso8601String())),
                ),
              ),
              const SizedBox(height: 20),
              label('Ghi chú'),
              TextFormField(
                controller: _note,
                maxLines: 3,
                decoration: decoration(hint: 'Nhập ghi chú (tùy chọn)'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: FilledButton(
                  onPressed: _loadingCategories || _categoryError != null
                      ? null
                      : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Lưu',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
