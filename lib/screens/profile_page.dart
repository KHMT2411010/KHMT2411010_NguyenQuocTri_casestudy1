import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../database/expense_database.dart';
import 'category_management_page.dart';
import 'ui_helpers.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String name = 'Người dùng';
  String email = '';
  String budget = '';
  bool loading = true;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    try {
      final db = ExpenseDatabase.instance;
      final n = await db.getSetting('user_name');
      final e = await db.getSetting('user_email');
      final b = await db.getSetting('monthly_budget');

      if (!mounted) return;

      setState(() {
        name = n?.isNotEmpty == true ? n! : 'Người dùng';
        email = e ?? '';
        budget = b ?? '';
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      snack(context, 'Lỗi tải thông tin: $e');
    }
  }

  Future<void> editProfile() async {
    String newName = name == 'Người dùng' ? '' : name;
    String newEmail = email;

    final result = await showDialog<List<String>>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Thông tin cá nhân'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: newName,
              decoration: const InputDecoration(labelText: 'Họ và tên'),
              onChanged: (v) => newName = v,
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: newEmail,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
              onChanged: (v) => newEmail = v,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(c, [newName.trim(), newEmail.trim()]),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );

    if (!mounted || result == null) return;

    if (result[0].isEmpty) {
      snack(context, 'Vui lòng nhập họ tên');
      return;
    }

    try {
      await ExpenseDatabase.instance.setSetting('user_name', result[0]);
      await ExpenseDatabase.instance.setSetting('user_email', result[1]);
      await refresh();
    } catch (e) {
      if (mounted) snack(context, 'Không thể lưu: $e');
    }
  }

  Future<void> editBudget() async {
    String newValue = budget;

    final result = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Cài đặt ngân sách'),
        content: TextFormField(
          initialValue: budget,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Ngân sách tháng (đ)'),
          onChanged: (v) => newValue = v,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, newValue.trim()),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );

    if (!mounted || result == null) return;

    final amount = double.tryParse(result.replaceAll(',', '.'));

    if (amount == null || !amount.isFinite || amount < 0) {
      snack(context, 'Ngân sách không hợp lệ');
      return;
    }

    try {
      await ExpenseDatabase.instance.setSetting(
        'monthly_budget',
        amount.toStringAsFixed(0),
      );
      await refresh();
    } catch (e) {
      if (mounted) snack(context, 'Không thể lưu: $e');
    }
  }

  Future<void> openCategories() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CategoryManagementPage()),
    );
    if (mounted) await refresh();
  }

  Future<void> backupData() async {
    try {
      final db = ExpenseDatabase.instance;
      final items = await db.getTransactions();

      final data = {
        'application': 'Expense Manager',
        'version': 1,
        'exported_at': DateTime.now().toIso8601String(),
        'profile': {'name': name, 'email': email, 'monthly_budget': budget},
        'transactions': items
            .map(
              (item) => {
                'id': item.id,
                'title': item.title,
                'type': item.type,
                'amount': item.amount,
                'category': item.category,
                'date': item.date,
                'note': item.note,
              },
            )
            .toList(),
      };

      final json = const JsonEncoder.withIndent('  ').convert(data);
      await Clipboard.setData(ClipboardData(text: json));

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Sao lưu dữ liệu'),
          content: Text(
            'Đã sao chép ${items.length} giao dịch '
            'dưới dạng JSON.\n\n'
            'Bạn cần dán nội dung vào một tệp .json '
            'và lưu lại ở nơi an toàn.\n\n'
            'Chức năng khôi phục chưa được hỗ trợ.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) snack(context, 'Sao lưu thất bại: $e');
    }
  }

  void notSupported(String title) {
    showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: const Text(
          'Ứng dụng hiện sử dụng SQLite cục bộ '
          'và chưa có hệ thống đăng nhập tài khoản. '
          'Chức năng này chưa được hỗ trợ.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget menuItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool danger = false,
  }) {
    final color = danger ? const Color(0xFFE5484D) : const Color(0xFF203B62);

    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 22,
            vertical: 6,
          ),
          leading: Icon(icon, color: color, size: 23),
          title: Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right,
            size: 20,
            color: Color(0xFF9EAABC),
          ),
          onTap: onTap,
        ),
        const Divider(
          height: 1,
          indent: 20,
          endIndent: 20,
          color: Color(0xFFEDF0F5),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(22, 28, 22, 25),
                child: Text(
                  'Cá nhân',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    color: navy,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 25),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Color(0xFFA9CAFA),
                      child: Icon(Icons.person, size: 36, color: Colors.white),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loading ? 'Đang tải...' : name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: navy,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            email.isEmpty ? 'Chưa cập nhật email' : email,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF8490A1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFEDF0F5)),
              menuItem(Icons.person_outline, 'Thông tin cá nhân', editProfile),
              menuItem(
                Icons.settings_outlined,
                'Cài đặt ngân sách',
                editBudget,
              ),
              menuItem(
                Icons.category_outlined,
                'Danh mục chi tiêu',
                openCategories,
              ),
              menuItem(
                Icons.cloud_upload_outlined,
                'Sao lưu dữ liệu',
                backupData,
              ),
              menuItem(
                Icons.lock_outline,
                'Đổi mật khẩu',
                () => notSupported('Đổi mật khẩu'),
              ),
              menuItem(
                Icons.logout,
                'Đăng xuất',
                () => notSupported('Đăng xuất'),
                danger: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
