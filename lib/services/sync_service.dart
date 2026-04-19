import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'hive_service.dart';
import '../core/constants/app_constants.dart';

class SyncService {
  final Connectivity _connectivity = Connectivity();
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isSyncing = false;

  void startListening() {
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      if (hasConnection && !_isSyncing) {
        syncPendingData();
      }
    });
  }

  void stopListening() {
    _subscription?.cancel();
  }

  Future<bool> isOnline() async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  Future<void> syncPendingData() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final queue = HiveService.getSyncQueue();
      if (queue.isEmpty) return;

      for (final operation in queue) {
        try {
          final type = operation['type'] as String?;
          final collection = operation['collection'] as String?;
          final data = Map<String, dynamic>.from(operation['data'] as Map? ?? {});
          final docId = operation['docId'] as String?;

          if (collection == null) continue;

          switch (type) {
            case 'create':
              if (docId != null) {
                await _db.collection(collection).doc(docId).set(data);
              } else {
                await _db.collection(collection).add(data);
              }
              break;
            case 'update':
              if (docId != null) {
                await _db.collection(collection).doc(docId).update(data);
              }
              break;
            case 'delete':
              if (docId != null) {
                await _db.collection(collection).doc(docId).delete();
              }
              break;
          }
        } catch (_) {
          // Individual operation failed, will retry next sync
        }
      }

      await HiveService.clearSyncQueue();
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> queueOperation({
    required String type,
    required String collection,
    required Map<String, dynamic> data,
    String? docId,
  }) async {
    final online = await isOnline();
    if (online) {
      // Execute directly
      switch (type) {
        case 'create':
          if (docId != null) {
            await _db.collection(collection).doc(docId).set(data);
          } else {
            await _db.collection(collection).add(data);
          }
          break;
        case 'update':
          if (docId != null) {
            await _db.collection(collection).doc(docId).update(data);
          }
          break;
        case 'delete':
          if (docId != null) {
            await _db.collection(collection).doc(docId).delete();
          }
          break;
      }
    } else {
      // Queue for later
      await HiveService.addToSyncQueue({
        'type': type,
        'collection': collection,
        'data': data,
        'docId': docId,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  // Cache Firestore data to Hive
  Future<void> cacheCollection(String collection, String hiveBox) async {
    try {
      final snapshot = await _db.collection(collection).get();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        await HiveService.put(hiveBox, doc.id, data);
      }
    } catch (_) {
      // Offline - use cached data
    }
  }

  Future<void> cacheUserData(String userId) async {
    await cacheCollection(
      AppConstants.coursesCollection,
      AppConstants.coursesBox,
    );
    await cacheCollection(
      AppConstants.assignmentsCollection,
      AppConstants.assignmentsBox,
    );
    await cacheCollection(
      AppConstants.gradesCollection,
      AppConstants.gradesBox,
    );
    await cacheCollection(
      AppConstants.notificationsCollection,
      AppConstants.notificationsBox,
    );
  }
}
