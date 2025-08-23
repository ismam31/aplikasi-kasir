import 'package:aplikasi_kasir_seafood/models/order_item.dart' as model_order_item;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:aplikasi_kasir_seafood/models/order.dart' as model_order;
import 'package:aplikasi_kasir_seafood/pages/success_page.dart';
import 'package:aplikasi_kasir_seafood/providers/order_list_provider.dart';
import 'package:aplikasi_kasir_seafood/providers/order_provider.dart';
import 'package:aplikasi_kasir_seafood/widgets/custom_app_bar.dart';
import 'package:aplikasi_kasir_seafood/widgets/custom_notification.dart';

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
  double get _cashGiven => double.tryParse(_cashController.text.replaceAll('.', '').replaceAll(',', '')) ?? 0.0;
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

  void _completePayment() {
    if (_selectedPaymentMethod == 'Tunai' && _changeAmount < 0) {
      CustomNotification.show(
        context,
        'Jumlah uang tunai kurang!',
        backgroundColor: Colors.red,
        icon: Icons.warning_amber,
      );
      return;
    }

    Provider.of<OrderListProvider>(context, listen: false).updateOrderStatus(
      widget.order.id!,
      'Selesai',
    );

    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final items = List<model_order_item.OrderItem>.from(orderProvider.cart);
    
    Provider.of<OrderProvider>(context, listen: false).clearCart();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => SuccessPage(
          changeAmount: _changeAmount,
          order: widget.order,
          cashGiven: _cashGiven,
          items: items,
        ),
      ),
    );
  }

  void _onKeyPress(String value) {
    if (value == 'C') {
      _cashController.clear();
    } else if (value == '<') {
      if (_cashController.text.isNotEmpty) {
        _cashController.text =
            _cashController.text.substring(0, _cashController.text.length - 1);
      }
    } else if (value == 'pas') {
      _cashController.text = _totalAmount.toStringAsFixed(0);
    } else {
      _cashController.text += value;
    }
    _cashController.selection = TextSelection.fromPosition(
      TextPosition(offset: _cashController.text.length),
    );
  }

  Widget _buildKeypadButton(String text, {Color? color}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: ElevatedButton(
          onPressed: () => _onKeyPress(text),
          style: ElevatedButton.styleFrom(
            backgroundColor: color ?? Colors.grey[200],
            foregroundColor: Colors.black87,
            padding: const EdgeInsets.symmetric(vertical: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            minimumSize: const Size(0, 70),
          ),
          child: Text(
            text,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildFunctionButton(IconData icon, Function()? onPressed) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade100,
            foregroundColor: Colors.blue.shade800,
            padding: const EdgeInsets.symmetric(vertical: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            minimumSize: const Size(0, 70),
          ),
          child: Icon(icon, size: 24),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodChip(String method, IconData icon) {
    return ChoiceChip(
      label: Text(method),
      selected: _selectedPaymentMethod == method,
      onSelected: (selected) {
        setState(() {
          _selectedPaymentMethod = method;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Pembayaran',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.green),
            onPressed: _completePayment,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text('Total: Rp', style: TextStyle(fontSize: 20)),
                  Text(
                    _formatCurrency(_totalAmount),
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  const Text('Dibayarkan:', style: TextStyle(fontSize: 20)),
                  Text(
                    'Rp ${_cashController.text.isNotEmpty ? _formatCurrency(_cashGiven) : '0'}',
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8.0,
                    children: [
                      _buildPaymentMethodChip('Tunai', Icons.money),
                      _buildPaymentMethodChip('Debit', Icons.credit_card),
                      _buildPaymentMethodChip('QRIS', Icons.qr_code),
                      _buildPaymentMethodChip('Piutang', Icons.list),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (_selectedPaymentMethod == 'Tunai') ...[
                    Text(
                      'Kembalian: Rp ${_formatCurrency(_changeAmount)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _changeAmount >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.grey[100],
            child: Column(
              children: [
                Row(
                  children: [
                    _buildKeypadButton('7'),
                    _buildKeypadButton('8'),
                    _buildKeypadButton('9'),
                    _buildFunctionButton(Icons.backspace, () => _onKeyPress('<')),
                  ],
                ),
                Row(
                  children: [
                    _buildKeypadButton('4'),
                    _buildKeypadButton('5'),
                    _buildKeypadButton('6'),
                    _buildFunctionButton(Icons.clear, () => _onKeyPress('C')),
                  ],
                ),
                Row(
                  children: [
                    _buildKeypadButton('1'),
                    _buildKeypadButton('2'),
                    _buildKeypadButton('3'),
                    _buildFunctionButton(Icons.monetization_on, () => _onKeyPress('pas')),
                  ],
                ),
                Row(
                  children: [
                    _buildKeypadButton('0'),
                    _buildKeypadButton('00'),
                    _buildKeypadButton('.'),
                    _buildFunctionButton(Icons.check, _completePayment),
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
