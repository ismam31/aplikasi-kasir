import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aplikasi_kasir_seafood/providers/report_provider.dart';
import 'package:aplikasi_kasir_seafood/providers/expense_provider.dart';
import 'package:aplikasi_kasir_seafood/models/expense.dart' as model_expense;
import 'package:aplikasi_kasir_seafood/widgets/custom_app_bar.dart';
import 'package:aplikasi_kasir_seafood/widgets/custom_drawer.dart';

class ReportPage extends StatelessWidget {
  const ReportPage({super.key});

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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Bagian Ringkasan Laporan
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildMetricRow(
                          'Total Pendapatan',
                          reportProvider.totalRevenue,
                          Colors.green,
                        ),
                        const Divider(),
                        _buildMetricRow(
                          'Total Pengeluaran',
                          reportProvider.totalExpenses,
                          Colors.red,
                        ),
                        const Divider(),
                        _buildMetricRow(
                          'Keuntungan Bersih',
                          reportProvider.netProfit,
                          Colors.blue,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Bagian Input Pengeluaran
                const Text(
                  'Catat Pengeluaran Baru',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildExpenseForm(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricRow(String title, double amount, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            'Rp ${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseForm(BuildContext context) {
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController amountController = TextEditingController();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Deskripsi Pengeluaran',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Jumlah (Rp)'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final description = descriptionController.text;
                  final amount = double.tryParse(amountController.text) ?? 0.0;

                  if (description.isNotEmpty && amount > 0) {
                    final newExpense = model_expense.Expense(
                      description: description,
                      amount: amount,
                      date: DateTime.now().toIso8601String(),
                    );
                    Provider.of<ExpenseProvider>(
                      context,
                      listen: false,
                    ).addExpense(newExpense);

                    // Setelah pengeluaran dicatat, muat ulang laporan
                    Provider.of<ReportProvider>(
                      context,
                      listen: false,
                    ).loadReports();

                    descriptionController.clear();
                    amountController.clear();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Pengeluaran berhasil dicatat!'),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Isi deskripsi dan jumlah dengan benar.'),
                      ),
                    );
                  }
                },
                child: const Text('Simpan Pengeluaran'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
