class Order {
  int? id;
  int? customerId;
  String? paymentMethod;
  double? totalAmount;
  String orderStatus;
  String orderTime;
  double? paidAmount;
  double? changeAmount;

  Order({
    this.id,
    this.customerId,
    this.paymentMethod,
    this.totalAmount,
    required this.orderStatus,
    required this.orderTime,
    this.paidAmount,
    this.changeAmount,
  });

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'],
      customerId: map['customer_id'],
      paymentMethod: map['payment_method'],
      totalAmount: map['total_amount'],
      orderStatus: map['order_status'],
      orderTime: map['order_time'],
      paidAmount: map['paid_amount'],
      changeAmount: map['change_amount'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'payment_method': paymentMethod,
      'total_amount': totalAmount,
      'order_status': orderStatus,
      'order_time': orderTime,
      'paid_amount': paidAmount,
      'change_amount': changeAmount,
    };
  }
}
