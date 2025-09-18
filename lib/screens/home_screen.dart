import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/wallet_service.dart';
import 'event_detail.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // For demo, use a fixed demo user id
  final String demoUserId = 'demo-user-1';

  @override
  Widget build(BuildContext context) {
    final eventsCol = FirebaseFirestore.instance.collection('events');

    return Scaffold(
      appBar: AppBar(title: const Text('SalesBets - Demo')),
      body: StreamBuilder<QuerySnapshot>(
        stream: eventsCol.orderBy('startTimestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Error loading events'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Text('No events found. Seed Firestore with events collection.'),
            );
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              print("-==-=>>> docs: $docs");
              final d = docs[index];
              final title = d['title'] ?? 'Untitled';
              final status = d['status'] ?? 'pending';
              return ListTile(
                title: Text(title),
                subtitle: Text('Status: $status'),
                trailing: IconButton(
                  icon: const Icon(Icons.open_in_new),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: d.id, demoUserId: demoUserId)));
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
