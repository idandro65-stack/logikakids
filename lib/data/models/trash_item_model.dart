class TrashItemModel {
  final String id;
  final String itemType; // 'notulen', 'anak', 'program', 'staf', 'ruang'
  final String title;
  final String subtitle;
  final String deletedAt;
  final String deletedBy;
  final Map<String, dynamic> rawData;

  TrashItemModel({
    required this.id,
    required this.itemType,
    required this.title,
    required this.subtitle,
    required this.deletedAt,
    required this.deletedBy,
    required this.rawData,
  });

  factory TrashItemModel.fromJson(Map<String, dynamic> json) {
    return TrashItemModel(
      id: json['id']?.toString() ?? '',
      itemType: json['item_type']?.toString() ?? 'notulen',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      deletedAt: json['deleted_at']?.toString() ?? DateTime.now().toIso8601String(),
      deletedBy: json['deleted_by']?.toString() ?? 'Admin',
      rawData: json['raw_data'] is Map<String, dynamic>
          ? json['raw_data'] as Map<String, dynamic>
          : (json['raw_data'] is Map ? Map<String, dynamic>.from(json['raw_data'] as Map) : {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'item_type': itemType,
      'title': title,
      'subtitle': subtitle,
      'deleted_at': deletedAt,
      'deleted_by': deletedBy,
      'raw_data': rawData,
    };
  }
}
