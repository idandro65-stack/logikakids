class UserModel {
  final String username;
  final String password;
  final String name;
  final String role; // 'admin' or 'staf'

  UserModel({
    required this.username,
    required this.password,
    required this.name,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      username: json['username']?.toString() ?? '',
      password: json['password']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      role: json['role']?.toString() ?? 'staf',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'name': name,
      'role': role,
    };
  }
}
