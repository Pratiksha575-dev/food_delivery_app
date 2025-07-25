import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _profileFormKey = GlobalKey<FormState>();
  bool _isEditingName = false;
  bool _isUpdating = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// --- Update display name in FirebaseAuth ---
  Future<void> _updateDisplayName() async {
    final user = FirebaseAuth.instance.currentUser;
    final newName = _nameController.text.trim();

    try {
      setState(() => _isUpdating = true);
      if (user != null) {
        await user.updateDisplayName(newName);
        await user.reload();
        setState(() => _isEditingName = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text("Username updated successfully"),
            backgroundColor: Colors.teal,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            margin: const EdgeInsets.all(12),),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update username: $e"),
    backgroundColor: Colors.teal,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    margin: const EdgeInsets.all(12),
    ),
      );
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  /// --- Cancel order in Firestore ---
  Future<void> _cancelOrder(String orderId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order?'),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('orders')
            .doc(orderId)
            .update({'status': 'Cancelled'});
      }
    }
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? '';
    if (!_isEditingName) _nameController.text = displayName;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            color: Colors.white,
            onPressed: () => _logout(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Profile Header ---
          Container(
            color: Colors.teal.shade50,
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 40,
                  child: Icon(Icons.person, size: 40),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _isEditingName
                      ? Form(
                    key: _profileFormKey,
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              hintText: 'Enter your name',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return "Username cannot be empty";
                              }
                              if (value.trim().length > 20) {
                                return "Max 20 characters allowed";
                              }
                              return null;
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.teal),
                          onPressed: _isUpdating
                              ? null
                              : () {
                            if (_profileFormKey.currentState!
                                .validate()) {
                              _updateDisplayName();
                            }
                          },
                        ),
                      ],
                    ),
                  )
                      : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              displayName.isEmpty
                                  ? "No Name"
                                  : displayName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: () =>
                                setState(() => _isEditingName = true),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? 'No email',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isUpdating)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Order History',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),

          // --- Orders List ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user?.uid)
                  .collection('orders')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading orders'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No previous orders'));
                }

                final orders = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final doc = orders[index];
                    final order = doc.data() as Map<String, dynamic>;
                    final items = order['items'] ?? [];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ExpansionTile(
                        title: Text(order['restaurantName'] ?? "Unknown"),
                        subtitle: Text(
                          '₹${order['total']} • ${order['status']}',
                          style: TextStyle(
                            color: order['status'] == 'Cancelled'
                                ? Colors.red
                                : Colors.black87,
                          ),
                        ),
                        children: [
                          Column(
                            children: [
                              ...items.map((item) => ListTile(
                                title: Text(item['name']),
                                trailing: Text(
                                    '₹${item['price']} x ${item['quantity']}'),
                              )),
                              if (order['status'] == 'Ordered') ...[
                                const Divider(),
                                TextButton.icon(
                                  onPressed: () => _cancelOrder(doc.id),
                                  icon: const Icon(Icons.cancel,
                                      color: Colors.red),
                                  label: const Text(
                                    'Cancel Order',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ]
                            ],
                          )
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
