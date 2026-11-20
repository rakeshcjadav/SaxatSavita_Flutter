import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:saxatsavita_flutter/models/saved_suvichar.dart';
import 'package:saxatsavita_flutter/services/saved_suvichar_sync.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavedSuvicharService {
  static final SavedSuvicharService _instance =
      SavedSuvicharService._internal();
  factory SavedSuvicharService() => _instance;
  SavedSuvicharService._internal();

  static const guestListKey = 'saved_suvichars_guest';
  static const guestTombstoneKey = 'saved_suvichars_guest_tombstones';

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  bool get _canSyncCloud => !kIsWeb && _uid != null;

  String _listKey(String? uid) =>
      uid == null ? guestListKey : 'saved_suvichars_$uid';

  String _tombstoneKey(String? uid) =>
      uid == null ? guestTombstoneKey : 'saved_suvichars_${uid}_tombstones';

  CollectionReference<Map<String, dynamic>> _collection(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('suvichars');
  }

  Future<List<SavedSuvichar>> load() async {
    final uid = _uid;
    if (uid != null) {
      await _mergeGuestIntoUser(uid);
    }
    var local = await _readList(uid);
    if (_canSyncCloud && uid != null) {
      local = await _sync(uid, local);
    }
    return local;
  }

  Future<SavedSuvichar> save(SavedSuvichar item) async {
    final uid = _uid;
    if (uid != null) {
      await _mergeGuestIntoUser(uid);
    }
    final local = await _readList(uid);
    final next = [item, ...local.where((existing) => existing.id != item.id)];
    final tombstones = await _readTombstones(uid);
    if (tombstones.remove(item.id)) {
      await _writeTombstones(uid, tombstones);
    }
    await _writeList(uid, next);
    if (_canSyncCloud && uid != null) {
      try {
        await _collection(uid).doc(item.id).set(item.toJson());
      } catch (e) {
        debugPrint('Saved suvichar locally; cloud sync failed: $e');
      }
    }
    return item;
  }

  Future<void> delete(String id) async {
    final uid = _uid;
    final local = await _readList(uid);
    await _writeList(uid, local.where((item) => item.id != id).toList());
    if (!_canSyncCloud || uid == null) return;

    final tombstones = await _readTombstones(uid);
    tombstones.add(id);
    await _writeTombstones(uid, tombstones);
    try {
      await _collection(uid).doc(id).delete();
      tombstones.remove(id);
      await _writeTombstones(uid, tombstones);
    } catch (e) {
      debugPrint('Suvichar cloud delete failed, will retry: $e');
    }
  }

  Future<void> _mergeGuestIntoUser(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final guestRaw = prefs.getString(guestListKey);
    final guestTombRaw = prefs.getString(guestTombstoneKey);
    final hasGuestItems =
        guestRaw != null && guestRaw.isNotEmpty && guestRaw != '[]';
    final hasGuestTombs =
        guestTombRaw != null && guestTombRaw.isNotEmpty && guestTombRaw != '[]';
    if (!hasGuestItems && !hasGuestTombs) return;

    final guest = _decodeList(guestRaw);
    final userItems = await _readList(uid);
    final tombstones = {
      ...await _readTombstones(uid),
      ..._decodeTombstones(guestTombRaw),
    };
    final plan = planSuvicharSync(
      local: guest,
      remote: userItems,
      tombstones: tombstones,
    );
    await _writeList(uid, plan.merged);
    await _writeTombstones(uid, tombstones);
    await prefs.remove(guestListKey);
    await prefs.remove(guestTombstoneKey);
  }

  Future<List<SavedSuvichar>> _sync(
    String uid,
    List<SavedSuvichar> local,
  ) async {
    List<SavedSuvichar> remote;
    try {
      remote = await _fetchCloud(uid);
    } catch (e) {
      debugPrint('Suvichar cloud load failed, using local cache: $e');
      return local;
    }

    final tombstones = await _readTombstones(uid);
    final plan = planSuvicharSync(
      local: local,
      remote: remote,
      tombstones: tombstones,
    );

    final remainingTombs = tombstones.toSet();
    for (final id in plan.tombstonesToRetry) {
      try {
        await _collection(uid).doc(id).delete();
        remainingTombs.remove(id);
      } catch (e) {
        debugPrint('Suvichar tombstone delete failed for $id: $e');
      }
    }
    remainingTombs.removeWhere((id) => !plan.tombstonesToRetry.contains(id));

    for (final item in plan.toUpload) {
      try {
        await _collection(uid).doc(item.id).set(item.toJson());
      } catch (e) {
        debugPrint('Suvichar upload failed for ${item.id}: $e');
      }
    }

    await _writeList(uid, plan.merged);
    await _writeTombstones(uid, remainingTombs);
    return plan.merged;
  }

  Future<List<SavedSuvichar>> _fetchCloud(String uid) async {
    final snapshot = await _collection(uid).get();
    final items = <SavedSuvichar>[];
    for (final doc in snapshot.docs) {
      try {
        items.add(SavedSuvichar.fromJson(_normalizeCloud(doc.id, doc.data())));
      } catch (e) {
        debugPrint('Skipping unreadable suvichar ${doc.id}: $e');
      }
    }
    return items;
  }

  Map<String, dynamic> _normalizeCloud(String id, Map<String, dynamic> data) {
    final json = Map<String, dynamic>.from(data);
    json['id'] = json['id'] ?? id;
    for (final key in ['createdAt', 'updatedAt']) {
      final value = json[key];
      if (value is Timestamp) {
        json[key] = value.toDate().toIso8601String();
      }
    }
    return json;
  }

  Future<List<SavedSuvichar>> _readList(String? uid) async {
    final prefs = await SharedPreferences.getInstance();
    final items = _decodeList(prefs.getString(_listKey(uid)));
    items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return items;
  }

  Future<void> _writeList(String? uid, List<SavedSuvichar> items) async {
    final prefs = await SharedPreferences.getInstance();
    final sorted = [...items]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    await prefs.setString(
      _listKey(uid),
      jsonEncode(sorted.map((item) => item.toJson()).toList()),
    );
  }

  Future<Set<String>> _readTombstones(String? uid) async {
    final prefs = await SharedPreferences.getInstance();
    return _decodeTombstones(prefs.getString(_tombstoneKey(uid)));
  }

  Future<void> _writeTombstones(String? uid, Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _tombstoneKey(uid);
    if (ids.isEmpty) {
      await prefs.remove(key);
      return;
    }
    final sorted = ids.toList()..sort();
    await prefs.setString(key, jsonEncode(sorted));
  }

  List<SavedSuvichar> _decodeList(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    final items = <SavedSuvichar>[];
    for (final entry in decoded) {
      if (entry is! Map) continue;
      try {
        items.add(SavedSuvichar.fromJson(Map<String, dynamic>.from(entry)));
      } catch (e) {
        debugPrint('Skipping unreadable saved suvichar: $e');
      }
    }
    return items;
  }

  Set<String> _decodeTombstones(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    final decoded = jsonDecode(raw);
    if (decoded is! List) return {};
    return decoded.map((id) => id.toString()).toSet();
  }
}
