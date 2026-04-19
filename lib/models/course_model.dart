import 'package:cloud_firestore/cloud_firestore.dart';

class CourseModel {
  final String id;
  final String name;
  final String description;
  final String teacherId;
  final String teacherName;
  final List<String> studentIds;
  final String color;
  final String icon;
  final DateTime createdAt;

  const CourseModel({
    required this.id,
    required this.name,
    this.description = '',
    required this.teacherId,
    this.teacherName = '',
    this.studentIds = const [],
    this.color = '#0D1B2A',
    this.icon = 'book',
    required this.createdAt,
  });

  factory CourseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CourseModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      teacherId: data['teacherId'] ?? '',
      teacherName: data['teacherName'] ?? '',
      studentIds: List<String>.from(data['studentIds'] ?? []),
      color: data['color'] ?? '#0D1B2A',
      icon: data['icon'] ?? 'book',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory CourseModel.fromMap(Map<String, dynamic> data) {
    return CourseModel(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      teacherId: data['teacherId'] ?? '',
      teacherName: data['teacherName'] ?? '',
      studentIds: List<String>.from(data['studentIds'] ?? []),
      color: data['color'] ?? '#0D1B2A',
      icon: data['icon'] ?? 'book',
      createdAt: DateTime.tryParse(data['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'studentIds': studentIds,
      'color': color,
      'icon': icon,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'studentIds': studentIds,
      'color': color,
      'icon': icon,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
