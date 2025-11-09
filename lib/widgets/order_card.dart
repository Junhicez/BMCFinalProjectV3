import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderCard extends StatelessWidget {
  final Map<String, dynamic> orderData;

  const OrderCard({super.key, required this.orderData});

  @override
  Widget build(BuildContext context) {

    final Timestamp? timestamp = orderData['createdAt'];
    final String formattedDate;

    if (timestamp != null) {
      formattedDate = DateFormat('MM/dd/yyyy - hh:mm a')
          .format(timestamp.toDate());
    } else {
      formattedDate = 'Date not available';
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ListTile(
          title: Text(
            'Total: ₱${(orderData['totalPrice'] as double).toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),

          subtitle: Text(
            'Items: ${orderData['itemCount']}\n'
                'Status: ${orderData['status']}',
          ),

          trailing: Text(
            formattedDate,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),

          isThreeLine: true,
        ),
      ),
    );
  }
}