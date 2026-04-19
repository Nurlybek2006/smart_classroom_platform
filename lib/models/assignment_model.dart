import 'package:cloud_firestore/cloud_firestore.dart';

class AssignmentModel {
  final String id;
  final String title;
  final String description;
  final String courseId;
  final String courseName;
  final String teacherId;
  final String type; // homework, quiz, test, project
  final DateTime deadline;
  final DateTime createdAt;
  final List<String> attachmentUrls;
  final List<QuizQuestion> quizQuestions;
  final int maxScore;

  const AssignmentModel({
    required this.id,
    required this.title,
    this.description = '',
    required this.courseId,
    this.courseName = '',
    required this.teacherId,
    required this.type,
    required this.deadline,
    required this.createdAt,
    this.attachmentUrls = const [],
    this.quizQuestions = const [],
    this.maxScore = 100,
  });

  bool get isOverdue => DateTime.now().isAfter(deadline);
  bool get isQuiz => type == 'quiz';

  factory AssignmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AssignmentModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      courseId: data['courseId'] ?? '',
      courseName: data['courseName'] ?? '',
      teacherId: data['teacherId'] ?? '',
      type: data['type'] ?? 'homework',
      deadline: (data['deadline'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      attachmentUrls: List<String>.from(data['attachmentUrls'] ?? []),
      quizQuestions: (data['quizQuestions'] as List<dynamic>?)
              ?.map((q) => QuizQuestion.fromMap(q as Map<String, dynamic>))
              .toList() ??
          [],
      maxScore: data['maxScore'] ?? 100,
    );
  }

  factory AssignmentModel.fromMap(Map<String, dynamic> data) {
    return AssignmentModel(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      courseId: data['courseId'] ?? '',
      courseName: data['courseName'] ?? '',
      teacherId: data['teacherId'] ?? '',
      type: data['type'] ?? 'homework',
      deadline: DateTime.tryParse(data['deadline']?.toString() ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(data['createdAt']?.toString() ?? '') ?? DateTime.now(),
      attachmentUrls: List<String>.from(data['attachmentUrls'] ?? []),
      quizQuestions: (data['quizQuestions'] as List<dynamic>?)
              ?.map((q) => QuizQuestion.fromMap(q as Map<String, dynamic>))
              .toList() ??
          [],
      maxScore: data['maxScore'] ?? 100,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'courseId': courseId,
      'courseName': courseName,
      'teacherId': teacherId,
      'type': type,
      'deadline': deadline.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'attachmentUrls': attachmentUrls,
      'quizQuestions': quizQuestions.map((q) => q.toMap()).toList(),
      'maxScore': maxScore,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'courseId': courseId,
      'courseName': courseName,
      'teacherId': teacherId,
      'type': type,
      'deadline': Timestamp.fromDate(deadline),
      'createdAt': Timestamp.fromDate(createdAt),
      'attachmentUrls': attachmentUrls,
      'quizQuestions': quizQuestions.map((q) => q.toMap()).toList(),
      'maxScore': maxScore,
    };
  }
}

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;

  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
  });

  factory QuizQuestion.fromMap(Map<String, dynamic> data) {
    return QuizQuestion(
      question: data['question'] ?? '',
      options: List<String>.from(data['options'] ?? []),
      correctIndex: data['correctIndex'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'options': options,
      'correctIndex': correctIndex,
    };
  }
}
