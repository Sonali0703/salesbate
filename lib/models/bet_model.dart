import 'package:cloud_firestore/cloud_firestore.dart';

class Bet {
  final String id;
  final String userId;
  final String eventId;
  final String teamId;
  final double stake;
  final String status;
  final double payout;

  Bet({
    required this.id,
    required this.userId,
    required this.eventId,
    required this.teamId,
    required this.stake,
    this.status = 'pending',
    this.payout = 0,
  });

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'eventId': eventId,
        'teamId': teamId,
        'stake': stake,
        'status': status,
        'payout': payout,
        'placedAt': FieldValue.serverTimestamp(),
      };
}
