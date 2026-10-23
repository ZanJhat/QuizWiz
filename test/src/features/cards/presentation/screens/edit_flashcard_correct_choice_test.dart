import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizwiz/src/features/cards/data/models/edit_flashcard_parameters.dart';
import 'package:quizwiz/src/features/cards/data/models/flashcard_collection.dart';
import 'package:quizwiz/src/features/cards/presentation/screens/edit_flashcard_screen.dart';

void main() {
  testWidgets('shows and updates the correct choices for parent and child',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final child = Flashcard(
      question: 'Child question',
      choices: ['Child A', 'Child B', 'Child C', 'Child D'],
      correctChoiceIndex: 2,
    );
    final parent = Flashcard(
      question: 'Parent question',
      choices: ['Parent A', 'Parent B', 'Parent C', 'Parent D'],
      correctChoiceIndex: 1,
      children: [child],
    );

    await tester.pumpWidget(MaterialApp(
      home: EditFlashcardScreen(
        parameters: EditFlashcardParameters(
          question: parent.question,
          answer: parent.answer,
          collection:
              FlashcardCollection(name: 'Collection', uuid: 'collection'),
          flashcard: parent,
        ),
      ),
    ));

    final radios =
        tester.widgetList<Radio<int>>(find.byType(Radio<int>)).toList();
    expect(radios.take(4).map((radio) => radio.groupValue), everyElement(1));
    expect(radios.skip(4).map((radio) => radio.groupValue), everyElement(2));
    await tester.tap(find.byType(Radio<int>).at(2));
    await tester.pump();
    final updatedRadios =
        tester.widgetList<Radio<int>>(find.byType(Radio<int>)).toList();
    expect(updatedRadios.take(4).map((radio) => radio.groupValue),
        everyElement(2));
  });

  testWidgets('prepopulates the editable note from the card', (tester) async {
    final card = Flashcard(
      question: 'Question',
      answer: 'Answer',
      note: 'Existing note',
    );

    await tester.pumpWidget(MaterialApp(
      home: EditFlashcardScreen(
        parameters: EditFlashcardParameters(
          question: card.question,
          answer: card.answer,
          collection: FlashcardCollection(
            name: 'Collection',
            uuid: 'collection',
          ),
          flashcard: card,
        ),
      ),
    ));

    expect(
      tester.widgetList<TextFormField>(find.byType(TextFormField)).any(
            (field) => field.controller?.text == 'Existing note',
          ),
      isTrue,
    );
  });
}
