import 'package:hive_flutter/hive_flutter.dart';
import '../core/constants/app_constants.dart';

class HiveService {
  static Future<void> init() async {
    await Hive.initFlutter();
    await _openBoxes();
  }

  static Future<void> _openBoxes() async {
    await Hive.openBox(AppConstants.userBox);
    await Hive.openBox(AppConstants.coursesBox);
    await Hive.openBox(AppConstants.assignmentsBox);
    await Hive.openBox(AppConstants.submissionsBox);
    await Hive.openBox(AppConstants.gradesBox);
    await Hive.openBox(AppConstants.attendanceBox);
    await Hive.openBox(AppConstants.notificationsBox);
    await Hive.openBox(AppConstants.messagesBox);
    await Hive.openBox(AppConstants.syncQueueBox);
    await Hive.openBox(AppConstants.settingsBox);
  }

  // ── Generic CRUD ──
  static Box _getBox(String boxName) => Hive.box(boxName);

  static Future<void> put(String boxName, String key, Map<String, dynamic> data) async {
    final box = _getBox(boxName);
    await box.put(key, data);
  }

  static Map<String, dynamic>? get(String boxName, String key) {
    final box = _getBox(boxName);
    final data = box.get(key);
    if (data == null) return null;
    return Map<String, dynamic>.from(data as Map);
  }

  static List<Map<String, dynamic>> getAll(String boxName) {
    final box = _getBox(boxName);
    return box.values
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  static Future<void> delete(String boxName, String key) async {
    final box = _getBox(boxName);
    await box.delete(key);
  }

  static Future<void> clearBox(String boxName) async {
    final box = _getBox(boxName);
    await box.clear();
  }

  // ── User ──
  static Future<void> saveUser(Map<String, dynamic> userData) async {
    await put(AppConstants.userBox, 'current_user', userData);
  }

  static Map<String, dynamic>? getCurrentUser() {
    return get(AppConstants.userBox, 'current_user');
  }

  static Future<void> clearUser() async {
    await delete(AppConstants.userBox, 'current_user');
  }

  // ── Sync Queue ──
  static Future<void> addToSyncQueue(Map<String, dynamic> operation) async {
    final box = _getBox(AppConstants.syncQueueBox);
    await box.add(operation);
  }

  static List<Map<String, dynamic>> getSyncQueue() {
    return getAll(AppConstants.syncQueueBox);
  }

  static Future<void> clearSyncQueue() async {
    await clearBox(AppConstants.syncQueueBox);
  }

  // ── Settings ──
  static Future<void> clearAll() async {
    final boxNames = [
      AppConstants.userBox,
      AppConstants.coursesBox,
      AppConstants.assignmentsBox,
      AppConstants.submissionsBox,
      AppConstants.gradesBox,
      AppConstants.attendanceBox,
      AppConstants.notificationsBox,
      AppConstants.messagesBox,
      AppConstants.syncQueueBox,
      AppConstants.settingsBox,
    ];
    for (final name in boxNames) {
      if (Hive.isBoxOpen(name)) {
        await Hive.box(name).clear();
      }
    }
  }

  static Future<void> saveSetting(String key, dynamic value) async {
    final box = _getBox(AppConstants.settingsBox);
    await box.put(key, value);
  }

  static dynamic getSetting(String key, {dynamic defaultValue}) {
    final box = _getBox(AppConstants.settingsBox);
    return box.get(key, defaultValue: defaultValue);
  }
}
