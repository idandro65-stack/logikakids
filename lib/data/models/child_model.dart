class ChildModel {
  final String id;
  final String name;
  final String category; // 'intensif' or 'reguler'
  final String? createdAt;

  ChildModel({
    required this.id,
    required this.name,
    required this.category,
    this.createdAt,
  });

  factory ChildModel.fromJson(Map<String, dynamic> json) {
    return ChildModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: (json['category']?.toString() ?? 'reguler').toLowerCase(),
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
    };
  }
}
