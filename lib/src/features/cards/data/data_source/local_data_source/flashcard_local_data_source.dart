import 'package:quizwiz/src/core/core.dart';
import 'package:dartz/dartz.dart';
import 'package:quizwiz/src/features/cards/data/data.dart';
import 'package:uuid/uuid.dart';

abstract class FlashcardLocalDataSource {
  factory FlashcardLocalDataSource() => IsarFlashcardDataSource();
  Future<Unit> addFlashcard(
    String question,
    String answer,
    String collectionUuid, {
    String note = '',
    List<String> choices = const [],
    int correctChoiceIndex = 0,
    List<CardAttachment> attachments = const [],
    List<Flashcard> children = const [],
    List<String> tags = const [],
    String? uuid,
  });

  Future<List<Flashcard>> getDueReviewCards(
    FlashcardCollection collection,
  );
  Future<Unit> updateDueTime(
    Flashcard card,
    String collectionUuid,
    ReviewResult reviewResult,
  );
  Future<Unit> markAllCardsEasy(String collectionUuid);
  Future<Unit> removeFlashcard(
      FlashcardCollection collection, String flashcardUuid);
  Future<Unit> editFlashcard(EditFlashcardParameters parameters);
  Future<Unit> reorderFlashcards(
      String collectionUuid, List<String> flashcardUuids);
  Future<List<MultipleChoiceQuiz>> getMultipleChoiceOptions(
      FlashcardCollection collection);
  Future<Unit> saveAllGeneratedFlashcard(
      String collectionUuid, List<Flashcard> flashcards);
}

class IsarFlashcardDataSource implements FlashcardLocalDataSource {
  final _instance = Isar.getInstance()!;
  final uuid = const Uuid();

  @override
  Future<Unit> addFlashcard(
    String question,
    String answer,
    String collectionUuid, {
    String note = '',
    List<String> choices = const [],
    int correctChoiceIndex = 0,
    List<CardAttachment> attachments = const [],
    List<Flashcard> children = const [],
    List<String> tags = const [],
    String? uuid,
  }) async {
    final flashcard = Flashcard(
        question: question,
        answer: answer,
        note: note,
        uuid: uuid ?? this.uuid.v4(),
        dueTime: DateTime.now().millisecondsSinceEpoch,
        choices: choices,
        correctChoiceIndex: correctChoiceIndex,
        attachments: attachments,
        tags: tags);
    final savedFlashcard = flashcard.copyWith(children: children);
    await _instance.writeTxn(() async {
      final collection =
          await _instance.flashcardCollections.getByUuid(collectionUuid);
      if (collection == null) {
        throw const LocalStorageException(
            message: 'Không tìm thấy bộ thẻ để lưu card');
      }
      final cards = collection.cards
          .where((card) => card.uuid != savedFlashcard.uuid)
          .toList()
        ..add(savedFlashcard);
      await _instance.flashcardCollections
          .put(collection.copyWith(cards: cards));
    }).onError((error, stackTrace) =>
        throw LocalStorageException(message: error.toString()));
    return unit;
  }

  @override
  Future<List<Flashcard>> getDueReviewCards(
    FlashcardCollection collection,
  ) async {
    final cards = collection.cards.where((card) {
      return DateTime.fromMillisecondsSinceEpoch(card.dueTime)
          .isBefore(DateTime.now());
    }).toList();
    cards.shuffle();
    return cards;
  }

  @override
  Future<Unit> updateDueTime(
      Flashcard card, String collectionUuid, ReviewResult reviewResult) async {
    await _instance.writeTxn(() async {
      final collection =
          await _instance.flashcardCollections.getByUuid(collectionUuid);

      final newCardList = collection!.cards.map((storedCard) {
        if (storedCard.uuid != card.uuid) return storedCard;
        if (!storedCard.isGroup) {
          return CardCalculation(storedCard).update(reviewResult);
        }
        return storedCard.copyWith(
          children: storedCard.children
              .map((child) => CardCalculation(child).update(reviewResult))
              .toList(),
        );
      }).toList();

      await _instance.flashcardCollections
          .put(collection.copyWith(cards: newCardList));
    });
    return unit;
  }

  @override
  Future<Unit> markAllCardsEasy(String collectionUuid) async {
    await _instance.writeTxn(() async {
      final collection =
          await _instance.flashcardCollections.getByUuid(collectionUuid);
      if (collection == null) {
        throw const LocalStorageException(
            message: 'Không tìm thấy bộ thẻ cần cập nhật');
      }
      final easyCards = collection.cards.map((card) {
        if (!card.isGroup) {
          return CardCalculation(card.copyWith()).update(ReviewResult.easy);
        }
        return card.copyWith(
          children: card.children
              .map((child) =>
                  CardCalculation(child.copyWith()).update(ReviewResult.easy))
              .toList(),
        );
      }).toList();
      await _instance.flashcardCollections
          .put(collection.copyWith(cards: easyCards));
    });
    return unit;
  }

