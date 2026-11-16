import 'package:flutter/material.dart';

import '../database/category_repository.dart';
import 'ui_helpers.dart';

class CategoryManagementPage extends StatefulWidget {
  const CategoryManagementPage({super.key});

  @override
  State<CategoryManagementPage> createState() => _CategoryManagementPageState();
}

class _CategoryManagementPageState extends State<CategoryManagementPage> {
  final repository = CategoryRepository.instance;

  String type = 'expense';
  List<String> categories = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    setState(() => loading = true);

    try {
      final result = await repository.getCategories(type);

      if (!mounted) return;

      setState(() {
        categories = result;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => loading = false);
      showMessage('Không tải được danh mục: $e');
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<String?> askName({required String title, String initial = ''}) async {
    String value = initial;

    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextFormField(
          initialValue: initial,
          autofocus: true,
          maxLength: 40,
          onChanged: (text) {
            value = text;
          },
          decoration: const InputDecoration(
            labelText: 'Tên danh mục',
            hintText: 'Ví dụ: Sức khỏe',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
            },
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext, value.trim());
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  Future<void> addCategory() async {
    final name = await askName(title: 'Thêm danh mục');

    if (name == null || !mounted) return;

    try {
      await repository.addCategory(type, name);

      if (!mounted) return;

      showMessage('Đã thêm danh mục');
      await refresh();
    } catch (e) {
      showMessage('Không thể thêm: $e');
    }
  }

  Future<void> renameCategory(String oldName) async {
    final newName = await askName(title: 'Đổi tên danh mục', initial: oldName);

    if (newName == null || !mounted) return;

    try {
      await repository.renameCategory(type, oldName, newName);

      if (!mounted) return;

      showMessage('Đã đổi tên danh mục');
      await refresh();
    } catch (e) {
      showMessage('Không thể đổi tên: $e');
    }
  }

  Future<void> deleteCategory(String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa danh mục?'),
        content: Text('Bạn có chắc muốn xóa danh mục "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await repository.deleteCategory(type, name);

      if (!mounted) return;

      showMessage('Đã xóa danh mục');
      await refresh();
    } catch (e) {
      showMessage('Không thể xóa: $e');
    }
  }

  Widget typeButton(String value, String label) {
    final selected = type == value;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            backgroundColor: selected ? blue : Colors.white,
            foregroundColor: selected ? Colors.white : navy,
          ),
          onPressed: () {
            if (type == value) return;

            setState(() => type = value);
            refresh();
          },
          child: Text(label),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: canvasColor,
      appBar: AppBar(
        title: const Text(
          'Quản lý danh mục',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: canvasColor,
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                typeButton('expense', 'Chi tiêu'),
                typeButton('income', 'Thu nhập'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: refresh,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final name = categories[index];
                        final protected = name == 'Khác';

                        return Card(
                          color: Colors.white,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: categoryColor(name)
                                  .withValues(alpha: 0.12),
                              child: Icon(
                                categoryIcon(name),
                                color: categoryColor(name),
                              ),
                            ),
                            title: Text(name),
                            subtitle: protected
                                ? const Text('Danh mục mặc định được bảo vệ')
                                : null,
                            trailing: protected
                                ? const Icon(
                                    Icons.lock_outline,
                                    color: Colors.grey,
                                  )
                                : PopupMenuButton<String>(
                                    onSelected: (action) {
                                      if (action == 'edit') {
                                        renameCategory(name);
                                      } else if (action == 'delete') {
                                        deleteCategory(name);
                                      }
                                    },
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Text('Đổi tên'),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Xóa'),
                                      ),
                                    ],
                                  ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addCategory,
        backgroundColor: blue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Thêm danh mục'),
      ),
    );
  }
}
