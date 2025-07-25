class Restaurant {
  final String id;
  final String name;
  final String imageUrl;

  Restaurant({required this.id, required this.name, required this.imageUrl});

  factory Restaurant.fromMap(Map<String, dynamic> data, String documentId) {
    return Restaurant(
      id: documentId,
      name: data['name'] ?? '',
      imageUrl: data['image'] ?? '',
    );
  }
}
