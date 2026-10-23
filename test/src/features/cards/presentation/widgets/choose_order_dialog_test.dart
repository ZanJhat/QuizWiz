import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizwiz/src/core/router/routes.dart';
import 'package:quizwiz/src/features/cards/data/data.dart';
import 'package:quizwiz/src/features/cards/presentation/widgets/home_screen_widgets/collection_card_widget.dart';
import 'package:quizwiz/src/features/cards/presentation/widgets/practice_cards_widgets/choose_order_dialog.dart';
import 'package:quizwiz/src/features/cards/presentation/widgets/practice_cards_widgets/choose_quiz_dialog.dart';

void main() {
  testWidgets('returns false when choosing to study in order', (tester) async {
    bool? selectedOrder;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            selectedOrder = await showDialog<bool>(
              context: context,
              builder: (_) => const ChooseOrderDialog(),
            );
          },
          child: const Text('Open'),
        ),
      ),
    ));

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Theo thứ tự'));
    await tester.pumpAndSettle();

    expect(selectedOrder, isFalse);
  });

  testWidgets('returns true when choosing random order', (tester) async {
    bool? selectedOrder;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            selectedOrder = await showDialog<bool>(
              context: context,
              builder: (_) => const ChooseOrderDialog(),
            );
          },
          child: const Text('Open'),
        ),
      ),
    ));

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ngẫu nhiên'));
    await tester.pumpAndSettle();

    expect(selectedOrder, isTrue);
  });

  testWidgets('Review opens directly in the default ordered mode',
      (tester) async {
    Object? routeArguments;
    final collection = FlashcardCollection(name: 'Collection', uuid: 'id');
    await tester.pumpWidget(MaterialApp(
      onGenerateRoute: (settings) {
        if (settings.name == Routes.practiceCards) {
          routeArguments = settings.arguments;
        }
        return MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Destination')),
        );
      },
      home: Scaffold(body: CollectionCardWidget(collection: collection)),
    ));

    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();

    expect(routeArguments, isA<PracticeArgs>());
    expect(find.byType(ChooseOrderDialog), findsNothing);
  });

  testWidgets('Writing mode asks for order and passes it to practice',
      (tester) async {
    Object? routeArguments;
    final collection = FlashcardCollection(name: 'Collection', uuid: 'id');
    await tester.pumpWidget(MaterialApp(
      onGenerateRoute: (settings) {
        if (settings.name == Routes.writingQuiz) {
          routeArguments = settings.arguments;
        }
        return MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Destination')),
        );
      },
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => ChooseQuizDialog(collection: collection),
          ),
          child: const Text('Choose practice'),
        ),
      ),
    ));

    await tester.tap(find.text('Choose practice'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Writing Quiz'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Theo thứ tự'));
    await tester.pumpAndSettle();

    expect(routeArguments, isA<QuizArgs>());
    expect((routeArguments! as QuizArgs).shuffle, isFalse);
  });
}
