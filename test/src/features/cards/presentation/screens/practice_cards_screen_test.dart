import '../../../../tests_imports.dart';

class CardsBlocMock extends MockBloc<CardsEvents, CardsState>
    implements CardsBloc {}

void main() {
  late Widget practiceCardsScreen;
  late CardsBloc mockBloc;
  setUp(() {
    mockBloc = CardsBlocMock();
    practiceCardsScreen = BlocProvider.value(
      value: mockBloc,
      child: MaterialApp(
        onGenerateRoute: (settings) => RouteGenerator.generateRoute(settings),
        home: PracticeCardsScreen(
            collection: FlashcardCollection(
          name: "name",
          uuid: "",
        )),
      ),
    );
  });
  group(
      "Test practice_cards_screen when it's loading,loaded, and has an error -",
      () {
    testWidgets(
        "When [flashcardsRequestState] is loading, expect [LoadingWidget]",
        (tester) async {
      whenListen(mockBloc, const Stream<CardsState>.empty(),
          initialState: const CardsState());
      await tester.pumpWidget(practiceCardsScreen);
      expect(find.byType(LoadingWidget), findsOneWidget);
    });
    testWidgets(
        "When [flashcardsRequestState] has an error, expect [LoadingWidget] then [CustomErrorWidget]",
        (tester) async {
      whenListen(
          mockBloc,
          Stream<CardsState>.value(const CardsState(
              flashcardRequestState: RequestState.error,
              flashcardErrorMessage: "error message")),
          initialState: const CardsState());
      await tester.pumpWidget(practiceCardsScreen);
      expect(find.byType(LoadingWidget), findsOneWidget);
      await tester.pump();
      expect(find.byType(CustomErrorWidget), findsOneWidget);
      expect(find.byType(PageView), findsNothing);
    });
    testWidgets(
        '''When [flashcardsRequestState] is success with empty flashcards list,
     expect [LoadingWidget] then [NoFlashcardsToReview] widget''',
        (tester) async {
      whenListen(
          mockBloc,
          Stream.value(const CardsState(
              flashcardRequestState: RequestState.success, flashcards: [])),
          initialState: const CardsState());
      await tester.pumpWidget(practiceCardsScreen);
      expect(find.byType(LoadingWidget), findsOneWidget);
      await tester.pump();
      expect(find.byType(NoFlashcardsToReview), findsOneWidget);
    });
    testWidgets(
        '''When [flashcardsRequestState] is success with a flashcards list,
     expect [LoadingWidget] then [PageView] and [Text] widgets''',
        (tester) async {
      whenListen(
          mockBloc,
          Stream.value(CardsState(
              flashcardRequestState: RequestState.success,
              collectionsRequestState: RequestState.success,
              flashcards: [
                Flashcard(
                  question: "question",
                  answer: "answer",
                )
              ])),
          initialState: const CardsState());
      await tester.pumpWidget(practiceCardsScreen);
      expect(find.byType(LoadingWidget), findsOneWidget);
      await tester.pump();
      expect(find.byType(PageView), findsOneWidget);
      expect(find.text('question'), findsOneWidget);
    });
    testWidgets(
        '''When tapping [Text], expect to navigate to [ReviewResultScree]''',
        (tester) async {
      whenListen(
          mockBloc,
          Stream.value(CardsState(
              flashcardRequestState: RequestState.success,
              collectionsRequestState: RequestState.success,
              flashcards: [
                Flashcard(
                  question: "question",
                  answer: "answer",
                )
              ])),
          initialState: const CardsState());
      await tester.pumpWidget(practiceCardsScreen);
      await tester.pump();
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();
      expect(find.byType(ReviewResultScreen), findsOneWidget);
    });

    testWidgets('shows a card note only after revealing the review card',
        (tester) async {
      whenListen(mockBloc, const Stream<CardsState>.empty(),
          initialState: const CardsState());
      await tester.pumpWidget(BlocProvider.value(
        value: mockBloc,
        child: MaterialApp(
          home: PracticeCardsScreen(
            collection: FlashcardCollection(
              name: 'Collection',
              uuid: 'collection',
              cards: [
                Flashcard(
                  uuid: 'card',
                  question: 'Review question',
                  answer: 'Review answer',
                  note: 'Review note',
                  dueTime: 0,
                ),
              ],
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Review note'), findsNothing);

      await tester.tap(find.text('Review question'));
      await tester.pumpAndSettle();
      expect(find.text('Review note'), findsOneWidget);
    });
  });
}
