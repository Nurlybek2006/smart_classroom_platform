class AppConstants {
  AppConstants._();

  // Firestore Collections
  static const String usersCollection = 'users';
  static const String coursesCollection = 'courses';
  static const String assignmentsCollection = 'assignments';
  static const String submissionsCollection = 'submissions';
  static const String gradesCollection = 'grades';
  static const String attendanceCollection = 'attendance';
  static const String notificationsCollection = 'notifications';
  static const String messagesCollection = 'messages';
  static const String analyticsCollection = 'analytics';
  static const String quizQuestionsCollection = 'quiz_questions';

  // Hive Boxes
  static const String userBox = 'user_box';
  static const String coursesBox = 'courses_box';
  static const String assignmentsBox = 'assignments_box';
  static const String submissionsBox = 'submissions_box';
  static const String gradesBox = 'grades_box';
  static const String attendanceBox = 'attendance_box';
  static const String notificationsBox = 'notifications_box';
  static const String messagesBox = 'messages_box';
  static const String syncQueueBox = 'sync_queue_box';
  static const String settingsBox = 'settings_box';

  // User Roles
  static const String roleTeacher = 'teacher';
  static const String roleStudent = 'student';

  // Assignment Types
  static const String typeHomework = 'homework';
  static const String typeQuiz = 'quiz';
  static const String typeTest = 'test';
  static const String typeProject = 'project';

  // Submission Status
  static const String statusPending = 'pending';
  static const String statusSubmitted = 'submitted';
  static const String statusGraded = 'graded';
  static const String statusOverdue = 'overdue';

  // Risk Thresholds
  static const double riskGradeThreshold = 50.0;
  static const double riskAttendanceThreshold = 70.0;
  static const int riskMissedAssignmentThreshold = 3;

  // Animation Durations
  static const int splashDuration = 3;
  static const int animationDuration = 300;
  static const int pageTransitionDuration = 400;

  // Pagination
  static const int pageSize = 20;

  // File Upload
  static const int maxFileSizeMB = 25;
  static const List<String> allowedFileTypes = [
    'pdf', 'doc', 'docx', 'png', 'jpg', 'jpeg', 'txt',
  ];
}
