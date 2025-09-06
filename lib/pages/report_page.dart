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
    // Muat laporan untuk hari ini saat halaman pertama kali dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ReportProvider>(context, listen: false).loadReports(DateTime.now());
    });
  }

  // Metode untuk memuat ulang laporan berdasarkan filter tanggal
  Future<void> _loadReportsByDateFilter(String filter) async {
    DateTime? dateToLoad;
    setState(() {
      _selectedDateFilter = filter;
    });

    switch (filter) {
      case 'Today':
        dateToLoad = DateTime.now();
        break;
      case 'Yesterday':
        dateToLoad = DateTime.now().subtract(const Duration(days: 1));
        break;
      case 'Last 7 Days':
        dateToLoad = DateTime.now().subtract(const Duration(days: 7));
        break;
    }

    if (dateToLoad != null) {
      await Provider.of<ReportProvider>(context, listen: false).loadReports(dateToLoad);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Laporan Keuangan'),
      drawer: const CustomDrawer(),
      body: Consumer<ReportProvider>(
        builder: (context, reportProvider, child) {
          if (reportProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () => _loadReportsByDateFilter(_selectedDateFilter),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Bagian Filter Tanggal
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
                            child: Text('Today'),
                          ),
                          DropdownMenuItem(
                            value: 'Yesterday',
                            child: Text('Yesterday'),
                          ),
                          DropdownMenuItem(
                            value: 'Last 7 Days',
                            child: Text('Last 7 Days'),
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
  
                  // Bagian Kartu Metrik
                  _buildMetricCard(
                    context,
                    title: 'Jml Transaksi',
                    value: reportProvider.totalOrders,
                    color: Colors.green.shade800,
                    icon: Icons.receipt_long,
                  ),
                  const SizedBox(height: 12),
                  _buildMetricCard(
                    context,
                    title: 'Keuntungan',
                    value: reportProvider.netProfit,
                    color: Colors.blue.shade800,
                    icon: Icons.trending_up,
                  ),
                  const SizedBox(height: 12),
                  _buildMetricCard(
                    context,
                    title: 'Pendapatan',
                    value: reportProvider.totalRevenue,
                    color: Colors.green,
                    icon: Icons.monetization_on,
                  ),
  
                  const SizedBox(height: 24),
                  const Text(
                    'Laporan Transaksi per jam',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _buildChartCard(context, reportProvider.hourlyData),
  
                  const SizedBox(height: 24),
                  _buildMetricCard(
                    context,
                    title: 'Sisa modal - Metode FIFO',
                    value: 0.0, // Ganti dengan data sisa modal yang sebenarnya
                    color: Colors.grey.shade600,
                    icon: Icons.inventory_2,
                  ),
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
      padding: const EdgeInsets.all(24.0),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    size: 24,
                    color: color,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
              const Text(
                '+0% vs kemarin',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            formattedValue,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildChartCard(BuildContext context, List<Map<String, dynamic>> hourlyData) {
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
                      ? hourlyData.map((e) => e['value'] as double).reduce((a, b) => a > b ? a : b) * 1.2
                      : 100,
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) {
                        return Text(value.toInt().toString());
                      }),
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
                    border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: hourlyData
                          .map((e) => FlSpot(e['hour'] as double, e['value'] as double))
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
