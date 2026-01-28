class User {
  final String id;
  final String username;
  final String fullName;
  final String? email;
  final String? phone;
  final String role; // 'admin', 'cashier', 'pharmacist'
  final bool isActive;
  final DateTime? lastLogin;
  final DateTime createdAt;

  User({
    required this.id,
    required this.username,
    required this.fullName,
    this.email,
    this.phone,
    required this.role,
    required this.isActive,
    this.lastLogin,
    required this.createdAt,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String,
      username: map['username'] as String,
      fullName: map['full_name'] as String,
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      role: map['role'] as String,
      isActive: (map['is_active'] as int) == 1,
      lastLogin: map['last_login'] != null
          ? DateTime.parse(map['last_login'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'role': role,
      'is_active': isActive ? 1 : 0,
      'last_login': lastLogin?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  // للعرض في الواجهة
  String get roleArabic {
    switch (role) {
      case 'admin':
        return 'مدير';
      case 'cashier':
        return 'كاشير';
      case 'pharmacist':
        return 'صيدلاني';
      default:
        return role;
    }
  }

  User copyWith({
    String? id,
    String? username,
    String? fullName,
    String? email,
    String? phone,
    String? role,
    bool? isActive,
    DateTime? lastLogin,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      lastLogin: lastLogin ?? this.lastLogin,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
