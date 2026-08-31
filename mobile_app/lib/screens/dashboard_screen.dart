import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/expense.dart';
import '../theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  final _api = ApiService();
  late TabController _tabController;
  final _periods = ["daily", "weekly", "monthly", "yearly"];
  final _currency = NumberFormat.currency(locale: "en_IN", symbol: "₹");

  Map<String, Future<DashboardResponse>> _futures = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _periods.length, vsync: this);
    _loadAll();
  }

  void _loadAll() {
    setState(() {
      _futures = {for (final p in _periods) p: _api.getDashboard(p)};
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.gold,
          labelColor: AppTheme.gold,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: _periods.map((p) => Tab(text: p[0].toUpperCase() + p.substring(1))).toList(),
        ),
        actions: [
          IconButton(onPressed: _loadAll, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: _periods.map((p) => _buildPeriodView(p)).toList(),
      ),
    );
  }

  Widget _buildPeriodView(String period) {
    return FutureBuilder<DashboardResponse>(
      future: _futures[period],
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.gold));
        }
        if (snap.hasError) {
          return Center(child: Text("Error: ${snap.error}", style: const TextStyle(color: AppTheme.danger)));
        }
        final data = snap.data!;
        if (data.buckets.isEmpty) {
          return const Center(child: Text("No expenses yet"));
        }
        final recent = data.buckets.length > 12
            ? data.buckets.sublist(data.buckets.length - 12)
            : data.buckets;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Total", style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 4),
                    Text(_currency.format(data.grandTotal),
                        style: Theme.of(context).textTheme.displayLarge),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 20, 16, 8),
                  child: BarChart(
                    BarChartData(
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt();
                              if (i < 0 || i >= recent.length) return const SizedBox();
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(recent[i].label,
                                    style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary)),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: [
                        for (int i = 0; i < recent.length; i++)
                          BarChartGroupData(x: i, barRods: [
                            BarChartRodData(
                              toY: recent[i].total,
                              color: AppTheme.gold,
                              width: 14,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ]),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text("By Category", style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            ..._aggregateByCategory(data).entries.map(
                  (e) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(e.key),
                      trailing: Text(_currency.format(e.value),
                          style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }

  Map<String, double> _aggregateByCategory(DashboardResponse data) {
    final map = <String, double>{};
    for (final bucket in data.buckets) {
      bucket.byCategory.forEach((cat, amt) {
        map[cat] = (map[cat] ?? 0) + amt;
      });
    }
    final sorted = Map.fromEntries(
      map.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
    return sorted;
  }
}
