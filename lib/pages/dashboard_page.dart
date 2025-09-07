import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aplikasi_kasir_seafood/providers/report_provider.dart';
import 'package:aplikasi_kasir_seafood/providers/order_list_provider.dart';
import 'package:aplikasi_kasir_seafood/widgets/custom_app_bar.dart';
import 'package:aplikasi_kasir_seafood/widgets/custom_drawer.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
    
    // Perbaikan: variabel yang tidak terdefinisi dihilangkan
    // final activeOrders = orderListProvider.activeOrders;

    await Future.wait([
      orderProvider.loadOrders(),
      reportProvider.loadReports(DateTime.now()),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Dashboard Kasir'),
      drawer: const CustomDrawer(currentPage: 'Dashboard',),
      body: Consumer<ReportProvider>(
        builder: (context, reportProvider, child) {
          if (reportProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Mengambil OrderListProvider di sini untuk mendapatkan data pesanan aktif
          final orderListProvider = Provider.of<OrderListProvider>(context);

          final formatter = NumberFormat('#,###', 'id_ID');
          String formatCurrency(double amount) {
            return formatter.format(amount);
          }

          return RefreshIndicator(
            onRefresh: () => _refreshDashboard(context),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              children: <Widget>[
                // Tampilan kartu metrik utama
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildMetricCard(
                      context,
                      title: 'Total Pendapatan',
                      value: formatCurrency(reportProvider.totalRevenue),
                      color: Colors.green,
                      icon: FontAwesomeIcons.sackDollar,
                    ),
                    _buildMetricCard(
                      context,
                      title: 'Total Pengeluaran',
                      value: formatCurrency(reportProvider.totalExpenses),
                      color: Colors.red,
                      icon: FontAwesomeIcons.moneyBillTransfer,
                    ),
                    _buildMetricCard(
                      context,
                      title: 'Keuntungan Bersih',
                      value: formatCurrency(reportProvider.netProfit),
                      color: Colors.blue,
                      icon: FontAwesomeIcons.chartLine,
                    ),
                    // Kartu tambahan untuk pesanan aktif
                    _buildMetricCard(
                      context,
                      title: 'Pesanan Aktif',
                      // Menggunakan data dari provider dan mengkonversinya ke string
                      value: orderListProvider.activeOrders.length.toString(),
                      color: Colors.orange,
                      icon: FontAwesomeIcons.bellConcierge,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Bagian untuk daftar menu terlaris atau info lainnya
                const Text(
                  'Analisis Penjualan',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF004D40),
                  ),
                ),
                const SizedBox(height: 16),
                _buildBestSellerCard(
                  context,
                  title: 'Menu Terlaris',
                  items: [
                    {'name': 'Kepiting Saus Padang', 'count': 50},
                    {'name': 'Udang Goreng Tepung', 'count': 45},
                    {'name': 'Ikan Bakar Bumbu', 'count': 40},
                  ],
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
    required IconData icon,
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
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Ikon yang lebih besar
              Icon(
                icon,
                size: 24,
                color: color,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color.withOpacity(0.9),
                ),
              ),
            ],
          ),
          Text.rich(
            TextSpan(
              children: [
                // Perbaikan: Hanya tambahkan 'Rp ' untuk kartu yang menampilkan mata uang
                if (title == 'Total Pendapatan' || title == 'Total Pengeluaran' || title == 'Keuntungan Bersih')
                  TextSpan(
                    text: 'Rp ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      color: color,
                    ),
                  ),
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontSize: 24,
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

  Widget _buildBestSellerCard(BuildContext context, {
    required String title,
    required List<Map<String, dynamic>> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    const Icon(FontAwesomeIcons.circle, size: 8, color: Colors.teal),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item['name']!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        // Menambahkan `overflow: TextOverflow.ellipsis` untuk mencegah overflow
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${item['count']} porsi',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blueGrey.shade700,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
