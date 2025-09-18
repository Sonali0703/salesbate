import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/wallet_service.dart';

class EventDetailScreen extends StatefulWidget {
  final String eventId;
  final String demoUserId;
  const EventDetailScreen({super.key, required this.eventId, required this.demoUserId});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final WalletService _wallet = WalletService();
  final TextEditingController _stakeCtrl = TextEditingController(text: '10');

  @override
  Widget build(BuildContext context) {
    final eventRef = FirebaseFirestore.instance.collection('events').doc(widget.eventId);
    return Scaffold(
      appBar: AppBar(title: const Text('Event')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: eventRef.snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final data = snap.data!.data() as Map<String, dynamic>?;
          if (data == null) return const Center(child: Text('Event not found'));
          final teams = List<String>.from(data['teams'] ?? []);
          final status = data['status'] ?? 'pending';
          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Text(data['title'] ?? 'Event', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Status: $status'),
                const SizedBox(height: 12),
                const Text('Teams:'),
                ...teams.map((t) => ListTile(
                      title: Text(t),
                      trailing: ElevatedButton(
                        child: const Text('Place Bet'),
                        onPressed: () async {
                          final stake = double.tryParse(_stakeCtrl.text) ?? 10.0;
                          // For demo, using team name as teamId
                          await _wallet.placeBet(
                              userId: widget.demoUserId,
                              eventId: widget.eventId,
                              teamId: t,
                              stake: stake);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bet placed (no-loss).')));
                        },
                      ),
                    )),
                const SizedBox(height: 12),
                TextField(
                  controller: _stakeCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Stake (demo credits)'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  child: const Text('Settle first pending bet as WIN (demo)'),
                  onPressed: () async {
                    // Find a pending bet by demo user for this event
                    final q = await FirebaseFirestore.instance.collection('bets')
                        .where('userId', isEqualTo: widget.demoUserId)
                        .where('eventId', isEqualTo: widget.eventId)
                        .where('status', isEqualTo: 'pending')
                        .limit(1)
                        .get();
                    if (q.docs.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No pending bets found for demo user.')));
                      return;
                    }
                    final betDoc = q.docs.first;
                    final teamId = betDoc['teamId'];
                    await _wallet.settleBet(betId: betDoc.id, winningTeamId: teamId);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settled bet as WIN and credited payout.')));
                  },
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  child: const Text('View my credits (demo)'),
                  onPressed: () async {
                    final userRef = FirebaseFirestore.instance.collection('users').doc(widget.demoUserId);
                    final snap = await userRef.get();
                    final credits = snap.data()?['credits'] ?? 0;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Credits: \$${credits.toString()}')));
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
