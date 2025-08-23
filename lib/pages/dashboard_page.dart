import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aplikasi_kasir_seafood/providers/report_provider.dart';
import 'package:aplikasi_kasir_seafood/widgets/custom_app_bar.dart';
import 'package:aplikasi_kasir_seafood/widgets/custom_drawer.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Card untuk Pendapatan
                _buildMetricCard(
                  context,
                  title: 'Total Pendapatan',
                  value: 'Rp ${reportProvider.totalRevenue.toStringAsFixed(0)}',
                  color: Colors.green,
                ),
                const SizedBox(height: 16),
                // Card untuk Pengeluaran
                _buildMetricCard(
                  context,
                  title: 'Total Pengeluaran',
                  value: 'Rp ${reportProvider.totalExpenses.toStringAsFixed(0)}',
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                // Card untuk Keuntungan Bersih
                _buildMetricCard(
                  context,
                  title: 'Keuntungan Bersih',
                  value: 'Rp ${reportProvider.netProfit.toStringAsFixed(0)}',
                  color: Colors.blue,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricCard(BuildContext context, {required String title, required String value, required Color color}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
