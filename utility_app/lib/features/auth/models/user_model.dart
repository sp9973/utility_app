class UserModel {
  final String uid;
  final String email;
  final String role;
  final String? name;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    this.name,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, String uid) {
    return UserModel(
      uid: uid,
      email: json['email'] ?? '',
      role: json['role'] ?? 'citizen',
      name: json['name'],
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'email': email,
        'role': role,
        'name': name,
        'createdAt': createdAt,
      };
}
