import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:first_project/features/announcements/models/announcement_item.dart';

class AnnouncementService {
  AnnouncementService._();

  static final AnnouncementService instance = AnnouncementService._();

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection('announcements');

  Stream<List<AnnouncementItem>> watchAnnouncements({int limit = 100}) {
    return _collection
        .orderBy('updated_at', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map(AnnouncementItem.fromDoc).toList();
        });
  }

  Future<List<AnnouncementItem>> fetchAnnouncements({int limit = 100}) async {
    final snapshot = await _collection
        .orderBy('updated_at', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs.map(AnnouncementItem.fromDoc).toList();
  }

  Future<AnnouncementItem?> fetchLatestActiveModalAnnouncement() async {
    final items = await fetchAnnouncements(limit: 60);
    final now = DateTime.now();
    for (final item in items) {
      if (item.active && item.showModal && item.isLiveAt(now)) {
        return item;
      }
    }
    return null;
  }

  Future<String> upsertAnnouncement({
    String? id,
    required String titleBn,
    required String messageBn,
    String titleEn = '',
    String messageEn = '',
    String? posterUrl,
    required bool active,
    required bool showModal,
    DateTime? startAt,
    DateTime? endAt,
  }) async {
    final normalizedPoster = (posterUrl ?? '').trim();
    final payload = <String, dynamic>{
      'title_bn': titleBn.trim(),
      'message_bn': messageBn.trim(),
      'title_en': titleEn.trim(),
      'message_en': messageEn.trim(),
      'poster_url': normalizedPoster.isEmpty ? null : normalizedPoster,
      'active': active,
      'show_modal': showModal,
      'start_at': startAt == null ? null : Timestamp.fromDate(startAt.toUtc()),
      'end_at': endAt == null ? null : Timestamp.fromDate(endAt.toUtc()),
      'updated_at': FieldValue.serverTimestamp(),
    };

    if (id == null) {
      payload['created_at'] = FieldValue.serverTimestamp();
      payload['created_by_uid'] = FirebaseAuth.instance.currentUser?.uid;
      final ref = await _collection.add(payload);
      return ref.id;
    }

    await _collection.doc(id).set(payload, SetOptions(merge: true));
    return id;
  }

  Future<void> setActive(String id, bool active) async {
    await _collection.doc(id).set({
      'active': active,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> setShowModal(String id, bool showModal) async {
    await _collection.doc(id).set({
      'show_modal': showModal,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteAnnouncement(String id) async {
    await _collection.doc(id).delete();
  }
}
