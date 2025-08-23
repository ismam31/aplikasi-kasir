class Customer {
  int? id;
  String name;
  String? tableNumber;
  String? notes;
  int? guestCount;

  Customer({
    this.id,
    required this.name,
    this.tableNumber,
    this.notes,
    this.guestCount,
  });

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      name: map['name'],
      tableNumber: map['table_number'],
      notes: map['notes'],
      guestCount: map['guest_count'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'table_number': tableNumber,
      'notes': notes,
      'guest_count': guestCount,
    };
  }
}
