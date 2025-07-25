class FoodItem {
  final String id;
  final String name;
  final double price;

  FoodItem({required this.id, required this.name, required this.price});

  factory FoodItem.fromMap(Map<String, dynamic> data, String documentId) {
    return FoodItem(
      id: documentId,
      name: data['name'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
    );
  }
}
