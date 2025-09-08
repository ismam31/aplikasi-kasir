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
import 'package:aplikasi_kasir_seafood/pages/expense_history_page.dart';
import 'package:aplikasi_kasir_seafood/providers/setting_provider.dart';
import 'package:provider/provider.dart';
import 'dart:io';

class CustomDrawer extends StatelessWidget {
  final String currentPage;

  const CustomDrawer({super.key, required this.currentPage});

  Widget _buildDrawerHeader(
    BuildContext context,
    SettingProvider settingProvider,
  ) {
    final settings = settingProvider.settings;
    String capitalizedName = '';
    if (settings?.restoName != null && settings!.restoName!.isNotEmpty) {
      capitalizedName = settings.restoName!
          .split(' ')
          .map((word) {
            if (word.isNotEmpty) {
              return word[0].toUpperCase() + word.substring(1).toLowerCase();
            }
            return '';
          })
          .join(' ');
    }
    return Container(
      padding: const EdgeInsets.only(top: 40, right: 20, left: 20, bottom: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF00796B), Color(0xFF004D40)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(bottomRight: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Align(
            alignment: Alignment.center,
            child: CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white,
              backgroundImage: settings?.restoLogo != null
                  ? FileImage(File(settings!.restoLogo!))
                  : null,
              child: settings?.restoLogo == null
                  ? const Icon(
                      FontAwesomeIcons.fish,
                      color: Colors.black,
                      size: 30,
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            capitalizedName.isNotEmpty
                ? capitalizedName
                : 'Aplikasi Kasir Seafood',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Sistem Manajemen Restoran',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget page,
    required String pageName,
  }) {
    final isSelected = currentPage == pageName;

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
          color: isSelected
              ? const Color(0xFF00796B)
              : Colors.blueGrey.shade800,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? const Color(0xFF00796B)
                : Colors.blueGrey.shade800,
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

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Consumer<SettingProvider>(
        builder: (context, settingProvider, child) {
          if (settingProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              _buildDrawerHeader(context, settingProvider),
              const SizedBox(height: 5),
              _buildDrawerItem(
                context,
                icon: FontAwesomeIcons.house,
                title: 'Dashboard',
                page: const DashboardPage(),
                pageName: 'Dashboard',
              ),
              _buildDrawerItem(
                context,
                icon: FontAwesomeIcons.utensils,
                title: 'Manajemen Menu',
                page: const MenuManagementPage(),
                pageName: 'Manajemen Menu',
              ),
              _buildDrawerItem(
                context,
                icon: FontAwesomeIcons.tags,
                title: 'Kategori',
                page: const CategoryPage(),
                pageName: 'Kategori',
              ),
              const Divider(indent: 20, endIndent: 20, thickness: 1),
              _buildDrawerItem(
                context,
                icon: FontAwesomeIcons.cartShopping,
                title: 'Pemesanan',
                page: const OrderPage(),
                pageName: 'Pemesanan',
              ),
              _buildDrawerItem(
                context,
                icon: FontAwesomeIcons.list,
                title: 'Pesanan Aktif',
                page: const ActiveOrdersPage(),
                pageName: 'Pesanan Aktif',
              ),
              _buildDrawerItem(
                context,
                icon: FontAwesomeIcons.history,
                title: 'Riwayat Pesanan',
                page: const OrderHistoryPage(),
                pageName: 'Riwayat Pesanan',
              ),
              const Divider(indent: 20, endIndent: 20, thickness: 1),
              _buildDrawerItem(
                context,
                icon: FontAwesomeIcons.chartBar,
                title: 'Laporan',
                page: const ReportPage(),
                pageName: 'Laporan',
              ),
              _buildDrawerItem(
                context,
                icon: FontAwesomeIcons.moneyBillTransfer,
                title: 'Riwayat Pengeluaran',
                page: const ExpenseHistoryPage(),
                pageName: 'Riwayat Pengeluaran',
              ),
              const Divider(indent: 20, endIndent: 20, thickness: 1),
              _buildDrawerItem(
                context,
                icon: FontAwesomeIcons.gear,
                title: 'Pengaturan',
                page: const SettingsPage(),
                pageName: 'Pengaturan',
              ),
            ],
          );
        },
      ),
    );
  }
}
