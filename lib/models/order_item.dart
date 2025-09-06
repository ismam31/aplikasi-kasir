class OrderItem {
  int? id;
  int orderId;
  int menuId;
  double quantity;
  double price;
  String menuName;

  OrderItem({
    this.id,
    required this.orderId,
    required this.menuId,
    required this.quantity,
    required this.price,
    required this.menuName,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'],
      orderId: map['order_id'],
      menuId: map['menu_id'],
      quantity: map['quantity'],
      price: map['price'],
      menuName: map['menu_name'] as String? ?? 'Menu tidak diketahui',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_id': orderId,
      'menu_id': menuId,
      'quantity': quantity,
      'price': price,
      'menu_name': menuName,
    };
  }
}
