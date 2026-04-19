import 'package:cloud_firestore/cloud_firestore.dart';

class GradeModel {
  final String id;
  final String studentId;
  final String courseId;
  final String courseName;
  final String assignmentId;
  final String assignmentTitle;
  final double score;
  final double maxScore;
  final DateTime gradedAt;

  const GradeModel({
    required this.id,
    required this.studentId,
    required this.courseId,
    this.courseName = '',
    required this.assignmentId,
    this.assignmentTitle = '',
    required this.score,
    this.maxScore = 100,
    required this.gradedAt,
  });

  double get percentage => maxScore > 0 ? (score / maxScore) * 100 : 0;

  String get letterGrade {
    final pct = percentage;
    if (pct >= 90) return 'A';
    if (pct >= 80) return 'B';
    if (pct >= 70) return 'C';
    if (pct >= 60) return 'D';
    return 'F';
  }

  factory GradeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GradeModel(
      id: doc.id,
      studentId: data['studentId'] ?? '',
      courseId: data['courseId'] ?? '',
      courseName: data['courseName'] ?? '',
      assignmentId: data['assignmentId'] ?? '',
      assignmentTitle: data['assignmentTitle'] ?? '',
      score: (data['score'] as num?)?.toDouble() ?? 0,
      maxScore: (data['maxScore'] as num?)?.toDouble() ?? 100,
      gradedAt: (data['gradedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory GradeModel.fromMap(Map<String, dynamic> data) {
    return GradeModel(
      id: data['id'] ?? '',
      studentId: data['studentId'] ?? '',
      courseId: data['courseId'] ?? '',
      courseName: data['courseName'] ?? '',
      assignmentId: data['assignmentId'] ?? '',
      assignmentTitle: data['assignmentTitle'] ?? '',
      score: (data['score'] as num?)?.toDouble() ?? 0,
      maxScore: (data['maxScore'] as num?)?.toDouble() ?? 100,
      gradedAt: DateTime.tryParse(data['gradedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'courseId': courseId,
      'courseName': courseName,
      'assignmentId': assignmentId,
      'assignmentTitle': assignmentTitle,
      'score': score,
      'maxScore': maxScore,
      'gradedAt': gradedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'studentId': studentId,
      'courseId': courseId,
      'courseName': courseName,
      'assignmentId': assignmentId,
      'assignmentTitle': assignmentTitle,
      'score': score,
      'maxScore': maxScore,
      'gradedAt': Timestamp.fromDate(gradedAt),
    };
  }
}
