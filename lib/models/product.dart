class Product {
  final String id;
  final String name;
  final String category;
  final String description;
  final int price;
  final String imagePath;

  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.price,
    required this.imagePath,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as String,
      name: map['name'] as String,
      category: map['category'] as String,
      description: map['description'] as String? ?? '',
      price: (map['price'] as num).toInt(),
      imagePath: map['image_path'] as String? ?? '',
    );
  }
}
