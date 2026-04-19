import 'package:flutter/material.dart';
import '../models/course_model.dart';
import '../models/assignment_model.dart';
import '../models/submission_model.dart';
import '../models/grade_model.dart';
import '../models/attendance_model.dart';
import '../models/notification_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/hive_service.dart';
import '../core/constants/app_constants.dart';
import 'dart:async';

class DataProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<CourseModel> _courses = [];
  List<AssignmentModel> _assignments = [];
  List<SubmissionModel> _submissions = [];
  List<GradeModel> _grades = [];
  List<AttendanceModel> _attendance = [];
  List<NotificationModel> _notifications = [];
  List<MessageModel> _messages = [];
  List<UserModel> _students = [];
  bool _isLoading = false;

  List<CourseModel> get courses => _courses;
  List<AssignmentModel> get assignments => _assignments;
  List<SubmissionModel> get submissions => _submissions;
  List<GradeModel> get grades => _grades;
  List<AttendanceModel> get attendance => _attendance;
  List<NotificationModel> get notifications => _notifications;
  List<MessageModel> get messages => _messages;
  List<UserModel> get students => _students;
  bool get isLoading => _isLoading;

  int get unreadNotifications => _notifications.where((n) => !n.isRead).length;

  final List<StreamSubscription> _subscriptions = [];

  void loadTeacherData(String teacherId) {
    _isLoading = true;
    notifyListeners();

    _subscriptions.add(
      _firestoreService.getCoursesByTeacher(teacherId).listen((data) {
        _courses = data;
        _cacheList(AppConstants.coursesBox, data.map((e) => e.toMap()).toList());
        notifyListeners();
      }),
    );

    _subscriptions.add(
      _firestoreService.getAssignmentsByTeacher(teacherId).listen((data) {
        _assignments = data;
        _cacheList(AppConstants.assignmentsBox, data.map((e) => e.toMap()).toList());
        notifyListeners();
      }),
    );

    _subscriptions.add(
      _firestoreService.getStudents().listen((data) {
        _students = data;
        notifyListeners();
      }),
    );

    _subscriptions.add(
      _firestoreService.getNotifications(teacherId).listen((data) {
        _notifications = data;
        notifyListeners();
      }),
    );

    _isLoading = false;
    notifyListeners();
  }

  void loadStudentData(String studentId, List<String> courseIds) {
    _isLoading = true;
    notifyListeners();

    _subscriptions.add(
      _firestoreService.getCoursesByStudent(studentId).listen((data) {
        _courses = data;
        _cacheList(AppConstants.coursesBox, data.map((e) => e.toMap()).toList());

        // Load assignments for student's courses
        final ids = data.map((c) => c.id).toList();
        if (ids.isNotEmpty) {
          _subscriptions.add(
            _firestoreService.getAssignmentsForStudent(ids).listen((assignments) {
              _assignments = assignments;
              _cacheList(AppConstants.assignmentsBox, assignments.map((e) => e.toMap()).toList());
              notifyListeners();
            }),
          );
        }

        notifyListeners();
      }),
    );

    _subscriptions.add(
      _firestoreService.getGradesByStudent(studentId).listen((data) {
        _grades = data;
        _cacheList(AppConstants.gradesBox, data.map((e) => e.toMap()).toList());
        notifyListeners();
      }),
    );

    _subscriptions.add(
      _firestoreService.getSubmissionsByStudent(studentId).listen((data) {
        _submissions = data;
        notifyListeners();
      }),
    );

    _subscriptions.add(
      _firestoreService.getAttendanceByStudent(studentId).listen((data) {
        _attendance = data;
        notifyListeners();
      }),
    );

    _subscriptions.add(
      _firestoreService.getNotifications(studentId).listen((data) {
        _notifications = data;
        notifyListeners();
      }),
    );

    _isLoading = false;
    notifyListeners();
  }

  // ── Assignment Actions ──
  Future<void> createAssignment(AssignmentModel assignment) async {
    await _firestoreService.createAssignment(assignment);
  }

  Future<void> submitAssignment(SubmissionModel submission) async {
    await _firestoreService.createSubmission(submission);
  }

  Future<void> gradeSubmission(String submissionId, double score, String feedback) async {
    await _firestoreService.gradeSubmission(submissionId, score, feedback);
  }

  // ── Grade Actions ──
  Future<void> createGrade(GradeModel grade) async {
    await _firestoreService.createGrade(grade);
  }

  // ── Course Actions ──
  Future<String> createCourse(CourseModel course) async {
    return await _firestoreService.createCourse(course);
  }

  Future<void> updateCourse(CourseModel course) async {
    await _firestoreService.updateCourse(course);
  }

  Future<void> deleteCourse(String courseId) async {
    await _firestoreService.deleteCourse(courseId);
  }

  Future<void> addStudentToCourse(String courseId, String studentId) async {
    await _firestoreService.addStudentToCourse(courseId, studentId);
  }

  Future<void> removeStudentFromCourse(String courseId, String studentId) async {
    await _firestoreService.removeStudentFromCourse(courseId, studentId);
  }

  // ── Student Actions ──
  Future<void> deleteStudent(String uid) async {
    await _firestoreService.deleteUserDocument(uid);
    for (final course in _courses) {
      if (course.studentIds.contains(uid)) {
        await _firestoreService.removeStudentFromCourse(course.id, uid);
      }
    }
  }

  Future<void> updateStudentInfo(UserModel updated) async {
    await _firestoreService.updateUser(updated);
  }

  Future<void> deleteAssignment(String assignmentId) async {
    await _firestoreService.deleteAssignment(assignmentId);
  }

  Future<void> markAttendance(AttendanceModel attendance) async {
    await _firestoreService.markAttendance(attendance);
  }

  void loadAttendanceByCourse(String courseId) {
    _subscriptions.add(
      _firestoreService.getAttendanceByCourse(courseId).listen((data) {
        _attendance = data;
        notifyListeners();
      }),
    );
  }

  // ── Message Actions ──
  void loadMessages(String chatId) {
    _subscriptions.add(
      _firestoreService.getMessages(chatId).listen((data) {
        _messages = data;
        notifyListeners();
      }),
    );
  }

  Future<void> sendMessage(MessageModel message) async {
    await _firestoreService.sendMessage(message);
  }

  Future<void> markMessagesAsRead(String chatId, String userId) async {
    await _firestoreService.markMessagesAsRead(chatId, userId);
  }

  // ── Notification Actions ──
  Future<void> markNotificationAsRead(String id) async {
    await _firestoreService.markNotificationAsRead(id);
  }

  Future<void> createNotification(NotificationModel notification) async {
    await _firestoreService.createNotification(notification);
  }

  // ── Submissions by Assignment ──
  void loadSubmissionsByAssignment(String assignmentId) {
    _subscriptions.add(
      _firestoreService.getSubmissionsByAssignment(assignmentId).listen((data) {
        _submissions = data;
        notifyListeners();
      }),
    );
  }

  // ── Cache helpers ──
  void _cacheList(String boxName, List<Map<String, dynamic>> items) {
    for (final item in items) {
      final id = item['id'] as String?;
      if (id != null) {
        HiveService.put(boxName, id, item);
      }
    }
  }

  // ── Analytics helpers ──
  double get averageGrade {
    if (_grades.isEmpty) return 0;
    final total = _grades.fold<double>(0, (sum, g) => sum + g.percentage);
    return total / _grades.length;
  }

  double get gpa {
    if (_grades.isEmpty) return 0;
    final avg = averageGrade;
    return (avg / 100) * 4.0;
  }

  double get attendanceRate {
    if (_attendance.isEmpty) return 0;
    final present = _attendance.where((a) => a.isPresent).length;
    return (present / _attendance.length) * 100;
  }

  int get missedAssignmentCount {
    return _assignments.where((a) {
      final hasSubmission = _submissions.any((s) => s.assignmentId == a.id);
      return a.isOverdue && !hasSubmission;
    }).length;
  }

  List<AssignmentModel> get upcomingAssignments {
    final now = DateTime.now();
    return _assignments
        .where((a) => a.deadline.isAfter(now))
        .toList()
      ..sort((a, b) => a.deadline.compareTo(b.deadline));
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    super.dispose();
  }
}
