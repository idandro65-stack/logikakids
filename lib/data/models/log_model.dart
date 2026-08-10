class LogModel {
  final String id;
  final String timestamp;
  final String userName;
  final String role;
  final String action;
  final String description;

  LogModel({
    required this.id,
    required this.timestamp,
    required this.userName,
    required this.role,
    required this.action,
    required this.description,
  });

  factory LogModel.fromJson(Map<String, dynamic> json) {
    return LogModel(
      id: json['id']?.toString() ?? '',
      timestamp: json['timestamp']?.toString() ?? DateTime.now().toIso8601String(),
      userName: json['user_name']?.toString() ?? 'Sistem',
      role: json['role']?.toString() ?? 'staf',
      action: json['action']?.toString() ?? 'LOG',
      description: json['description']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp,
      'user_name': userName,
      'role': role,
      'action': action,
      'description': description,
    };
  }
}
