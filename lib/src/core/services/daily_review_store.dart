import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persists the cards reviewed in a collection during the current local day.
class DailyReviewStore {
  static String _key(String collectionUuid, DateTime date) {
    final day =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return 'daily_review_${collectionUuid}_$day';
  }

  static String _againKey(String collectionUuid, DateTime date) =>
      '${_key(collectionUuid, date)}_again';

  static String _orderKey(String collectionUuid, DateTime date) =>
      '${_key(collectionUuid, date)}_order';

  static Future<
      ({
        bool shuffle,
        bool reviewAll,
        List<String> cardUuids,
        String? currentCardUuid
      })?> reviewOrder(
    String collectionUuid,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    final value = preferences.getString(_orderKey(
      collectionUuid,
      DateTime.now(),
    ));
    if (value == null) return null;
    final decoded = jsonDecode(value);
    if (decoded is! Map<String, dynamic> ||
        decoded['shuffle'] is! bool ||
        decoded['cardUuids'] is! List ||
        (decoded['reviewAll'] != null && decoded['reviewAll'] is! bool) ||
        (decoded['currentCardUuid'] != null &&
            decoded['currentCardUuid'] is! String)) {
      throw const FormatException('Tiến trình ôn đã lưu không hợp lệ.');
    }
    return (
      shuffle: decoded['shuffle'] as bool,
      reviewAll: decoded['reviewAll'] as bool? ?? false,
      cardUuids: (decoded['cardUuids'] as List).whereType<String>().toList(),
      currentCardUuid: decoded['currentCardUuid'] as String?,
    );
  }

  static Future<void> saveReviewOrder({
    required String collectionUuid,
    required bool shuffle,
    bool reviewAll = false,
    required Iterable<String> cardUuids,
    String? currentCardUuid,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _orderKey(collectionUuid, DateTime.now()),
      jsonEncode({
        'shuffle': shuffle,
        'reviewAll': reviewAll,
        'cardUuids': cardUuids.toList(),
        'currentCardUuid': currentCardUuid,
      }),
    );
  }

  static Future<Set<String>> reviewedUuids(String collectionUuid) async {
    final preferences = await SharedPreferences.getInstance();
    return (preferences.getStringList(_key(collectionUuid, DateTime.now())) ??
            const <String>[])
        .toSet();
  }

  static Future<Set<String>> againUuids(String collectionUuid) async {
    final preferences = await SharedPreferences.getInstance();
    return (preferences
                .getStringList(_againKey(collectionUuid, DateTime.now())) ??
            const <String>[])
        .toSet();
  }

  static Future<void> markReviewed({
    required String collectionUuid,
    required String cardUuid,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final key = _key(collectionUuid, today);
    final reviewed = preferences.getStringList(key) ?? <String>[];
    if (!reviewed.contains(cardUuid)) {
      reviewed.add(cardUuid);
      await preferences.setStringList(key, reviewed);
    }
    final againKey = _againKey(collectionUuid, today);
    final again = preferences.getStringList(againKey) ?? <String>[];
    if (again.remove(cardUuid)) {
      await preferences.setStringList(againKey, again);
    }
  }

  static Future<void> markManyReviewed({
    required String collectionUuid,
    required Iterable<String> cardUuids,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final reviewedKey = _key(collectionUuid, today);
    final reviewed = (preferences.getStringList(reviewedKey) ?? <String>[])
        .toSet()
      ..addAll(cardUuids);
    await preferences.setStringList(reviewedKey, reviewed.toList());

    final againKey = _againKey(collectionUuid, today);
    final again = (preferences.getStringList(againKey) ?? <String>[]).toSet()
      ..removeAll(cardUuids);
    await preferences.setStringList(againKey, again.toList());
  }

  static Future<void> resetToday(String collectionUuid) async {
    final preferences = await SharedPreferences.getInstance();
    final today = DateTime.now();
    await preferences.remove(_key(collectionUuid, today));
    await preferences.remove(_againKey(collectionUuid, today));
    await preferences.remove(_orderKey(collectionUuid, today));
  }

  static Future<void> markAgain({
    required String collectionUuid,
    required String cardUuid,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final reviewedKey = _key(collectionUuid, today);
    final reviewed = preferences.getStringList(reviewedKey) ?? <String>[];
    if (!reviewed.contains(cardUuid)) {
      reviewed.add(cardUuid);
      await preferences.setStringList(reviewedKey, reviewed);
    }

    final againKey = _againKey(collectionUuid, today);
    final again = preferences.getStringList(againKey) ?? <String>[];
    if (!again.contains(cardUuid)) {
      again.add(cardUuid);
      await preferences.setStringList(againKey, again);
    }
  }
}
