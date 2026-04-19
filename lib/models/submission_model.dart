import 'package:cloud_firestore/cloud_firestore.dart';

class SubmissionModel {
  final String id;
  final String assignmentId;
  final String studentId;
  final String studentName;
  final String courseId;
  final String status; // pending, submitted, graded, overdue
  final List<String> fileUrls;
  final String textAnswer;
  final List<int> quizAnswers;
  final double? score;
  final String feedback;
  final DateTime submittedAt;
  final DateTime? gradedAt;

  const SubmissionModel({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    this.studentName = '',
    required this.courseId,
    this.status = 'submitted',
    this.fileUrls = const [],
    this.textAnswer = '',
    this.quizAnswers = const [],
    this.score,
    this.feedback = '',
    required this.submittedAt,
    this.gradedAt,
  });

  bool get isGraded => status == 'graded';

  factory SubmissionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SubmissionModel(
      id: doc.id,
      assignmentId: data['assignmentId'] ?? '',
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      courseId: data['courseId'] ?? '',
      status: data['status'] ?? 'submitted',
      fileUrls: List<String>.from(data['fileUrls'] ?? []),
      textAnswer: data['textAnswer'] ?? '',
      quizAnswers: List<int>.from(data['quizAnswers'] ?? []),
      score: (data['score'] as num?)?.toDouble(),
      feedback: data['feedback'] ?? '',
      submittedAt: (data['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      gradedAt: (data['gradedAt'] as Timestamp?)?.toDate(),
    );
  }

  factory SubmissionModel.fromMap(Map<String, dynamic> data) {
    return SubmissionModel(
      id: data['id'] ?? '',
      assignmentId: data['assignmentId'] ?? '',
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      courseId: data['courseId'] ?? '',
      status: data['status'] ?? 'submitted',
      fileUrls: List<String>.from(data['fileUrls'] ?? []),
      textAnswer: data['textAnswer'] ?? '',
      quizAnswers: List<int>.from(data['quizAnswers'] ?? []),
      score: (data['score'] as num?)?.toDouble(),
      feedback: data['feedback'] ?? '',
      submittedAt: DateTime.tryParse(data['submittedAt']?.toString() ?? '') ?? DateTime.now(),
      gradedAt: data['gradedAt'] != null ? DateTime.tryParse(data['gradedAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'assignmentId': assignmentId,
      'studentId': studentId,
      'studentName': studentName,
      'courseId': courseId,
      'status': status,
      'fileUrls': fileUrls,
      'textAnswer': textAnswer,
      'quizAnswers': quizAnswers,
      'score': score,
      'feedback': feedback,
      'submittedAt': submittedAt.toIso8601String(),
      'gradedAt': gradedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'assignmentId': assignmentId,
      'studentId': studentId,
      'studentName': studentName,
      'courseId': courseId,
      'status': status,
      'fileUrls': fileUrls,
      'textAnswer': textAnswer,
      'quizAnswers': quizAnswers,
      'score': score,
      'feedback': feedback,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'gradedAt': gradedAt != null ? Timestamp.fromDate(gradedAt!) : null,
    };
  }
}
