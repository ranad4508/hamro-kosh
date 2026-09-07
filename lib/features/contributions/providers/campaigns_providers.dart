import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/campaign.dart';
import '../data/campaigns_repository.dart';

final campaignsRepositoryProvider = Provider<CampaignsRepository>((ref) {
  return CampaignsRepository(FirebaseFirestore.instance);
});

final campaignsProvider = StreamProvider<List<Campaign>>((ref) {
  return ref.watch(campaignsRepositoryProvider).watchCampaigns();
});

final campaignProgressProvider = StreamProvider.family<double, String>((
  ref,
  campaignId,
) {
  return ref
      .watch(campaignsRepositoryProvider)
      .watchCampaignProgress(campaignId);
});
