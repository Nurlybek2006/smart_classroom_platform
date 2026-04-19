import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/course_model.dart';
import '../models/assignment_model.dart';
import '../models/submission_model.dart';
import '../models/grade_model.dart';
import '../models/message_model.dart';
import '../models/notification_model.dart';
import '../models/attendance_model.dart';
import '../core/constants/app_constants.dart';

class FirestoreService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  // ── Users ──
  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection(AppConstants.usersCollection).doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Stream<List<UserModel>> getStudents() {
    return _db
        .collection(AppConstants.usersCollection)
        .where('role', isEqualTo: AppConstants.roleStudent)
        .snapshots()
        .map((s) => s.docs.map((d) => UserModel.fromFirestore(d)).toList());
  }

  Stream<List<UserModel>> getTeachers() {
    return _db
        .collection(AppConstants.usersCollection)
        .where('role', isEqualTo: AppConstants.roleTeacher)
        .snapshots()
        .map((s) => s.docs.map((d) => UserModel.fromFirestore(d)).toList());
  }

  Future<void> updateUser(UserModel user) async {
    await _db.collection(AppConstants.usersCollection).doc(user.uid).set(
          user.toFirestore(),
          SetOptions(merge: true),
        );
  }

  // ── Courses ──
  Stream<List<CourseModel>> getCoursesByTeacher(String teacherId) {
    return _db
        .collection(AppConstants.coursesCollection)
        .where('teacherId', isEqualTo: teacherId)
        .snapshots()
        .map((s) => s.docs.map((d) => CourseModel.fromFirestore(d)).toList());
  }

  Stream<List<CourseModel>> getCoursesByStudent(String studentId) {
    return _db
        .collection(AppConstants.coursesCollection)
        .where('studentIds', arrayContains: studentId)
        .snapshots()
        .map((s) => s.docs.map((d) => CourseModel.fromFirestore(d)).toList());
  }

  Future<String> createCourse(CourseModel course) async {
    final doc = await _db.collection(AppConstants.coursesCollection).add(course.toFirestore());
    return doc.id;
  }

  Future<void> updateCourse(CourseModel course) async {
    await _db.collection(AppConstants.coursesCollection).doc(course.id).update(course.toFirestore());
  }

  Future<void> deleteCourse(String courseId) async {
    await _db.collection(AppConstants.coursesCollection).doc(courseId).delete();
  }

  Future<void> addStudentToCourse(String courseId, String studentId) async {
    await _db.collection(AppConstants.coursesCollection).doc(courseId).update({
      'studentIds': FieldValue.arrayUnion([studentId]),
    });
  }

  Future<void> removeStudentFromCourse(String courseId, String studentId) async {
    await _db.collection(AppConstants.coursesCollection).doc(courseId).update({
      'studentIds': FieldValue.arrayRemove([studentId]),
    });
  }

  Future<void> deleteUserDocument(String uid) async {
    await _db.collection(AppConstants.usersCollection).doc(uid).delete();
  }

  Future<void> updateAssignment(AssignmentModel assignment) async {
    await _db.collection(AppConstants.assignmentsCollection).doc(assignment.id).update(assignment.toFirestore());
  }

  Future<void> deleteAssignment(String assignmentId) async {
    await _db.collection(AppConstants.assignmentsCollection).doc(assignmentId).delete();
  }

  // ── Assignments ──
  Stream<List<AssignmentModel>> getAssignmentsByTeacher(String teacherId) {
    return _db
        .collection(AppConstants.assignmentsCollection)
        .where('teacherId', isEqualTo: teacherId)
        .snapshots()
        .map((s) {
          final list = s.docs.map((d) => AssignmentModel.fromFirestore(d)).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Stream<List<AssignmentModel>> getAssignmentsByCourse(String courseId) {
    return _db
        .collection(AppConstants.assignmentsCollection)
        .where('courseId', isEqualTo: courseId)
        .snapshots()
        .map((s) {
          final list = s.docs.map((d) => AssignmentModel.fromFirestore(d)).toList();
          list.sort((a, b) => a.deadline.compareTo(b.deadline));
          return list;
        });
  }

  Stream<List<AssignmentModel>> getAssignmentsForStudent(List<String> courseIds) {
    if (courseIds.isEmpty) return Stream.value([]);
    return _db
        .collection(AppConstants.assignmentsCollection)
        .where('courseId', whereIn: courseIds.take(10).toList())
        .orderBy('deadline')
        .snapshots()
        .map((s) => s.docs.map((d) => AssignmentModel.fromFirestore(d)).toList());
  }

  Future<String> createAssignment(AssignmentModel assignment) async {
    final doc = await _db.collection(AppConstants.assignmentsCollection).add(assignment.toFirestore());
    return doc.id;
  }

  // ── Submissions ──
  Stream<List<SubmissionModel>> getSubmissionsByAssignment(String assignmentId) {
    return _db
        .collection(AppConstants.submissionsCollection)
        .where('assignmentId', isEqualTo: assignmentId)
        .snapshots()
        .map((s) => s.docs.map((d) => SubmissionModel.fromFirestore(d)).toList());
  }

  Stream<List<SubmissionModel>> getSubmissionsByStudent(String studentId) {
    return _db
        .collection(AppConstants.submissionsCollection)
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((s) {
          final list = s.docs.map((d) => SubmissionModel.fromFirestore(d)).toList();
          list.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
          return list;
        });
  }

  Future<String> createSubmission(SubmissionModel submission) async {
    final doc = await _db.collection(AppConstants.submissionsCollection).add(submission.toFirestore());
    return doc.id;
  }

  Future<void> gradeSubmission(String submissionId, double score, String feedback) async {
    await _db.collection(AppConstants.submissionsCollection).doc(submissionId).update({
      'score': score,
      'feedback': feedback,
      'status': AppConstants.statusGraded,
      'gradedAt': Timestamp.now(),
    });
  }

  // ── Grades ──
  Stream<List<GradeModel>> getGradesByStudent(String studentId) {
    return _db
        .collection(AppConstants.gradesCollection)
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((s) {
          final list = s.docs.map((d) => GradeModel.fromFirestore(d)).toList();
          list.sort((a, b) => b.gradedAt.compareTo(a.gradedAt));
          return list;
        });
  }

  Stream<List<GradeModel>> getGradesByCourse(String courseId) {
    return _db
        .collection(AppConstants.gradesCollection)
        .where('courseId', isEqualTo: courseId)
        .snapshots()
        .map((s) => s.docs.map((d) => GradeModel.fromFirestore(d)).toList());
  }

  Future<void> createGrade(GradeModel grade) async {
    await _db.collection(AppConstants.gradesCollection).add(grade.toFirestore());
  }

  // ── Attendance ──
  Stream<List<AttendanceModel>> getAttendanceByCourse(String courseId) {
    return _db
        .collection(AppConstants.attendanceCollection)
        .where('courseId', isEqualTo: courseId)
        .snapshots()
        .map((s) {
          final list = s.docs.map((d) => AttendanceModel.fromFirestore(d)).toList();
          list.sort((a, b) => b.date.compareTo(a.date));
          return list;
        });
  }

  Stream<List<AttendanceModel>> getAttendanceByStudent(String studentId) {
    return _db
        .collection(AppConstants.attendanceCollection)
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((s) {
          final list = s.docs.map((d) => AttendanceModel.fromFirestore(d)).toList();
          list.sort((a, b) => b.date.compareTo(a.date));
          return list;
        });
  }

  Future<void> markAttendance(AttendanceModel attendance) async {
    await _db.collection(AppConstants.attendanceCollection).add(attendance.toFirestore());
  }

  // ── Messages ──
  Stream<List<MessageModel>> getMessages(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((s) => s.docs.map((d) {
              final data = d.data();
              return MessageModel(
                id: d.id,
                senderId: data['senderId'] ?? '',
                senderName: data['senderName'] ?? '',
                receiverId: data['receiverId'] ?? '',
                chatId: chatId,
                text: data['text'] ?? '',
                timestamp: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                isRead: data['isRead'] ?? false,
              );
            }).toList());
  }

  Future<void> sendMessage(MessageModel message) async {
    final chatRef = _db.collection('chats').doc(message.chatId);
    await chatRef.collection('messages').add({
      'senderId': message.senderId,
      'senderName': message.senderName,
      'receiverId': message.receiverId,
      'text': message.text,
      'createdAt': Timestamp.fromDate(message.timestamp),
      'isRead': false,
    });
    await chatRef.set({
      'participants': [message.senderId, message.receiverId],
      'lastMessage': message.text,
      'lastMessageAt': Timestamp.fromDate(message.timestamp),
      'lastSenderId': message.senderId,
      'names': {
        message.senderId: message.senderName,
      },
    }, SetOptions(merge: true));
  }

  Future<void> markMessagesAsRead(String chatId, String userId) async {
    final batch = _db.batch();
    final unread = await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('receiverId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Stream<QuerySnapshot> getChatsByUser(String userId) {
    return _db
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots();
  }

  Stream<List<UserModel>> getUsersByRole(String role) {
    return _db
        .collection(AppConstants.usersCollection)
        .where('role', isEqualTo: role)
        .snapshots()
        .map((s) => s.docs.map((d) => UserModel.fromFirestore(d)).toList());
  }

  Stream<int> getUnreadMessageCount(String userId) {
    return _db
        .collection('chats')
        .where('participants', arrayContains: userId)
        .snapshots()
        .asyncMap((chatsSnap) async {
          int count = 0;
          for (final chat in chatsSnap.docs) {
            final unread = await chat.reference
                .collection('messages')
                .where('receiverId', isEqualTo: userId)
                .where('isRead', isEqualTo: false)
                .count()
                .get();
            count += unread.count ?? 0;
          }
          return count;
        });
  }

  // ── Notifications ──
  Stream<List<NotificationModel>> getNotifications(String userId) {
    return _db
        .collection(AppConstants.notificationsCollection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((s) {
          final list = s.docs.map((d) => NotificationModel.fromFirestore(d)).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Future<void> createNotification(NotificationModel notification) async {
    await _db.collection(AppConstants.notificationsCollection).add(notification.toFirestore());
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await _db.collection(AppConstants.notificationsCollection).doc(notificationId).update({
      'isRead': true,
    });
  }

  Stream<int> getUnreadNotificationCount(String userId) {
    return _db
        .collection(AppConstants.notificationsCollection)
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((s) => s.docs.length);
  }
}
