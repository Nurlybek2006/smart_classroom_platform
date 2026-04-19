import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceModel {
  final String id;
  final String studentId;
  final String studentName;
  final String courseId;
  final String courseName;
  final DateTime date;
  final bool isPresent;

  const AttendanceModel({
    required this.id,
    required this.studentId,
    this.studentName = '',
    required this.courseId,
    this.courseName = '',
    required this.date,
    required this.isPresent,
  });

  factory AttendanceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AttendanceModel(
      id: doc.id,
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      courseId: data['courseId'] ?? '',
      courseName: data['courseName'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isPresent: data['isPresent'] ?? false,
    );
  }

  factory AttendanceModel.fromMap(Map<String, dynamic> data) {
    return AttendanceModel(
      id: data['id'] ?? '',
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      courseId: data['courseId'] ?? '',
      courseName: data['courseName'] ?? '',
      date: DateTime.tryParse(data['date']?.toString() ?? '') ?? DateTime.now(),
      isPresent: data['isPresent'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'courseId': courseId,
      'courseName': courseName,
      'date': date.toIso8601String(),
      'isPresent': isPresent,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'courseId': courseId,
      'courseName': courseName,
      'date': Timestamp.fromDate(date),
      'isPresent': isPresent,
    };
  }
}
