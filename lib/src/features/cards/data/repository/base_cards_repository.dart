import 'package:quizwiz/src/core/core.dart';
import 'package:quizwiz/src/features/cards/data/data.dart';
import 'dart:io';

abstract class BaseCardsRepository {
  factory BaseCardsRepository(FlashcardLocalDataSource flashcardLocalDataSource,
          CollectionLocalDataSource collectionLocalDataSource) =>
      CardsRepository(flashcardLocalDataSource, collectionLocalDataSource);

  EitherFlashcards getDueReviewCards(
    FlashcardCollection collection,
  );
  EitherCollections getCollections();
  EitherUnit createCollection(String name, {description = ''});
  EitherUnit addFlashcard(
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
  EitherUnit removeCollection(String uuid);
  EitherUnit updateDueTime(
    Flashcard card,
    String collectionUuid,
    ReviewResult reviewResult,
  );
  EitherUnit markAllCardsEasy(String collectionUuid);
  EitherUnit removeFlashcard(
      FlashcardCollection collection, String flashcardUuid);
  EitherUnit editFlashcard(EditFlashcardParameters parameters);
  EitherUnit reorderFlashcards(
      String collectionUuid, List<String> flashcardUuids);
  EitherUnit editCollection(
      ({
        FlashcardCollection collection,
        String name,
        String description
      }) collection);
  EitherMultiple getMultipleChoiceOptions(FlashcardCollection collection);
  EitherFlashcards generateFlashcards({
    File? file,
    List<File> files = const [],
    String? sourceUrl,
    String prompt = '',
    String notes = '',
  });
  EitherUnit saveAllGeneratedFlashcard(
      String collectionUuid, List<Flashcard> flashcards);
  EitherUnit combineCollections(FlashcardCollection mainCollection,
      FlashcardCollection secondaryCollection);
  EitherUnit importCollection(FlashcardCollection collection);
  EitherUnit importCollections(List<FlashcardCollection> collections);
}
