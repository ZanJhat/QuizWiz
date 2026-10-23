import 'package:flutter_test/flutter_test.dart';
import 'package:quizwiz/src/core/services/daily_review_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('persists the selected order and card sequence per collection',
      () async {
    expect(await DailyReviewStore.reviewOrder('collection-1'), isNull);

    await DailyReviewStore.saveReviewOrder(
      collectionUuid: 'collection-1',
      shuffle: true,
      cardUuids: ['card-3', 'card-1', 'card-2'],
    );

    final savedOrder = await DailyReviewStore.reviewOrder('collection-1');
    expect(savedOrder?.shuffle, isTrue);
    expect(savedOrder?.cardUuids, ['card-3', 'card-1', 'card-2']);
    expect(await DailyReviewStore.reviewOrder('collection-2'), isNull);
  });

  test('persists ordered mode when selected for Again', () async {
    await DailyReviewStore.saveReviewOrder(
      collectionUuid: 'collection-1',
      shuffle: false,
      reviewAll: true,
      cardUuids: ['card-1', 'card-2'],
    );

    final savedOrder = await DailyReviewStore.reviewOrder('collection-1');
    expect(savedOrder?.shuffle, isFalse);
    expect(savedOrder?.reviewAll, isTrue);
    expect(savedOrder?.cardUuids, ['card-1', 'card-2']);
  });

  test('clears the saved order when today is reset', () async {
    await DailyReviewStore.saveReviewOrder(
      collectionUuid: 'collection-1',
      shuffle: true,
      cardUuids: ['card-2', 'card-1'],
    );

    await DailyReviewStore.resetToday('collection-1');

    expect(await DailyReviewStore.reviewOrder('collection-1'), isNull);
  });
}
