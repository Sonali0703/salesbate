import 'package:cloud_firestore/cloud_firestore.dart';

class WalletService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Place a bet: records bet but DOES NOT deduct credits (no-loss mechanic)
  Future<void> placeBet({
    required String userId,
    required String eventId,
    required String teamId,
    required double stake,
  }) async {
    final betRef = _db.collection('bets').doc();
    await betRef.set({
      'userId': userId,
      'eventId': eventId,
      'teamId': teamId,
      'stake': stake,
      'status': 'pending',
      'placedAt': FieldValue.serverTimestamp(),
    });
  }

  // For demo: settle a bet and award payout if winningTeamId matches
  Future<void> settleBet({
    required String betId,
    required String winningTeamId,
  }) async {
    final betRef = _db.collection('bets').doc(betId);
    final betSnap = await betRef.get();
    if (!betSnap.exists) return;
    final betData = betSnap.data()!;
    final String teamId = betData['teamId'];
    final String userId = betData['userId'];
    final double stake = (betData['stake'] ?? 0).toDouble();

    if (teamId == winningTeamId) {
      final payout = stake * 2; // simple 2x payout for demo
      final userRef = _db.collection('users').doc(userId);
      await _db.runTransaction((tx) async {
        final userSnap = await tx.get(userRef);
        final current = (userSnap.data()?['credits'] ?? 0).toDouble();
        tx.update(userRef, {'credits': current + payout});
        tx.update(betRef, {'status': 'won', 'payout': payout});
      });
    } else {
      await betRef.update({'status': 'lost', 'payout': 0});
    }
  }
}
