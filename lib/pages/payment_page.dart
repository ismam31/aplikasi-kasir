import 'package:aplikasi_kasir_seafood/widgets/custom_notification.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:aplikasi_kasir_seafood/models/order.dart' as model_order;
import 'package:aplikasi_kasir_seafood/pages/success_page.dart';
import 'package:aplikasi_kasir_seafood/providers/order_provider.dart';
import 'package:aplikasi_kasir_seafood/services/order_service.dart';
import 'package:aplikasi_kasir_seafood/widgets/custom_app_bar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PaymentPage extends StatefulWidget {
  final model_order.Order order;

  const PaymentPage({super.key, required this.order});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final TextEditingController _cashController = TextEditingController();
  String _selectedPaymentMethod = 'Tunai';

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'id_ID');
    return formatter.format(amount);
  }

  double get _totalAmount => widget.order.totalAmount ?? 0.0;
  double get _cashGiven {
    final cleanText = _cashController.text.replaceAll('.', '');
    return double.tryParse(cleanText) ?? 0.0;
  }

  double get _changeAmount => _cashGiven - _totalAmount;

  @override
  void initState() {
    super.initState();
    _cashController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _cashController.dispose();
    super.dispose();
  }

  Future<void> _completePayment() async {
    if (_selectedPaymentMethod == 'Tunai' && _changeAmount < 0) {
      CustomNotification.show(
        context,
        'Jumlah uang tunai kurang!',
        backgroundColor: Colors.red,
        icon: Icons.warning_amber,
      );
      return;
    }

    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final orderService = OrderService();
    final items = orderProvider.cart;
    int? newOrderId;

    if (widget.order.id == null) {
      final newOrder = model_order.Order(
        customerId: widget.order.customerId,
        orderStatus: 'Selesai',
        paymentMethod: _selectedPaymentMethod,
        orderTime: DateTime.now().toIso8601String(),
        totalAmount: _totalAmount,
        paidAmount: _cashGiven,
        changeAmount: _changeAmount,
      );
      newOrderId = await orderService.insertOrder(newOrder, items);
    } else {
      newOrderId = widget.order.id;
      final updatedOrder = model_order.Order(
        id: newOrderId,
        customerId: widget.order.customerId,
        orderStatus: 'Selesai',
        paymentMethod: _selectedPaymentMethod,
        orderTime: DateTime.now().toIso8601String(),
        totalAmount: _totalAmount,
        paidAmount: _cashGiven,
        changeAmount: _changeAmount,
      );
      await orderService.updateOrder(updatedOrder, items);
    }

    orderProvider.clearCart();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => SuccessPage(
          orderId: newOrderId!,
          cashGiven: _cashGiven,
          changeAmount: _changeAmount,
        ),
      ),
      (route) => false,
    );
  }

  void _onKeyPress(String value) {
    if (value == 'C') {
      _cashController.clear();
    } else if (value == '<') {
      if (_cashController.text.isNotEmpty) {
        _cashController.text = _cashController.text.substring(
          0,
          _cashController.text.length - 1,
        );
      }
    } else if (value == 'pas') {
      _cashController.text = _totalAmount.toStringAsFixed(0);
    } else {
      final currentText = _cashController.text.replaceAll('.', '');
      final newText = currentText + value;
      final formattedText = NumberFormat('#,###').format(double.parse(newText));
      _cashController.text = formattedText.replaceAll(',', '.');
    }
    _cashController.selection = TextSelection.fromPosition(
      TextPosition(offset: _cashController.text.length),
    );
  }

  Widget _buildPaymentSummaryCard({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      color: color.withOpacity(0.1),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rp ${_formatCurrency(amount)}',
                    style: TextStyle(
                      color: color,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypadButton(
    String text, {
    Color? color,
    IconData? icon,
    VoidCallback? onPressed,
  }) {
    final isIcon = icon != null;
    final isFunction = text == 'C' || text == '<' || text == 'pas';

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: ElevatedButton(
          onPressed: onPressed ?? () => _onKeyPress(text),
          style: ElevatedButton.styleFrom(
            backgroundColor: isFunction
                ? Colors.blueGrey.shade100
                : color ?? Colors.grey.shade200,
            foregroundColor: isFunction
                ? Colors.blueGrey.shade700
                : Colors.black87,
            padding: const EdgeInsets.symmetric(vertical: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            minimumSize: const Size(0, 70),
          ),
          child: isIcon
              ? Icon(icon, size: 28)
              : Text(
                  text,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodChip(String method, IconData icon) {
    return ChoiceChip(
      label: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(method),
        ],
      ),
      selected: _selectedPaymentMethod == method,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedPaymentMethod = method;
          });
        }
      },
      selectedColor: Colors.teal.shade50,
      backgroundColor: Colors.grey.shade200,
      labelStyle: TextStyle(
        color: _selectedPaymentMethod == method
            ? Colors.teal.shade900
            : Colors.blueGrey,
        fontWeight: _selectedPaymentMethod == method
            ? FontWeight.bold
            : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: _selectedPaymentMethod == method
              ? Colors.teal
              : Colors.grey.shade400,
          width: 1.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Pembayaran', showBackButton: true),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Column(
                children: [
                  _buildPaymentSummaryCard(
                    title: 'Total Pembayaran',
                    amount: _totalAmount,
                    color: Colors.teal,
                    icon: FontAwesomeIcons.sackDollar,
                  ),
                  const SizedBox(height: 8),
                  _buildPaymentSummaryCard(
                    title: 'Uang Dibayarkan',
                    amount: _cashGiven,
                    color: Colors.blue,
                    icon: FontAwesomeIcons.wallet,
                  ),
                  const SizedBox(height: 8),
                  _buildPaymentSummaryCard(
                    title: 'Kembalian',
                    amount: _changeAmount,
                    color: _changeAmount >= 0 ? Colors.green : Colors.red,
                    icon: FontAwesomeIcons.moneyBillTransfer,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildPaymentMethodChip(
                        'Tunai',
                        FontAwesomeIcons.moneyBill,
                      ),
                      const SizedBox(width: 16),
                      _buildPaymentMethodChip(
                        'Transfer',
                        FontAwesomeIcons.creditCard,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Keypad section
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  spreadRadius: 2,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildKeypadButton('7'),
                    _buildKeypadButton('8'),
                    _buildKeypadButton('9'),
                    _buildKeypadButton('<', icon: Icons.backspace),
                  ],
                ),
                Row(
                  children: [
                    _buildKeypadButton('4'),
                    _buildKeypadButton('5'),
                    _buildKeypadButton('6'),
                    _buildKeypadButton('C', icon: Icons.clear),
                  ],
                ),
                Row(
                  children: [
                    _buildKeypadButton('1'),
                    _buildKeypadButton('2'),
                    _buildKeypadButton('3'),
                    _buildKeypadButton('pas', icon: FontAwesomeIcons.coins),
                  ],
                ),
                Row(
                  children: [
                    _buildKeypadButton('0'),
                    _buildKeypadButton('00'),
                    _buildKeypadButton('.'),
                    _buildKeypadButton(
                      'Bayar',
                      color: Colors.green,
                      onPressed: _completePayment,
                      icon: Icons.check,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
