import 'package:flutter/material.dart';

import 'expense_page.dart';
import 'transaction_list_page.dart';
import 'statistics_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selected = 0;
  int refreshVersion = 0;

  void changeTab(int index) {
    setState(() {
      selected = index;
      refreshVersion++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: selected,
        children: [
          ExpensePage(
            key: ValueKey('dashboard_$refreshVersion'),
            onViewAll: () => changeTab(1),
          ),
          TransactionListPage(
            key: ValueKey('transactions_$refreshVersion'),
          ),
          StatisticsPage(
            key: ValueKey('statistics_$refreshVersion'),
          ),
          ProfilePage(
            key: ValueKey('profile_$refreshVersion'),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected,
        height: 70,
        backgroundColor: const Color(0xFFF8F7FC),
        indicatorColor: const Color(0xFFDDE8FF),
        onDestinationSelected: changeTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: Color(0xFF1769EB)),
            label: 'Tổng quan',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long, color: Color(0xFF1769EB)),
            label: 'Giao dịch',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart, color: Color(0xFF1769EB)),
            label: 'Thống kê',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Color(0xFF1769EB)),
            label: 'Cá nhân',
          ),
        ],
      ),
    );
  }
}
