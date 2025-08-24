class Menu {
  int? id;
  String name;
  String? description;
  double? priceBase;
  double priceSell;
  bool isAvailable;
  String? weightUnit;
  String? image;
  int? categoryId;

  Menu({
    this.id,
    required this.name,
    this.description,
    this.priceBase,
    required this.priceSell,
    required this.isAvailable,
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
      isAvailable: map['is_available'] == 1,
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
      'is_available': isAvailable ? 1 : 0,
      'weight_unit': weightUnit,
      'image': image,
      'category_id': categoryId,
    };
  }
}
