import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // We'll use this for dates again

class AdminOrderScreen extends StatefulWidget {
  const AdminOrderScreen({super.key});

  @override
  State<AdminOrderScreen> createState() => _AdminOrderScreenState();
}

class _AdminOrderScreenState extends State<AdminOrderScreen> {
  // 1. Get an instance of Firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 2. This is the function that updates the status in Firestore
  // (Part D, Step 1):
  // We added String userId as a parameter.
  // _firestore.collection('notifications').add(...): After successfully updating the order, we create a new document in our notifications collection.
  // We save the userId so our query in NotificationIcon can find it.
  // We save isRead: false, which will trigger the "new" badge on the user's HomeScreen.
  Future<void> _updateOrderStatus(String orderId, String newStatus, String userId) async {
    try {
      // 3. Find the document and update the 'status' field
      await _firestore.collection('orders').doc(orderId).update({
        'status': newStatus,
      });

      // 3. --- ADD THIS NEW LOGIC ---
      //    Create a new notification document
      await _firestore.collection('notifications').add({
        'userId': userId, // 4. The user this notification is for
        'title': 'Order Status Updated',
        'body': 'Your order ($orderId) has been updated to "$newStatus".',
        'orderId': orderId,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false, // 5. Mark it as unread
      });
      // --- END OF NEW LOGIC ---

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order status updated!')),
      );
    } catch (e) {
      // ... (error handling is the same)
    }
  }

  // lib/screens/admin_order_screen.dart - Part 2: Update Dialog Functions
  // Now we just need to pass the userId to the functions that call _updateOrderStatus.

  // 1. MODIFY this function to accept userId
  void _showStatusDialog(String orderId, String currentStatus, String userId) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        // ... (statuses list is the same)
        const statuses = ['Pending', 'Processing', 'Shipped', 'Delivered', 'Cancelled'];

        return AlertDialog(
          // ... (title, content, etc. is the same)
          title: const Text('Update Order Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: statuses.map((status) {
              return ListTile(
                // ... (title, trailing)
                title: Text(status),
                trailing: currentStatus == status ? const Icon(Icons.check) : null,
                onTap: () {
                  // 2. PASS userId to our update function
                  _updateOrderStatus(orderId, status, userId);
                  Navigator.of(dialogContext).pop();
                },
              );
            }).toList(),
          ),
          // ... (actions are the same)
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            )
          ],
        );
      },
    );
  }

  // ... (inside the build method)
  @override
  Widget build(BuildContext context) {
    // ... (inside the StreamBuilder's ListView.builder)
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Orders'),
      ),
      // 1. Use a StreamBuilder to get all orders
      body: StreamBuilder<QuerySnapshot>(
        // 2. This is our query
        stream: _firestore
            .collection('orders')
            .orderBy('createdAt', descending: true) // Newest first
            .snapshots(),
        builder: (context, snapshot) {
          // 3. Handle all states: loading, error, empty
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No orders found.'));
          }

          // 4. We have the orders!
          final orders = snapshot.data!.docs;

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final orderData = order.data() as Map<String, dynamic>;

              // ... (getting orderData, timestamp, status, etc.)
              final Timestamp? timestamp = orderData['createdAt'];
              final String formattedDate = timestamp != null
                  ? DateFormat('MM/dd/yyyy hh:mm a').format(timestamp.toDate())
                  : 'No date';

              final String status = orderData['status'] ?? 'Unknown';
              final double totalPrice = (orderData['totalPrice'] ?? 0.0) as double;
              final String formattedTotal = '₱${totalPrice.toStringAsFixed(2)}';
              final String userId = orderData['userId'] ?? 'Unknown User';

              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text(
                    'Order ID: ${order.id}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  subtitle: Text(
                    'User: $userId\nTotal: $formattedTotal | Date: $formattedDate',
                  ),
                  isThreeLine: true,
                  trailing: Chip(
                    label: Text(
                      status,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    backgroundColor:
                    status == 'Pending'
                        ? Colors.orange
                        : status == 'Processing'
                        ? Colors.blue
                        : status == 'Shipped'
                        ? Colors.deepPurple
                        : status == 'Delivered'
                        ? Colors.green
                        : Colors.red,
                  ),
                  onTap: () {
                    // 3. PASS userId from the order data to our dialog
                    _showStatusDialog(order.id, status, userId);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
