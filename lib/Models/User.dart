import 'dart:convert';

class User {
  // For Registration
  final String? name; // Represents 'username' in the backend
  final String email;
  final String? phone;
  final String password;
  final String passwordConfirm;

  // For Login Response
  final Staff? staff;
  final Map<String, dynamic>? userProfile;
  final String? token;

  User({
    // Registration fields
    this.name,
    required this.email,
    this.phone,
    required this.password,
    required this.passwordConfirm,

    // Login fields
    this.staff,
    this.userProfile,
    this.token,
  });

  // Convert to JSON for API requests (Registration)
  Map<String, dynamic> toMap() {
    return {
      'username': name, // Maps to 'username' in the Staff table
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirm, // Match Laravel's expected key
    };
  }

  String toJson() => json.encode(toMap());

  // Parse JSON from API responses (Login)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      email: json['staff']?['email'] ?? '', // Fallback for registration
      password: '', // Not needed for login response
      passwordConfirm: '', // Not needed for login response
      staff: json['staff'] != null ? Staff.fromJson(json['staff']) : null,
      userProfile: json['user_profile'], // Ensure this matches the API response
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