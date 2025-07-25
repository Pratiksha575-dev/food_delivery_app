import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.teal,
          title: const Text('Food Delivery App',style:TextStyle(color:Colors.white,fontWeight: FontWeight.bold,fontStyle: FontStyle.italic)),
          bottom: const TabBar(
            isScrollable: true,
            labelColor: Colors.white,
            indicatorColor: Colors.amber,
            tabs: [
              Tab(text: 'All'),
              Tab(text: 'Veg'),
              Tab(text: 'Non-Veg'),
              Tab(text: 'Cafe'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.shopping_cart),
              onPressed: () => Navigator.pushNamed(context, '/cart'),
            ),
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () => Navigator.pushNamed(context, '/profile'),
            ),
          ],
        ),
        body: const TabBarView(
          children: [
            RestaurantList(category: 'All'),
            RestaurantList(category: 'Veg'),
            RestaurantList(category: 'Non-Veg'),
            RestaurantList(category: 'Cafe'),
          ],
        ),
      ),
    );
  }
}

class RestaurantList extends StatelessWidget {
  final String category;

  const RestaurantList({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    Query restaurantsQuery = FirebaseFirestore.instance.collection('restaurants');
    if (category != 'All') {
      restaurantsQuery = restaurantsQuery.where('category', isEqualTo: category);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: restaurantsQuery.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading restaurants'));
        }

        final restaurants = snapshot.data?.docs ?? [];
        if (restaurants.isEmpty) {
          return const Center(child: Text('No restaurants available'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: restaurants.length,
          itemBuilder: (context, index) {
            final data = restaurants[index].data() as Map<String, dynamic>;
            final name = data['name'] ?? 'Unnamed';
            final image = data['image'] ?? '';
            final cat = data['category'] ?? '';

            return GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/restaurant', arguments: {
                  'id': restaurants[index].id,
                  'name': name,
                });
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  image: image.isNotEmpty
                      ? DecorationImage(
                    image: NetworkImage(image),
                    fit: BoxFit.cover,
                  )
                      : null,
                  color: Colors.grey.shade300,
                ),
                child: Stack(
                  children: [
                    // Gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: LinearGradient(
                          colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      bottom: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.restaurant_menu, color: Colors.amber, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                cat,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
