import 'dart:convert';

class User {
  // For Registration
  final String? name;
  final String email;
  final String? phone;
  final String password;
  final String passwordConfirm;

  // For Login Response
  final Staff? staff;
  final String? profilePicture; // ✅ Profile picture field
  final Map<String, dynamic>? userProfile;
  final String? token;

  User({
    this.name,
    required this.email,
    this.phone,
    required this.password,
    required this.passwordConfirm,
    this.staff,
    this.profilePicture, // ✅ No 'final' here
    this.userProfile,
    this.token,
  });

  Map<String, dynamic> toMap() {
    return {
      'username': name,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirm,
    };
  }

  String toJson() => json.encode(toMap());

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      email: json['staff']?['email'] ?? '',
      password: '',
      passwordConfirm: '',
      staff: json['staff'] != null ? Staff.fromJson(json['staff']) : null,
      profilePicture: json['user']?['profile_picture'],
      userProfile: json['user_profile'],
      token: json['token'],
    );
  }
}


class Staff {
  final int staffId;
  final int roleId;
  final String username;
  final String email;
  final bool isLocked;
  final DateTime createdAt;
  final DateTime updatedAt;

  Staff({
    required this.staffId,
    required this.roleId,
    required this.username,
    required this.email,
    required this.isLocked,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Staff.fromJson(Map<String, dynamic> json) {
    return Staff(
      staffId: json['staff_id'],
      roleId: json['role_id'],
      username: json['username'],
      email: json['email'],
      isLocked: json['is_locked'] == 1, // Convert to boolean
      createdAt: DateTime.parse(json['created_at']), // Parse DateTime
      updatedAt: DateTime.parse(json['updated_at']), // Parse DateTime
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'staff_id': staffId,
      'role_id': roleId,
      'username': username,
      'email': email,
      'is_locked': isLocked ? 1 : 0, // Convert boolean to int
      'created_at': createdAt.toIso8601String(), // Convert DateTime to String
      'updated_at': updatedAt.toIso8601String(), // Convert DateTime to String
    };
  }
}