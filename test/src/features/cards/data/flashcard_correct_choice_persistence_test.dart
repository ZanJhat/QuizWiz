import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:quizwiz/src/core/services/card_template_service.dart';
import 'package:quizwiz/src/features/cards/data/data_source/local_data_source/flashcard_local_data_source.dart';
import 'package:quizwiz/src/features/cards/data/models/edit_flashcard_parameters.dart';
import 'package:quizwiz/src/features/cards/data/models/flashcard_collection.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('resolves correct choice indexes after saving and reloading cards',
      () async {
    await Isar.initializeIsarCore(download: true);
    final directory = await Directory.systemTemp.createTemp('quizwiz-isar-');
    final isar = await Isar.open(
      [FlashcardCollectionSchema],
      directory: directory.path,
      inspector: false,
    );
    addTearDown(() async {
      await isar.close();
      await directory.delete(recursive: true);
    });

    await isar.writeTxn(() async {
      await isar.flashcardCollections.put(FlashcardCollection(
        name: 'Collection',
        uuid: 'collection',
      ));
    });
    await IsarFlashcardDataSource().addFlashcard(
      'Parent question',
      '',
      'collection',
      note: 'Parent note',
      choices: ['A', 'B', 'C', 'D'],
      correctChoiceIndex: 1,
      children: [
        Flashcard(
          uuid: 'child',
          question: 'Child question',
          note: 'Child note',
          choices: ['A', 'B', 'C', 'D'],
          correctChoiceIndex: 2,
        ),
      ],
    );

    final stored = await isar.flashcardCollections.getByUuid('collection');
    expect(stored!.cards.single.resolvedCorrectChoiceIndex, 1);
    expect(stored.cards.single.children.single.resolvedCorrectChoiceIndex, 2);
    expect(stored.cards.single.note, 'Parent note');
    expect(stored.cards.single.children.single.note, 'Child note');
    expect(stored.cards.single.toJson()['correctChoiceIndex'], 1);
    expect(stored.cards.single.toJson()['note'], 'Parent note');
    expect(
        stored.cards.single.children.single.toJson()['correctChoiceIndex'], 2);
    expect(stored.cards.single.children.single.toJson()['note'], 'Child note');
  });

  test('persists attachment metadata when adding and editing a card', () async {
    await Isar.initializeIsarCore(download: true);
    final directory = await Directory.systemTemp.createTemp('quizwiz-isar-');
    final isar = await Isar.open(
      [FlashcardCollectionSchema],
      directory: directory.path,
      inspector: false,
    );
    addTearDown(() async {
      await isar.close();
      await directory.delete(recursive: true);
    });

    final collection = FlashcardCollection(
      name: 'Collection',
      uuid: 'collection',
    );
    await isar.writeTxn(() async {
      await isar.flashcardCollections.put(collection);
    });
    final dataSource = IsarFlashcardDataSource();
    final addedAttachment = CardAttachment(
      type: 'audio',
      source: 'collection/card/audio.mp3',
      fileName: 'audio.mp3',
    );
    final childAttachment = CardAttachment(
      type: 'audio',
      source: 'collection/card/child-audio.mp3',
      fileName: 'child-audio.mp3',
    );
    await dataSource.addFlashcard(
      'Question',
      'Answer',
      'collection',
      uuid: 'card',
      attachments: [addedAttachment],
      children: [
        Flashcard(
          uuid: 'child',
          question: 'Child question',
          attachments: [childAttachment],
        ),
      ],
    );

    var stored = await isar.flashcardCollections.getByUuid('collection');
    expect(
        stored!.cards.single.attachments.single.source, addedAttachment.source);
    expect(
      stored.cards.single.children.single.attachments.single.source,
      childAttachment.source,
    );

    final editedAttachment = CardAttachment(
      type: 'image',
      source: 'collection/card/image.png',
      fileName: 'image.png',
    );
    final editedChildAttachment = CardAttachment(
      type: 'video',
      source: 'collection/card/child-video.mp4',
      fileName: 'child-video.mp4',
    );
    final card = stored.cards.single;
    await dataSource.editFlashcard(EditFlashcardParameters(
      question: card.question,
      answer: card.answer,
      collection: collection,
      flashcard: card,
      attachments: [editedAttachment],
      children: [
        card.children.single.copyWith(attachments: [editedChildAttachment]),
      ],
    ));

    stored = await isar.flashcardCollections.getByUuid('collection');
    expect(stored!.cards, hasLength(1));
    expect(stored.cards.single.attachments, hasLength(1));
    expect(
        stored.cards.single.attachments.single.source, editedAttachment.source);
    expect(
      stored.cards.single.children.single.attachments.single.source,
      editedChildAttachment.source,
    );
  });

  test('editing and reordering cards preserves the requested list order',
      () async {
    await Isar.initializeIsarCore(download: true);
    final directory = await Directory.systemTemp.createTemp('quizwiz-isar-');
    final isar = await Isar.open(
      [FlashcardCollectionSchema],
      directory: directory.path,
      inspector: false,
    );
    addTearDown(() async {
      await isar.close();
      await directory.delete(recursive: true);
    });

    final cards = [
      Flashcard(uuid: 'first', question: 'First'),
      Flashcard(uuid: 'second', question: 'Second', note: 'Old note'),
      Flashcard(uuid: 'third', question: 'Third'),
    ];
    final collection = FlashcardCollection(
      name: 'Collection',
      uuid: 'collection',
      cards: cards,
    );
    await isar.writeTxn(() async {
      await isar.flashcardCollections.put(collection);
    });

    final dataSource = IsarFlashcardDataSource();
    await dataSource.editFlashcard(EditFlashcardParameters(
      question: 'Updated second',
      answer: '',
      note: 'Updated note',
      collection: collection,
      flashcard: cards[1],
    ));
    var stored = await isar.flashcardCollections.getByUuid('collection');
    expect(
        stored!.cards.map((card) => card.uuid), ['first', 'second', 'third']);
    expect(stored.cards[1].question, 'Updated second');
    expect(stored.cards[1].note, 'Updated note');

    await dataSource
        .reorderFlashcards('collection', ['third', 'first', 'second']);
    stored = await isar.flashcardCollections.getByUuid('collection');
    expect(
        stored!.cards.map((card) => card.uuid), ['third', 'first', 'second']);
  });

  test('legacy JSON cards default note to an empty string', () {
    final card = Flashcard.fromJson({
      'question': 'Legacy question',
      'answer': 'Legacy answer',
    });

    expect(card.note, isEmpty);
    expect(
        FlashcardCollection(
          name: 'Collection',
          uuid: 'collection',
          cards: [card],
        ).toJson()['version'],
        4);
  });

  test('latest template describes and serializes card notes', () async {
    final template = await CardTemplateService.renderLatestTemplate();

    expect(template, contains('Phiên bản định dạng: 4'));
    expect(template, contains('"note": "Có thể ghi thêm cách phát âm'));
    expect(template, contains('note là ghi chú tùy chọn'));
  });
}
