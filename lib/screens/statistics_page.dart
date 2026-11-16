import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../database/expense_database.dart';
import '../models/transaction_model.dart';
import 'ui_helpers.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});
  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  String period = 'month';
  List<TransactionModel> data = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    try {
      final items = await ExpenseDatabase.instance.getTransactions();
      if (mounted) {
        setState(() {
          data = items;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => loading = false);
        snack(context, '$e');
      }
    }
  }

  bool inPeriod(TransactionModel item) {
    final date = DateTime.tryParse(item.date);
    if (date == null) return false;
    final now = DateTime.now();
    if (period == 'previous_month') {
      final previous = DateTime(now.year, now.month - 1);
      return date.year == previous.year && date.month == previous.month;
    }
    if (period == 'year') return date.year == now.year;
    return date.year == now.year && date.month == now.month;
  }

  @override
  Widget build(BuildContext context) {
    final expenses = data.where(
      (item) => item.type == 'expense' && inPeriod(item),
    );
    final totals = <String, double>{};
    for (final item in expenses) {
      totals.update(
        item.category,
        (n) => n + item.amount,
        ifAbsent: () => item.amount,
      );
    }
    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = totals.values.fold<double>(0, (a, b) => a + b);
    final palette = [
      const Color(0xFFFF5778),
      const Color(0xFF27B8A0),
      const Color(0xFF9061F0),
      const Color(0xFF5375ED),
      const Color(0xFFE9AA39),
      const Color(0xFF86A3BB),
    ];
    return Scaffold(
      backgroundColor: canvasColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: refresh,
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              const Text(
                'Thống kê',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  color: navy,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  for (final p in [
                    ('month', 'Tháng này'),
                    ('previous_month', 'Tháng trước'),
                    ('year', 'Năm nay'),
                  ])
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 5),
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: period == p.$1
                                ? blue
                                : Colors.white,
                            foregroundColor: period == p.$1
                                ? Colors.white
                                : navy,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                          ),
                          onPressed: () => setState(() => period = p.$1),
                          child: Text(
                            p.$2,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 26),
              if (loading)
                const Center(child: CircularProgressIndicator())
              else if (total <= 0)
                const SizedBox(
                  height: 240,
                  child: Center(
                    child: Text('Chưa có chi tiêu trong khoảng thời gian này'),
                  ),
                )
              else
                Center(
                  child: SizedBox(
                    width: 220,
                    height: 220,
                    child: CustomPaint(
                      painter: DonutPainter(
                        values: sorted.map((e) => e.value).toList(),
                        colors: palette,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              money(total),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                color: navy,
                              ),
                            ),
                            const Text(
                              'Tổng chi tiêu',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              for (var i = 0; i < sorted.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 6,
                        backgroundColor: palette[i % palette.length],
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(sorted[i].key)),
                      Text(
                        money(sorted[i].value),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(sorted[i].value / total * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class DonutPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  const DonutPainter({required this.values, required this.colors});
  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (a, b) => a + b);
    if (total <= 0) return;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.shortestSide / 2 - 12,
    );
    var start = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      final sweep = values[i] / total * math.pi * 2;
      canvas.drawArc(
        rect,
        start,
        sweep,
        false,
        Paint()
          ..color = colors[i % colors.length]
          ..style = PaintingStyle.stroke
          ..strokeWidth = 25,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant DonutPainter old) => true;
}
