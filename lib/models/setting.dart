class Setting {
  int? id;
  String? restoName;
  String? restoLogo;
  String? restoAddress;
  String? receiptMessage;
  String? restoPhone;
  String? restoPhone2;

  Setting({
    this.id,
    this.restoName,
    this.restoLogo,
    this.restoAddress,
    this.receiptMessage,
    this.restoPhone,
    this.restoPhone2,
  });

  // Factory dari Map
  factory Setting.fromMap(Map<String, dynamic> map) {
    return Setting(
      id: map['id'],
      restoName: map['resto_name'],
      restoLogo: map['resto_logo'],
      restoAddress: map['resto_address'],
      receiptMessage: map['receipt_message'],
      restoPhone: map['resto_phone'],
      restoPhone2: map['resto_phone2'],
    );
  }

  // Convert ke Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'resto_name': restoName,
      'resto_logo': restoLogo,
      'resto_address': restoAddress,
      'receipt_message': receiptMessage,
      'resto_phone': restoPhone,
      'resto_phone2': restoPhone2,
    };
  }

  // Tambahin copyWith biar bisa update sebagian field
  Setting copyWith({
    int? id,
    String? restoName,
    String? restoLogo,
    String? restoAddress,
    String? receiptMessage,
    String? restoPhone,
    String? restoPhone2,
  }) {
    return Setting(
      id: id ?? this.id,
      restoName: restoName ?? this.restoName,
      restoLogo: restoLogo ?? this.restoLogo,
      restoAddress: restoAddress ?? this.restoAddress,
      receiptMessage: receiptMessage ?? this.receiptMessage,
      restoPhone: restoPhone ?? this.restoPhone,
      restoPhone2: restoPhone2 ?? this.restoPhone2,
    );
  }
}
