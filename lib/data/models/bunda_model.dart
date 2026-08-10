class BundaModel {
  final String id;
  final String name;

  BundaModel({
    required this.id,
    required this.name,
  });

  factory BundaModel.fromJson(Map<String, dynamic> json) {
    return BundaModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}
