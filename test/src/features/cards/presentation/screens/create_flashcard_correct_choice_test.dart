import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizwiz/src/core/core.dart';
import 'package:quizwiz/src/features/cards/controller/controller.dart';
import 'package:quizwiz/src/features/cards/presentation/screens/create_flashcards_screen.dart';

class _CapturingCardsBloc implements CardsBloc {
  final events = <CardsEvents>[];

  @override
  CardsState get state => const CardsState();

  @override
  Stream<CardsState> get stream => const Stream.empty();

  @override
  void add(CardsEvents event) {
    events.add(event);
    if (event is AddFlashcardsEvent) {
      event.completer?.complete(null);
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('saves the selected correct choice when creating a card',
      (tester) async {
    final bloc = _CapturingCardsBloc();

    await tester.pumpWidget(BlocProvider<CardsBloc>.value(
      value: bloc,
      child: MaterialApp(
        onGenerateRoute: (_) =>
            MaterialPageRoute<void>(builder: (_) => const SizedBox()),
        home: const CreateFlashcardsScreen(collectionUuid: 'collection'),
      ),
    ));
    expect(tester.takeException(), isNull);
    expect(find.byType(CreateFlashcardsScreen), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
    await tester.enterText(find.byKey(const Key('question')), 'Question');
    await tester.tap(find.byType(Radio<int>).at(1));
    await tester.pump();
    await tester.drag(find.byType(ListView).first, const Offset(0, -2000));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key(AppStrings.addCard)));
    await tester.pumpAndSettle();

    final event = bloc.events.whereType<AddFlashcardsEvent>().single;
    expect(event.correctChoiceIndex, 1);
  });
}
