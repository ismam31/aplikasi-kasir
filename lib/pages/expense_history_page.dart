import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:aplikasi_kasir_seafood/providers/expense_provider.dart';
import 'package:aplikasi_kasir_seafood/widgets/custom_app_bar.dart';
import 'package:aplikasi_kasir_seafood/widgets/custom_drawer.dart';
import 'package:aplikasi_kasir_seafood/widgets/custom_notification.dart';
import 'package:aplikasi_kasir_seafood/models/expense.dart' as model_expense;
import 'package:intl/intl.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';

class ExpenseHistoryPage extends StatefulWidget {
  const ExpenseHistoryPage({super.key});

  @override
  State<ExpenseHistoryPage> createState() => _ExpenseHistoryPageState();
}

class _ExpenseHistoryPageState extends State<ExpenseHistoryPage> {
  final _descController = TextEditingController();
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ExpenseProvider>(context, listen: false).loadExpenses();
    });
  }

  @override
  void dispose() {
    _descController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'id_ID');
    return 'Rp ${formatter.format(amount)}';
  }

  void _showAddExpenseDialog() async {
    // Menggunakan showGeneralDialog untuk animasi
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Tambah Pengeluaran',
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          ),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Tambah Pengeluaran',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _descController,
                  decoration: InputDecoration(
                    labelText: 'Deskripsi',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'Deskripsi tidak boleh kosong' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    labelText: 'Jumlah (Rp)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    // Menggunakan CurrencyInputFormatter untuk otomatisasi
                    CurrencyInputFormatter(
                      thousandSeparator: ThousandSeparator.Period,
                      mantissaLength: 0,
                    ),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Jumlah tidak boleh kosong';
                    }
                    final doubleAmount = double.tryParse(value);
                    if (doubleAmount == null || doubleAmount <= 0) {
                      return 'Jumlah harus lebih dari 0';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: Colors.blueGrey),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final desc = _descController.text.trim();
                  // Menggunakan toDouble dari package flutter_multi_formatter
                  final amount = double.parse(_amountController.text);
                  final newExpense = model_expense.Expense(
                    id: null,
                    description: desc,
                    amount: amount,
                    date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                  );
                  await Provider.of<ExpenseProvider>(
                    context,
                    listen: false,
                  ).insertExpense(newExpense);
                  Navigator.pop(context);
                  if (mounted) {
                    CustomNotification.show(
                      context,
                      'Pengeluaran berhasil disimpan!',
                      backgroundColor: Colors.green,
                      icon: Icons.check,
                    );
                    // Memuat ulang data setelah menambahkan pengeluaran
                    await Provider.of<ExpenseProvider>(
                      context,
                      listen: false,
                    ).loadExpenses();
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void _deleteExpense(int id) async {
    await Provider.of<ExpenseProvider>(
      context,
      listen: false,
    ).deleteExpense(id);
    CustomNotification.show(
      context,
      'Pengeluaran berhasil dihapus',
      backgroundColor: Colors.red,
      icon: Icons.check,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Riwayat Pengeluaran'),
      drawer: const CustomDrawer(currentPage: 'Riwayat Pengeluaran'),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddExpenseDialog,
        tooltip: 'Tambah Pengeluaran',
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, expenseProvider, child) {
          if (expenseProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final expenses = expenseProvider.expenses;
          if (expenses.isEmpty) {
            return const Center(child: Text('Belum ada data pengeluaran.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: expenses.length,
            itemBuilder: (context, index) {
              final expense = expenses[index];
              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: const Icon(
                    FontAwesomeIcons.moneyBillTransfer,
                    color: Colors.red,
                    size: 30,
                  ),
                  title: Text(
                    expense.description,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    ),
                  ),
                  subtitle: Text(
                    DateFormat(
                      'dd MMM yyyy',
                    ).format(DateTime.parse(expense.date)),
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatCurrency(expense.amount),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteExpense(expense.id!),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
