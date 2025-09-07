class Category {
  int? id;
  String? name;
  int? orderPosition;
  String? createdAt;
  String? updatedAt;

  Category({
    this.id,
    this.name,
    this.orderPosition,
    this.createdAt,
    this.updatedAt,
  });

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      orderPosition: map['orderPosition'],
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'orderPosition': orderPosition,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
