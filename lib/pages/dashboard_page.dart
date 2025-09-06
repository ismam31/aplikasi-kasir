import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aplikasi_kasir_seafood/providers/report_provider.dart';
import 'package:aplikasi_kasir_seafood/providers/order_list_provider.dart';
import 'package:aplikasi_kasir_seafood/widgets/custom_app_bar.dart';
import 'package:aplikasi_kasir_seafood/widgets/custom_drawer.dart';
import 'package:intl/intl.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshDashboard(context);
    });
  }

  Future<void> _refreshDashboard(BuildContext context) async {
    final orderProvider = Provider.of<OrderListProvider>(
      context,
      listen: false,
    );
    final reportProvider = Provider.of<ReportProvider>(
      context,
      listen: false,
    );

    await Future.wait([
      orderProvider.loadOrders(),
      reportProvider.loadReports(DateTime.now()),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Dashboard Kasir'),
      drawer: const CustomDrawer(),
      body: Consumer<ReportProvider>(
        builder: (context, reportProvider, child) {
          if (reportProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final formatter = NumberFormat('#,###', 'id_ID');
          String formatCurrency(double amount) {
            return formatter.format(amount);
          }

          return RefreshIndicator(
            onRefresh: () => _refreshDashboard(context),
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: <Widget>[
                _buildMetricCard(
                  context,
                  title: 'Total Pendapatan',
                  value: formatCurrency(reportProvider.totalRevenue),
                  color: Colors.green,
                ),
                const SizedBox(height: 16),
                _buildMetricCard(
                  context,
                  title: 'Total Pengeluaran',
                  value: formatCurrency(reportProvider.totalExpenses),
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                _buildMetricCard(
                  context,
                  title: 'Keuntungan Bersih',
                  value: formatCurrency(reportProvider.netProfit),
                  color: Colors.blue,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: color.withOpacity(0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Rp ',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w400,
                    color: color,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
