import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quizwiz/src/features/cards/controller/bloc/cards_bloc.dart';
import 'package:quizwiz/src/features/cards/controller/bloc/cards_events.dart';
import 'package:quizwiz/src/features/cards/data/models/flashcard_collection.dart';
import 'package:quizwiz/src/features/cards/presentation/screens/practice_cards_screen.dart';
import 'package:quizwiz/src/features/cards/presentation/widgets/practice_cards_widgets/choose_order_dialog.dart';
import 'package:quizwiz/src/core/services/daily_review_store.dart';
import 'package:quizwiz/src/features/cards/presentation/widgets/practice_cards_widgets/no_flashcards_to_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _CardsBlocFake implements CardsBloc {
  @override
  CardsState get state => const CardsState();

  @override
  Stream<CardsState> get stream => const Stream<CardsState>.empty();

  @override
  void add(CardsEvents event) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('choosing Again opens the order dialog before rating',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(MaterialApp(
      home: PracticeCardsScreen(
        collection: FlashcardCollection(
          name: 'Collection',
          uuid: 'collection-again',
          cards: [
            Flashcard(
              uuid: 'card-again',
              question: 'Question',
              answer: 'Answer',
              dueTime: 0,
            ),
          ],
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(ChooseOrderDialog), findsNothing);

    await tester.tap(find.text('Question'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Again'));
    await tester.tap(find.text('Again'));
    await tester.pumpAndSettle();

    expect(find.byType(ChooseOrderDialog), findsOneWidget);
    expect(find.text('Theo thứ tự'), findsOneWidget);
    expect(find.text('Ngẫu nhiên'), findsOneWidget);
  });

  testWidgets('resumes the saved card sequence while Again cards remain',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await DailyReviewStore.markAgain(
      collectionUuid: 'collection-resume',
      cardUuid: 'card-1',
    );
    await DailyReviewStore.saveReviewOrder(
      collectionUuid: 'collection-resume',
      shuffle: true,
      cardUuids: ['card-3', 'card-1', 'card-2'],
      currentCardUuid: 'card-1',
    );

    await tester.pumpWidget(MaterialApp(
      home: PracticeCardsScreen(
        collection: FlashcardCollection(
          name: 'Collection',
          uuid: 'collection-resume',
          cards: [
            Flashcard(
              uuid: 'card-1',
              question: 'Question 1',
              answer: 'Answer 1',
              dueTime: 0,
            ),
            Flashcard(
              uuid: 'card-2',
              question: 'Question 2',
              answer: 'Answer 2',
              dueTime: 0,
            ),
            Flashcard(
              uuid: 'card-3',
              question: 'Question 3',
              answer: 'Answer 3',
              dueTime: 0,
            ),
          ],
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Question 1'), findsOneWidget);
  });

  testWidgets('resumes a shuffled sequence when its third card is source-last',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    const order = [
      'card-1',
      'card-2',
      'card-10',
      'card-3',
      'card-4',
      'card-5',
      'card-6',
      'card-7',
      'card-8',
      'card-9',
    ];
    await DailyReviewStore.markAgain(
      collectionUuid: 'collection-shuffled-last-card',
      cardUuid: 'card-1',
    );
    await DailyReviewStore.saveReviewOrder(
      collectionUuid: 'collection-shuffled-last-card',
      shuffle: true,
      cardUuids: order,
      currentCardUuid: 'card-10',
    );

    await tester.pumpWidget(BlocProvider<CardsBloc>.value(
      value: _CardsBlocFake(),
      child: MaterialApp(
        home: PracticeCardsScreen(
          collection: FlashcardCollection(
            name: 'Collection',
            uuid: 'collection-shuffled-last-card',
            cards: List.generate(
              10,
              (index) => Flashcard(
                uuid: 'card-${index + 1}',
                question: 'Question ${index + 1}',
                answer: 'Answer ${index + 1}',
                dueTime: 0,
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Question 10'), findsOneWidget);
    await tester.tap(find.text('Question 10'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Good'));
    await tester.pumpAndSettle();

    expect(find.byType(NoFlashcardsToReview), findsNothing);
    expect(find.text('Question 3'), findsOneWidget);
  });

  testWidgets('starts in collection order without saved progress',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(MaterialApp(
      home: PracticeCardsScreen(
        collection: FlashcardCollection(
          name: 'Collection',
          uuid: 'collection-default',
          cards: [
            Flashcard(
              uuid: 'card-1',
              question: 'Question 1',
              answer: 'Answer 1',
              dueTime: 0,
            ),
            Flashcard(
              uuid: 'card-2',
              question: 'Question 2',
              answer: 'Answer 2',
              dueTime: 0,
            ),
          ],
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Question 1'), findsOneWidget);
  });

  testWidgets('Again selection saves its order and marks the card Again',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(BlocProvider<CardsBloc>.value(
      value: _CardsBlocFake(),
      child: MaterialApp(
        home: PracticeCardsScreen(
          collection: FlashcardCollection(
            name: 'Collection',
            uuid: 'collection-select-again',
            cards: [
              Flashcard(
                uuid: 'card-1',
                question: 'Question 1',
                answer: 'Answer 1',
                dueTime: 0,
              ),
              Flashcard(
                uuid: 'card-2',
                question: 'Question 2',
                answer: 'Answer 2',
                dueTime: 0,
              ),
            ],
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Question 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Again'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ngẫu nhiên'));
    await tester.pumpAndSettle();

    expect(find.byType(ChooseOrderDialog), findsNothing);
    expect(
      await DailyReviewStore.againUuids('collection-select-again'),
      contains('card-1'),
    );
    expect(
      (await DailyReviewStore.reviewOrder('collection-select-again'))?.shuffle,
      isTrue,
    );
  });

  testWidgets('keeps the shuffled order after rating a card', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await DailyReviewStore.markReviewed(
      collectionUuid: 'collection-shuffle-progress',
      cardUuid: 'card-1',
    );
    await DailyReviewStore.saveReviewOrder(
      collectionUuid: 'collection-shuffle-progress',
      shuffle: true,
      cardUuids: ['card-3', 'card-2'],
      currentCardUuid: 'card-3',
    );

    await tester.pumpWidget(BlocProvider<CardsBloc>.value(
      value: _CardsBlocFake(),
      child: MaterialApp(
        home: PracticeCardsScreen(
          collection: FlashcardCollection(
            name: 'Collection',
            uuid: 'collection-shuffle-progress',
            cards: [
              Flashcard(
                uuid: 'card-1',
                question: 'Question 1',
                answer: 'Answer 1',
                dueTime: 0,
              ),
              Flashcard(
                uuid: 'card-2',
                question: 'Question 2',
                answer: 'Answer 2',
                dueTime: 0,
              ),
              Flashcard(
                uuid: 'card-3',
                question: 'Question 3',
                answer: 'Answer 3',
                dueTime: 0,
              ),
            ],
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Question 3'), findsOneWidget);
    await tester.tap(find.text('Question 3'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Good'));
    await tester.pumpAndSettle();

    final savedOrder =
        await DailyReviewStore.reviewOrder('collection-shuffle-progress');
    expect(savedOrder?.shuffle, isTrue);
    expect(savedOrder?.cardUuids, ['card-2']);
  });

  testWidgets('Again on the completed screen asks for order and restarts',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await DailyReviewStore.markManyReviewed(
      collectionUuid: 'collection-restart',
      cardUuids: ['card-1', 'card-2'],
    );
    await DailyReviewStore.saveReviewOrder(
      collectionUuid: 'collection-restart',
      shuffle: false,
      cardUuids: const [],
    );

    await tester.pumpWidget(BlocProvider<CardsBloc>.value(
      value: _CardsBlocFake(),
      child: MaterialApp(
        home: PracticeCardsScreen(
          collection: FlashcardCollection(
            name: 'Collection',
            uuid: 'collection-restart',
            cards: [
              Flashcard(
                uuid: 'card-1',
                question: 'Question 1',
                answer: 'Answer 1',
                dueTime: 0,
              ),
              Flashcard(
                uuid: 'card-2',
                question: 'Question 2',
                answer: 'Answer 2',
                dueTime: 0,
              ),
            ],
          ),
        ),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(NoFlashcardsToReview), findsOneWidget);
    await tester.tap(find.text('Again'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(ChooseOrderDialog), findsOneWidget);
    await tester.tap(find.text('Ngẫu nhiên'));
    await tester.pumpAndSettle();

    expect(find.byType(NoFlashcardsToReview), findsNothing);
    expect(find.text('Đã ôn hôm nay: 0 / 2'), findsOneWidget);
    final savedOrder = await DailyReviewStore.reviewOrder('collection-restart');
    expect(savedOrder?.shuffle, isTrue);
    expect(savedOrder?.reviewAll, isTrue);
    expect(savedOrder?.cardUuids, hasLength(2));

    final firstCardIndex =
        int.parse(savedOrder!.currentCardUuid!.split('-').last);
    await tester.tap(find.text('Question $firstCardIndex'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Good'));
    await tester.pumpAndSettle();

    final progressAfterRating =
        await DailyReviewStore.reviewOrder('collection-restart');
    final nextCardIndex =
        int.parse(progressAfterRating!.currentCardUuid!.split('-').last);
    await tester.pumpWidget(BlocProvider<CardsBloc>.value(
      value: _CardsBlocFake(),
      child: MaterialApp(
        home: PracticeCardsScreen(
          collection: FlashcardCollection(
            name: 'Collection',
            uuid: 'collection-restart',
            cards: List.generate(
              2,
              (index) => Flashcard(
                uuid: 'card-${index + 1}',
                question: 'Question ${index + 1}',
                answer: 'Answer ${index + 1}',
                dueTime: DateTime.now()
                    .add(const Duration(days: 2))
                    .millisecondsSinceEpoch,
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(NoFlashcardsToReview), findsNothing);
    expect(find.text('Question $nextCardIndex'), findsOneWidget);
  });

  testWidgets('rating the last visible card advances to the remaining card',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(BlocProvider<CardsBloc>.value(
      value: _CardsBlocFake(),
      child: MaterialApp(
        home: PracticeCardsScreen(
          collection: FlashcardCollection(
            name: 'Collection',
            uuid: 'collection-last-card',
            cards: [
              Flashcard(
                uuid: 'card-1',
                question: 'Question 1',
                answer: 'Answer 1',
                dueTime: 0,
              ),
              Flashcard(
                uuid: 'card-2',
                question: 'Question 2',
                answer: 'Answer 2',
                dueTime: 0,
              ),
              Flashcard(
                uuid: 'card-3',
                question: 'Question 3',
                answer: 'Answer 3',
                dueTime: 0,
              ),
            ],
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.fling(find.byType(PageView), const Offset(-600, 0), 1000);
    await tester.pumpAndSettle();
    await tester.fling(find.byType(PageView), const Offset(-600, 0), 1000);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Question 3'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Good'));
    await tester.pumpAndSettle();

    expect(find.byType(NoFlashcardsToReview), findsNothing);
    expect(find.text('Question 2'), findsOneWidget);
  });

  testWidgets('Again shows order dialog and review resumes after arrow back',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final collection = FlashcardCollection(
      name: 'Collection',
      uuid: 'collection-resume-after-back',
      cards: [
        Flashcard(
          uuid: 'card-1',
          question: 'Question 1',
          answer: 'Answer 1',
          dueTime: 0,
        ),
        Flashcard(
          uuid: 'card-2',
          question: 'Question 2',
          answer: 'Answer 2',
          dueTime: 0,
        ),
        Flashcard(
          uuid: 'card-3',
          question: 'Question 3',
          answer: 'Answer 3',
          dueTime: 0,
        ),
      ],
    );

    await tester.pumpWidget(BlocProvider<CardsBloc>.value(
      value: _CardsBlocFake(),
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => PracticeCardsScreen(collection: collection),
              )),
              child: const Text('Open review'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Open review'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Question 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Again'));
    await tester.pumpAndSettle();
    expect(find.byType(ChooseOrderDialog), findsOneWidget);
    await tester.tap(find.text('Theo thứ tự'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Question 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Good'));
    await tester.pumpAndSettle();
    expect(find.text('Question 2'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open review'));
    await tester.pumpAndSettle();

    expect(find.text('Question 2'), findsOneWidget);
    await tester.tap(find.text('Question 2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hard'));
    await tester.pumpAndSettle();

    expect(find.byType(NoFlashcardsToReview), findsNothing);
    expect(find.text('Question 3'), findsOneWidget);
  });

  testWidgets('resumes the current card after Again order and leaving review',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final collection = FlashcardCollection(
      name: 'Collection',
      uuid: 'collection-resume-current-card',
      cards: List.generate(
        10,
        (index) => Flashcard(
          uuid: 'card-${index + 1}',
          question: 'Question ${index + 1}',
          answer: 'Answer ${index + 1}',
          dueTime: 0,
        ),
      ),
    );

    await tester.pumpWidget(BlocProvider<CardsBloc>.value(
      value: _CardsBlocFake(),
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => PracticeCardsScreen(collection: collection),
              )),
              child: const Text('Open review'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Open review'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Question 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Again'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Theo thứ tự'));
    await tester.pumpAndSettle();

    await tester.fling(find.byType(PageView), const Offset(-600, 0), 1000);
    await tester.pumpAndSettle();
    await tester.fling(find.byType(PageView), const Offset(-600, 0), 1000);
    await tester.pumpAndSettle();
    final savedBeforeExit =
        await DailyReviewStore.reviewOrder('collection-resume-current-card');
    expect(savedBeforeExit?.currentCardUuid, 'card-3');

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open review'));
    await tester.pumpAndSettle();

    expect(find.text('Question 3'), findsOneWidget);
    await tester.tap(find.text('Question 3'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Good'));
    await tester.pumpAndSettle();
    expect(find.text('Question 4'), findsOneWidget);
    expect(find.byType(NoFlashcardsToReview), findsNothing);
  });
}
