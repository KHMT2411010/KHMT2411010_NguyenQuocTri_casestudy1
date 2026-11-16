import 'package:flutter_test/flutter_test.dart';
import 'package:khmt2411010_nguyenquoctri_casestudy1/main.dart';

void main() {
  testWidgets('Hiển thị màn hình chào KHMT', (tester) async {
    await tester.pumpWidget(const ExpenseManagerApp());

    expect(find.text('Expense Manager'), findsOneWidget);
    expect(find.text('Bắt đầu'), findsOneWidget);
  });
}