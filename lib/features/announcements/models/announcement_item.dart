import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementItem {
  const AnnouncementItem({
    required this.id,
    required this.titleBn,
    required this.messageBn,
    required this.titleEn,
    required this.messageEn,
    required this.active,
    required this.showModal,
    required this.sendPush,
    required this.pushTopic,
    this.posterUrl,
    this.pushStatus,
    this.pushError,
    this.startAt,
    this.endAt,
    this.pushRequestedAt,
    this.pushSentAt,
    this.createdAt,
    this.updatedAt,
    this.createdByUid,
  });

  final String id;
  final String titleBn;
  final String messageBn;
  final String titleEn;
  final String messageEn;
  final String? posterUrl;
  final bool active;
  final bool showModal;
  final bool sendPush;
  final String pushTopic;
  final String? pushStatus;
  final String? pushError;
  final DateTime? startAt;
  final DateTime? endAt;
  final DateTime? pushRequestedAt;
  final DateTime? pushSentAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdByUid;

  factory AnnouncementItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return AnnouncementItem.fromMap(doc.id, doc.data() ?? const {});
  }

  factory AnnouncementItem.fromMap(String id, Map<String, dynamic> map) {
    final topic = _asString(map['push_topic']);
    return AnnouncementItem(
      id: id,
      titleBn: _asString(map['title_bn']),
      messageBn: _asString(map['message_bn']),
      titleEn: _asString(map['title_en']),
      messageEn: _asString(map['message_en']),
      posterUrl: _nullableString(map['poster_url']),
      active: _asBool(map['active'], fallback: true),
      showModal: _asBool(map['show_modal'], fallback: true),
      sendPush: _asBool(map['send_push'], fallback: false),
      pushTopic: topic.isEmpty ? 'noorify_all' : topic,
      pushStatus: _nullableString(map['push_status']),
      pushError: _nullableString(map['push_error']),
      startAt: _asDateTime(map['start_at']),
      endAt: _asDateTime(map['end_at']),
      pushRequestedAt: _asDateTime(map['push_requested_at']),
      pushSentAt: _asDateTime(map['push_sent_at']),
      createdAt: _asDateTime(map['created_at']),
      updatedAt: _asDateTime(map['updated_at']),
      createdByUid: _nullableString(map['created_by_uid']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title_bn': titleBn,
      'message_bn': messageBn,
      'title_en': titleEn,
      'message_en': messageEn,
      'poster_url': posterUrl,
      'active': active,
      'show_modal': showModal,
      'send_push': sendPush,
      'push_topic': pushTopic,
      'push_status': pushStatus,
      'push_error': pushError,
      'start_at': startAt,
      'end_at': endAt,
      'push_requested_at': pushRequestedAt,
      'push_sent_at': pushSentAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'created_by_uid': createdByUid,
    };
  }

  String localizedTitle(bool isBangla) {
    final bn = titleBn.trim();
    final en = titleEn.trim();
    if (isBangla) {
      if (bn.isNotEmpty) return bn;
      return en;
    }
    if (en.isNotEmpty) return en;
    return bn;
  }

  String localizedMessage(bool isBangla) {
    final bn = messageBn.trim();
    final en = messageEn.trim();
    if (isBangla) {
      if (bn.isNotEmpty) return bn;
      return en;
    }
    if (en.isNotEmpty) return en;
    return bn;
  }

  bool isLiveAt(DateTime moment) {
    final utcMoment = moment.toUtc();
    final afterStart = startAt == null || !utcMoment.isBefore(startAt!.toUtc());
    final beforeEnd = endAt == null || !utcMoment.isAfter(endAt!.toUtc());
    return afterStart && beforeEnd;
  }

  static String _asString(Object? value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  static String? _nullableString(Object? value) {
    final text = _asString(value);
    return text.isEmpty ? null : text;
  }

  static bool _asBool(Object? value, {required bool fallback}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final lower = value.toLowerCase().trim();
      if (lower == 'true' || lower == '1' || lower == 'yes') return true;
      if (lower == 'false' || lower == '0' || lower == 'no') return false;
    }
    return fallback;
  }

  static DateTime? _asDateTime(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