  @override
  Future<Unit> removeFlashcard(
      FlashcardCollection collection, String flashcardUuid) async {
    await _instance.writeTxn(() async {
      await _instance.flashcardCollections.put(collection.copyWith(
          cards: collection.cards
              .where((element) => element.uuid != flashcardUuid)
              .toList()));
    });
    return unit;
  }

  @override
  Future<Unit> editFlashcard(EditFlashcardParameters parameters) async {
    await _instance.writeTxn(() async {
      final collection = await _instance.flashcardCollections
          .getByUuid(parameters.collection.uuid);
      if (collection == null) {
        throw const LocalStorageException(
            message: 'Không tìm thấy bộ thẻ cần cập nhật');
      }
      final findCard = collection.cards
          .where((element) => element.uuid == parameters.flashcard.uuid);
      final newCard = findCard.single.copyWith(
        question: parameters.question,
        answer: parameters.answer,
        note: parameters.note ?? findCard.single.note,
        choices: parameters.choices,
        correctChoiceIndex: parameters.correctChoiceIndex,
        attachments: parameters.attachments,
        tags: parameters.tags ?? findCard.single.tags,
        children: parameters.children ?? findCard.single.children,
      );
      final newList = collection.cards
          .map(
              (card) => card.uuid == parameters.flashcard.uuid ? newCard : card)
          .toList();

      await _instance.flashcardCollections
          .put(collection.copyWith(cards: newList));
    });
    return unit;
  }

  @override
  Future<Unit> reorderFlashcards(
      String collectionUuid, List<String> flashcardUuids) async {
    await _instance.writeTxn(() async {
      final collection =
          await _instance.flashcardCollections.getByUuid(collectionUuid);
      if (collection == null) {
        throw const LocalStorageException(
            message: 'Không tìm thấy bộ thẻ cần sắp xếp');
      }

      final cardsByUuid = {
        for (final card in collection.cards) card.uuid: card,
      };
      final reorderedCards = <Flashcard>[];
      for (final flashcardUuid in flashcardUuids) {
        final card = cardsByUuid.remove(flashcardUuid);
        if (card != null) reorderedCards.add(card);
      }
      reorderedCards.addAll(cardsByUuid.values);

      await _instance.flashcardCollections
          .put(collection.copyWith(cards: reorderedCards));
    }).onError((error, stackTrace) =>
        throw LocalStorageException(message: error.toString()));
    return unit;
  }

  @override
  Future<List<MultipleChoiceQuiz>> getMultipleChoiceOptions(
      FlashcardCollection collection) async {
    List<MultipleChoiceQuiz> result = [];
    for (var element in collection.cards) {
      final quizCollection = FlashcardCollection(
        name: collection.name,
        description: collection.description,
        uuid: collection.uuid,
        cards: [...collection.cards, ...element.children],
      );
      if (element.isGroup) {
        final childQuizzes = element.children.map((child) {
          final card = child.copyWith(
            attachments: child.attachments.isEmpty
                ? element.attachments
                : child.attachments,
          );
          return MultipleChoiceQuiz.fromCollection(
              card: card, collection: quizCollection);
        }).toList();
        result.add(MultipleChoiceQuiz(
          question: element.question,
          options: const [],
          card: element,
          children: childQuizzes,
        ));
      } else {
        result.add(MultipleChoiceQuiz.fromCollection(
            card: element, collection: quizCollection));
      }
    }
    return result;
  }

  @override
  Future<Unit> saveAllGeneratedFlashcard(
      String collectionUuid, List<Flashcard> flashcards) async {
    _instance.writeTxn(() async {
      final collection =
          await _instance.flashcardCollections.getByUuid(collectionUuid);
      List<Flashcard> newCardsList = [...collection!.cards];
      final now = DateTime.now().millisecondsSinceEpoch;
      newCardsList.addAll(flashcards.map((card) {
        if (card.uuid.isEmpty) {
          return card.copyWith(
            uuid: uuid.v4(),
            dueTime: now,
          );
        }
        return card.dueTime == 0 ? card.copyWith(dueTime: now) : card;
      }));
      await _instance.flashcardCollections
          .put(collection.copyWith(cards: newCardsList));
    }).onError((error, stackTrace) =>
        throw LocalStorageException(message: error.toString()));
    return unit;
  }
}
