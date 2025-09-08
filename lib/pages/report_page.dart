import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aplikasi_kasir_seafood/providers/report_provider.dart';
import 'package:aplikasi_kasir_seafood/widgets/custom_app_bar.dart';
import 'package:aplikasi_kasir_seafood/widgets/custom_drawer.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  String _selectedDateFilter = 'Today';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReportsByDateFilter('Today');
    });
  }

  Future<void> _loadReportsByDateFilter(String filter) async {
    DateTime now = DateTime.now();
    DateTime? startDate;
    DateTime? endDate;

    setState(() {
      _selectedDateFilter = filter;
    });

    switch (filter) {
      case 'Today':
        startDate = DateTime(now.year, now.month, now.day);
        endDate = startDate.add(const Duration(days: 1));
        break;
      case 'Yesterday':
        startDate = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 1));
        endDate = startDate.add(const Duration(days: 1));
        break;
      case 'This Week':
        int weekday = now.weekday;
        startDate = now.subtract(Duration(days: weekday - 1));
        endDate = startDate.add(const Duration(days: 7));
        break;
      case 'This Month':
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 1);
        break;
    }

    if (startDate != null && endDate != null) {
      await Provider.of<ReportProvider>(
        context,
        listen: false,
      ).loadReportsByRange(startDate, endDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Laporan Keuangan'),
      drawer: const CustomDrawer(currentPage: 'Laporan'),
      body: Consumer<ReportProvider>(
        builder: (context, reportProvider, child) {
          if (reportProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Metric cards dalam 2 kolom
          final metrics = [
            {
              'title': 'Jml Transaksi',
              'value': reportProvider.totalOrders,
              'color': Colors.green.shade800,
              'icon': Icons.receipt_long,
            },
            {
              'title': 'Keuntungan',
              'value': reportProvider.netProfit,
              'color': Colors.blue.shade800,
              'icon': Icons.trending_up,
            },
            {
              'title': 'Pendapatan',
              'value': reportProvider.totalRevenue,
              'color': Colors.green,
              'icon': Icons.monetization_on,
            },
            {
              'title': 'Pengeluaran',
              'value': reportProvider.totalExpenses,
              'color': Colors.red.shade800,
              'icon': Icons.money_off,
            },
          ];

          return RefreshIndicator(
            onRefresh: () => _loadReportsByDateFilter(_selectedDateFilter),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Filter Tanggal
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Ringkasan Laporan Penjualan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      DropdownButton<String>(
                        value: _selectedDateFilter,
                        items: const [
                          DropdownMenuItem(
                            value: 'Today',
                            child: Text('Hari Ini'),
                          ),
                          DropdownMenuItem(
                            value: 'Yesterday',
                            child: Text('Kemarin'),
                          ),
                          DropdownMenuItem(
                            value: 'This Week',
                            child: Text('Mingguan'),
                          ),
                          DropdownMenuItem(
                            value: 'This Month',
                            child: Text('Bulanan'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            _loadReportsByDateFilter(value);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Grid Metric Cards 2 kolom
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.5,
                        ),
                    itemCount: metrics.length,
                    itemBuilder: (context, index) {
                      final metric = metrics[index];
                      return _buildMetricCard(
                        context,
                        title: metric['title'] as String,
                        value: metric['value'] as num,
                        color: metric['color'] as Color,
                        icon: metric['icon'] as IconData,
                      );
                    },
                  ),

                  const SizedBox(height: 24),
                  const Text(
                    'Laporan Transaksi per jam',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  _buildChartCard(context, reportProvider.hourlyData),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required num value,
    required Color color,
    required IconData icon,
  }) {
    final formatter = NumberFormat('#,###', 'id_ID');
    final formattedValue = value is int
        ? value.toString()
        : 'Rp ${formatter.format(value)}';

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 24, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            formattedValue,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(
    BuildContext context,
    List<Map<String, dynamic>> hourlyData,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Grafik Pendapatan per Jam',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: 24,
                  minY: 0,
                  maxY: hourlyData.isNotEmpty
                      ? hourlyData
                                .map((e) => e['value'] as double)
                                .reduce((a, b) => a > b ? a : b) *
                            1.2
                      : 100,
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(value.toInt().toString());
                        },
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: 200000,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.2),
                        strokeWidth: 1,
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.2),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: hourlyData
                          .map(
                            (e) => FlSpot(
                              e['hour'] as double,
                              e['value'] as double,
                            ),
                          )
                          .toList(),
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.green.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
