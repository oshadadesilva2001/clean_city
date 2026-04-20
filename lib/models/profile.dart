class Profile {
  final String id;
  final String email;
  final String? fullName;
  final String role;
  final DateTime createdAt;

  const Profile({
    required this.id,
    required this.email,
    this.fullName,
    required this.role,
    required this.createdAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as String,
        email: json['email'] as String,
        fullName: json['full_name'] as String?,
        role: json['role'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  String get displayName => fullName?.isNotEmpty == true ? fullName! : email;
}
