class Setting {
  int? id;
  String? restoName;
  String? restoLogo;
  String? restoAddress;
  String? receiptMessage;

  Setting({
    this.id,
    this.restoName,
    this.restoLogo,
    this.restoAddress,
    this.receiptMessage,
  });

  // Metode untuk mengubah Map dari database menjadi objek Setting
  factory Setting.fromMap(Map<String, dynamic> map) {
    return Setting(
      id: map['id'],
      restoName: map['resto_name'],
      restoLogo: map['resto_logo'],
      restoAddress: map['resto_address'],
      receiptMessage: map['receipt_message'],
    );
  }

  // Metode untuk mengubah objek Setting menjadi Map untuk disimpan ke database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'resto_name': restoName,
      'resto_logo': restoLogo,
      'resto_address': restoAddress,
      'receipt_message': receiptMessage,
    };
  }
}
