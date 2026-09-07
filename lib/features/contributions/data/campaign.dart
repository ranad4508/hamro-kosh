import 'package:cloud_firestore/cloud_firestore.dart';

/// SRS §15 — an admin-created, named special-contribution campaign with a
/// target (e.g. "Dashain Contribution 2083"), distinct from an ad-hoc
/// special contribution a member tags themselves.
class Campaign {
  const Campaign({
    required this.id,
    required this.name,
    required this.description,
    this.targetAmount,
    required this.startDate,
    required this.endDate,
    this.isPublished = true,
    this.createdBy,
  });

  final String id;
  final String name;
  final String description;
  final double? targetAmount;
  final DateTime startDate;
  final DateTime endDate;
  final bool isPublished;
  final String? createdBy;

  bool get isActive {
    final now = DateTime.now();
    return isPublished && !now.isBefore(startDate) && !now.isAfter(endDate);
  }

  bool get hasEnded => DateTime.now().isAfter(endDate);

  factory Campaign.fromFirestore(String id, Map<String, dynamic> data) {
    return Campaign(
      id: id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      targetAmount: (data['targetAmount'] as num?)?.toDouble(),
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isPublished: data['isPublished'] as bool? ?? true,
      createdBy: data['createdBy'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'description': description,
    'targetAmount': targetAmount,
    'startDate': Timestamp.fromDate(startDate),
    'endDate': Timestamp.fromDate(endDate),
    'isPublished': isPublished,
    'createdBy': createdBy,
  };
}
