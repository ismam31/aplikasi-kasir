class Menu {
  int? id;
  String name;
  String? description;
  double? priceBase;
  double priceSell;
  int? stock;
  String? weightUnit;
  String? image;
  int? categoryId;

  Menu({
    this.id,
    required this.name,
    this.description,
    this.priceBase,
    required this.priceSell,
    this.stock,
    this.weightUnit,
    this.image,
    this.categoryId,
  });

  factory Menu.fromMap(Map<String, dynamic> map) {
    return Menu(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      priceBase: map['price_base'],
      priceSell: map['price_sell'],
      stock: map['stock'],
      weightUnit: map['weight_unit'],
      image: map['image'],
      categoryId: map['category_id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price_base': priceBase,
      'price_sell': priceSell,
      'stock': stock,
      'weight_unit': weightUnit,
      'image': image,
      'category_id': categoryId,
    };
  }
}
