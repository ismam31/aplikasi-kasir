import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:aplikasi_kasir_seafood/pages/dashboard_page.dart';
import 'package:aplikasi_kasir_seafood/pages/order_page.dart';
import 'package:aplikasi_kasir_seafood/pages/active_orders_page.dart';
import 'package:aplikasi_kasir_seafood/pages/order_history_page.dart';
import 'package:aplikasi_kasir_seafood/pages/report_page.dart';
import 'package:aplikasi_kasir_seafood/pages/settings_page.dart';
import 'package:aplikasi_kasir_seafood/pages/menu_management_page.dart';
import 'package:aplikasi_kasir_seafood/pages/category_page.dart';

class CustomDrawer extends StatelessWidget {
  final String currentPage;

  const CustomDrawer({super.key, required this.currentPage});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      // Mengatur warna latar belakang drawer
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          // Bagian header drawer dengan gradien warna yang menarik
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF00796B), Color(0xFF004D40)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(30),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon aplikasi
                Icon(
                  FontAwesomeIcons.fish,
                  color: Colors.white,
                  size: 50,
                ),
                SizedBox(height: 10),
                // Judul aplikasi
                Text(
                  'Aplikasi Kasir Seafood',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                // Subtitle
                Text(
                  'Sistem Manajemen Restoran',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Item navigasi dengan gaya yang lebih modern
          _buildDrawerItem(
            context,
            icon: FontAwesomeIcons.house,
            title: 'Dashboard',
            page: const DashboardPage(),
            routeName: 'Dashboard',
            isSelected: currentPage == 'Dashboard',
          ),
          _buildDrawerItem(
            context,
            icon: FontAwesomeIcons.utensils,
            title: 'Manajemen Menu',
            page: const MenuManagementPage(),
            routeName: 'Manajemen Menu',
            isSelected: currentPage == 'Manajemen Menu',
          ),
          _buildDrawerItem(
            context,
            icon: FontAwesomeIcons.tags,
            title: 'Kategori',
            page: const CategoryPage(),
            routeName: 'Kategori',
            isSelected: currentPage == 'Kategori',
          ),
          const Divider(indent: 20, endIndent: 20, thickness: 1),
          _buildDrawerItem(
            context,
            icon: FontAwesomeIcons.cartShopping,
            title: 'Pemesanan',
            page: const OrderPage(),
            routeName: 'Pemesanan',
            isSelected: currentPage == 'Pemesanan',
          ),
          _buildDrawerItem(
            context,
            icon: FontAwesomeIcons.list,
            title: 'Pesanan Aktif',
            page: const ActiveOrdersPage(),
            routeName: 'Pesanan Aktif',
            isSelected: currentPage == 'Pesanan Aktif',
          ),
          _buildDrawerItem(
            context,
            icon: FontAwesomeIcons.history,
            title: 'Riwayat Pesanan',
            page: const OrderHistoryPage(),
            routeName: 'Riwayat Pesanan',
            isSelected: currentPage == 'Riwayat Pesanan',
          ),
          const Divider(indent: 20, endIndent: 20, thickness: 1),
          _buildDrawerItem(
            context,
            icon: FontAwesomeIcons.chartBar,
            title: 'Laporan',
            page: const ReportPage(),
            routeName: 'Laporan',
            isSelected: currentPage == 'Laporan',
          ),
          _buildDrawerItem(
            context,
            icon: FontAwesomeIcons.gear,
            title: 'Pengaturan',
            page: const SettingsPage(),
            routeName: 'Pengaturan',
            isSelected: currentPage == 'Pengaturan',
          ),
        ],
      ),
    );
  }

  // Widget pembantu untuk membuat item drawer dengan gaya yang konsisten
  Widget _buildDrawerItem(BuildContext context, {
    required IconData icon,
    required String title,
    required Widget page,
    required String routeName,
    bool isSelected = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isSelected ? Colors.teal.shade50 : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          size: 20,
          color: isSelected ? const Color(0xFF00796B) : Colors.blueGrey.shade800,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? const Color(0xFF00796B) : Colors.blueGrey.shade800,
          ),
        ),
        onTap: () {
          Navigator.pop(context);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        },
      ),
    );
  }
}
