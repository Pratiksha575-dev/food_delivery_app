import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../models/food_item.dart';
import '../widgets/food_tile.dart';

class RestaurantDetailScreen extends StatelessWidget {
  const RestaurantDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
    ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final restaurantId = args['id'];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: const Text(
          'Restaurant Details',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('restaurants')
            .doc(restaurantId)
            .get(),
        builder: (context, restaurantSnapshot) {
          if (restaurantSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!restaurantSnapshot.hasData || !restaurantSnapshot.data!.exists) {
            return const Center(child: Text('Restaurant not found'));
          }

          final restaurantData =
          restaurantSnapshot.data!.data() as Map<String, dynamic>;

          final restaurantName = restaurantData['name'] ?? 'No Name';
          final address = restaurantData['address'] ?? 'Address not available';
          final category =
              restaurantData['category'] ?? 'Category not available';
          final rating = (restaurantData['rating'] ?? 0).toString();

          return Column(
            children: [
              // ---- Restaurant Info Header ----
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurantName,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(category,
                        style: const TextStyle(
                            fontSize: 16, color: Colors.black54)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 20),
                        const SizedBox(width: 4),
                        Text(rating,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(address,
                        style: const TextStyle(
                            fontSize: 14, color: Colors.black87)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: ExpansionTile(
                    initiallyExpanded: true,
                    title: const Text(
                      "Menu",
                      style:
                      TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    children: [
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('restaurants')
                            .doc(restaurantId)
                            .collection('items')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return const Center(
                                child: Text('Error loading items'));
                          }
                          if (!snapshot.hasData) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          final items = snapshot.data!.docs;
                          if (items.isEmpty) {
                            return const Center(
                                child: Text('No items available'));
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(12),
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final data =
                              items[index].data() as Map<String, dynamic>;
                              final food =
                              FoodItem.fromMap(data, items[index].id);

                              return FoodTile(
                                food: food,
                                onAdd: () async {
                                  final cart = Provider.of<CartProvider>(context,
                                      listen: false);

                                  if (cart.restaurantId != null &&
                                      cart.restaurantId != restaurantId) {
                                    final clearCart = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Clear Cart?'),
                                        content: const Text(
                                            'Your cart has items from another restaurant. Clear it to add from this one?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const Text('Clear & Add'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (clearCart == true) {
                                      cart.clearCart();
                                    } else {
                                      return;
                                    }
                                  }
                                  await cart.addItem(
                                      food, restaurantId, restaurantName);
                                },
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      // ---- Mini Cart at Bottom ----
      bottomNavigationBar: Consumer<CartProvider>(
        builder: (context, cart, child) {
          if (cart.items.isEmpty) return const SizedBox();
          return GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/cart'),
            child: Container(
              margin: const EdgeInsets.all(12),
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.teal,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  )
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${cart.items.length} items | ₹${cart.totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const Icon(Icons.shopping_cart, color: Colors.white),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
