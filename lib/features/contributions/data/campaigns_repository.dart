import 'package:cloud_firestore/cloud_firestore.dart';

import 'campaign.dart';

class CampaignsRepository {
  CampaignsRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _campaigns =>
      _firestore.collection('campaigns');

  Stream<List<Campaign>> watchCampaigns() {
    return _campaigns
        .orderBy('startDate', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Campaign.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<void> createCampaign(Campaign campaign) {
    return _campaigns.add(campaign.toFirestore());
  }

  /// Sum of *verified* contributions tagged with this campaign — SRS §15
  /// "see campaign progress". Uses a collection-group query across every
  /// member's `contributions` subcollection, governed by the same read
  /// rule active members already get there (Phase 5's member-to-member
  /// transparency).
  Stream<double> watchCampaignProgress(String campaignId) {
    return _firestore
        .collectionGroup('contributions')
        .where('campaignId', isEqualTo: campaignId)
        .where('status', isEqualTo: 'verified')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.fold<double>(
            0,
            (total, doc) =>
                total + ((doc.data()['amount'] as num?)?.toDouble() ?? 0),
          ),
        );
  }
}
