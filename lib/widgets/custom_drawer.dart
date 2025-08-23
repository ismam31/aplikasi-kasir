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
  const CustomDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          // Bagian header drawer
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue.shade800),
            child: const Text(
              'Aplikasi Kasir Seafood',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          // Item navigasi untuk Dashboard
          ListTile(
            leading: const Icon(FontAwesomeIcons.house, size: 20),
            title: const Text('Dashboard', style: TextStyle(fontSize: 20)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const DashboardPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(FontAwesomeIcons.utensils, size: 20),
            title: const Text('Manajemen Menu', style: TextStyle(fontSize: 20)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const MenuManagementPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(FontAwesomeIcons.tags, size: 20),
            title: const Text('Kategori', style: TextStyle(fontSize: 20)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const CategoryPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(FontAwesomeIcons.cartShopping, size: 20),
            title: const Text('Pemesanan', style: TextStyle(fontSize: 20)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const OrderPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(FontAwesomeIcons.list, size: 20),
            title: const Text('Pesanan Aktif', style: TextStyle(fontSize: 20)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const ActiveOrdersPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(FontAwesomeIcons.history, size: 20),
            title: const Text(
              'Riwayat Pesanan',
              style: TextStyle(fontSize: 20),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const OrderHistoryPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(FontAwesomeIcons.chartBar, size: 20),
            title: const Text('Laporan', style: TextStyle(fontSize: 20)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ReportPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(FontAwesomeIcons.gear, size: 20),
            title: const Text('Pengaturan', style: TextStyle(fontSize: 20)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
          const Divider(),
        ],
      ),
    );
  }
}
