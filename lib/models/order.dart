class Order {
  int? id;
  int? customerId;
  String? paymentMethod;
  double? totalAmount;
  String orderStatus;
  String orderTime;

  Order({
    this.id,
    this.customerId,
    this.paymentMethod,
    this.totalAmount,
    required this.orderStatus,
    required this.orderTime,
  });

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'],
      customerId: map['customer_id'],
      paymentMethod: map['payment_method'],
      totalAmount: map['total_amount'],
      orderStatus: map['order_status'],
      orderTime: map['order_time'],
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
    };
  }
}
