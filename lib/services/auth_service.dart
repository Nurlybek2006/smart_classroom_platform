import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../core/constants/app_constants.dart';

class AuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  bool get isFirebaseAvailable {
    try {
      Firebase.app();
      return true;
    } catch (_) {
      return false;
    }
  }

  User? get currentUser => isFirebaseAvailable ? _auth.currentUser : null;
  Stream<User?> get authStateChanges =>
      isFirebaseAvailable ? _auth.authStateChanges() : const Stream.empty();

  Future<UserModel?> signIn(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (credential.user == null) return null;
    return getUserData(credential.user!.uid);
  }

  Future<UserModel?> getUserData(String uid) async {
    final doc = await _firestore.collection(AppConstants.usersCollection).doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Creates a student account without signing out the current teacher.
  /// Uses a secondary Firebase App instance.
  Future<UserModel> createStudentAccount({
    required String email,
    required String password,
    required String fullName,
    String faculty = '',
    String group = '',
  }) async {
    FirebaseApp secondaryApp;
    try {
      secondaryApp = Firebase.app('secondary');
    } catch (_) {
      secondaryApp = await Firebase.initializeApp(
        name: 'secondary',
        options: Firebase.app().options,
      );
    }

    final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
    final cred = await secondaryAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = cred.user!.uid;
    final student = UserModel(
      uid: uid,
      fullName: fullName,
      email: email,
      role: AppConstants.roleStudent,
      faculty: faculty,
      group: group,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .set(student.toFirestore());

    await secondaryAuth.signOut();

    return student;
  }
}
