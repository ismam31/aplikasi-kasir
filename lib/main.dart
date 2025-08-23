import 'package:flutter/material.dart';
import 'package:aplikasi_kasir_seafood/services/database_helper.dart';
import 'package:provider/provider.dart';
import 'pages/dashboard_page.dart';
import 'providers/category_provider.dart';
import 'providers/menu_provider.dart';
import 'providers/order_provider.dart';
import 'providers/customer_provider.dart';
import 'providers/order_list_provider.dart';
import 'providers/report_provider.dart';
import 'providers/expense_provider.dart';
import 'providers/setting_provider.dart';

void main() {
  // Pastikan binding Flutter sudah diinisialisasi
  WidgetsFlutterBinding.ensureInitialized();
  // Inisialisasi database di awal aplikasi
  DatabaseHelper().database;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => MenuProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => OrderListProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider(create: (_) => SettingProvider()),
        // Di sini kita akan menambahkan provider lain di masa depan
      ],
      child: MaterialApp(
        title: 'Aplikasi Kasir Seafood',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const DashboardPage(),
      ),
    );
  }
}
