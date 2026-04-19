import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/hive_service.dart';
import '../services/sync_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final SyncService _syncService = SyncService();

  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get isTeacher => _user?.isTeacher ?? false;
  bool get isStudent => _user?.isStudent ?? false;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Check if user is already logged in
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        await _loadUserData(currentUser.uid);
      } else {
        // Try loading from Hive cache
        final cached = HiveService.getCurrentUser();
        if (cached != null) {
          _user = UserModel.fromMap(cached);
        }
      }
    } catch (e) {
      // Firebase not available - try cache
      final cached = HiveService.getCurrentUser();
      if (cached != null) {
        _user = UserModel.fromMap(cached);
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadUserData(String uid) async {
    try {
      _user = await _authService.getUserData(uid);
      if (_user != null) {
        await HiveService.saveUser(_user!.toMap());
        _syncService.startListening();
        await _syncService.cacheUserData(uid);
      }
    } catch (e) {
      // Offline - load from cache
      final cached = HiveService.getCurrentUser();
      if (cached != null) {
        _user = UserModel.fromMap(cached);
      }
    }
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authService.signIn(email, password);
      if (_user != null) {
        await HiveService.saveUser(_user!.toMap());
        _syncService.startListening();
        await _syncService.cacheUserData(_user!.uid);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Пайдаланушы деректері табылмады';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          _error = 'Пайдаланушы табылмады';
          break;
        case 'wrong-password':
          _error = 'Құпия сөз дұрыс емес';
          break;
        case 'invalid-email':
          _error = 'Электрондық пошта дұрыс емес';
          break;
        case 'user-disabled':
          _error = 'Аккаунт блокталған';
          break;
        default:
          _error = 'Кіру қатесі: ${e.message}';
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Қате: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    await HiveService.clearUser();
    _syncService.stopListening();
    _user = null;
    notifyListeners();
  }

  Future<void> createStudent({
    required String email,
    required String password,
    required String fullName,
    String faculty = '',
    String group = '',
  }) async {
    await _authService.createStudentAccount(
      email: email,
      password: password,
      fullName: fullName,
      faculty: faculty,
      group: group,
    );
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
