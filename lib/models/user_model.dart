import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final String role;
  final String faculty;
  final String group;
  final String avatarUrl;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.role,
    this.faculty = '',
    this.group = '',
    this.avatarUrl = '',
    required this.createdAt,
  });

  bool get isTeacher => role == 'teacher';
  bool get isStudent => role == 'student';

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'student',
      faculty: data['faculty'] ?? '',
      group: data['group'] ?? '',
      avatarUrl: data['avatarUrl'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] ?? '',
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'student',
      faculty: data['faculty'] ?? '',
      group: data['group'] ?? '',
      avatarUrl: data['avatarUrl'] ?? '',
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(data['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'role': role,
      'faculty': faculty,
      'group': group,
      'avatarUrl': avatarUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'fullName': fullName,
      'email': email,
      'role': role,
      'faculty': faculty,
      'group': group,
      'avatarUrl': avatarUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  UserModel copyWith({
    String? uid,
    String? fullName,
    String? email,
    String? role,
    String? faculty,
    String? group,
    String? avatarUrl,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      faculty: faculty ?? this.faculty,
      group: group ?? this.group,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
