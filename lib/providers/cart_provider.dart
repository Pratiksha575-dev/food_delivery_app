import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/food_item.dart';

class CartItem {
  final FoodItem food;
  int quantity;

  CartItem({required this.food, this.quantity = 1});

  Map<String, dynamic> toMap() => {
    'id': food.id,
    'name': food.name,
    'price': food.price,
    'quantity': quantity,
  };
}

class CartProvider with ChangeNotifier {
  final Map<String, CartItem> _items = {};
  String? _restaurantId;
  String? _restaurantName;

  Map<String, CartItem> get items => _items;
  double get totalPrice =>
      _items.values.fold(0, (sum, item) => sum + item.food.price * item.quantity);
  String? get restaurantId => _restaurantId;
  String? get activeRestaurantName => _restaurantName;

  bool get isEmpty => _items.isEmpty;

  Future<void> addItem(FoodItem food, String restaurantId, [String? restaurantName]) async {
    if (_restaurantId != null && _restaurantId != restaurantId) {
      return; // handled externally
    }

    _restaurantId = restaurantId;
    if (restaurantName != null) _restaurantName = restaurantName;

    if (_items.containsKey(food.id)) {
      _items[food.id]!.quantity++;
    } else {
      _items[food.id] = CartItem(food: food);
    }
    notifyListeners();
  }

  void updateQuantity(String foodId, int quantity, {FoodItem? food}) {
    if (_items.containsKey(foodId)) {
      if (quantity <= 0) {
        _items.remove(foodId);
      } else {
        _items[foodId]!.quantity = quantity;
      }
    } else if (food != null && quantity > 0) {
      _items[foodId] = CartItem(food: food, quantity: quantity);
    }
    notifyListeners();
  }

  void removeItem(String foodId) {
    _items.remove(foodId);
    if (_items.isEmpty) {
      _restaurantId = null;
      _restaurantName = null;
    }
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _restaurantId = null;
    _restaurantName = null;
    notifyListeners();
  }

  /// --- CONFIRM ORDER (Firestore) ---
  Future<void> confirmOrder() async {
    if (_items.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final orderData = {
      'restaurantId': _restaurantId,
      'restaurantName': _restaurantName,
      'items': _items.values.map((e) => e.toMap()).toList(),
      'total': totalPrice,
      'status': 'Ordered',
      'timestamp': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('orders')
        .add(orderData);

    clearCart();
  }

  /// --- CANCEL ORDER ---
  Future<void> cancelOrder(String orderId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('orders')
        .doc(orderId)
        .update({'status': 'Cancelled'});
  }
}
