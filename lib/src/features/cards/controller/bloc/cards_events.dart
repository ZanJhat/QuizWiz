// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:io';
import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:quizwiz/src/core/core.dart';
import 'package:quizwiz/src/features/cards/data/data.dart';

class CardsEvents extends Equatable {
  const CardsEvents();
  @override
  List<Object?> get props => [];
}

class GetCollectionsEvent extends CardsEvents {
  const GetCollectionsEvent();
}

class RemoveCollectionEvent extends CardsEvents {
  final String uuid;
  const RemoveCollectionEvent({
    required this.uuid,
  });
}

class CreateCollectionsEvent extends CardsEvents {
  final String name;
  final String description;
  const CreateCollectionsEvent({
    required this.name,
    required this.description,
  });
}

class AddFlashcardsEvent extends CardsEvents {
  final String collectionUuid;
  final String question;
  final String answer;
  final String note;
  final List<String> choices;
  final int correctChoiceIndex;
  final List<CardAttachment> attachments;
  final List<Flashcard> children;
  final List<String> tags;
  final Completer<String?>? completer;
  final String? uuid;
  const AddFlashcardsEvent({
    required this.collectionUuid,
    required this.question,
    required this.answer,
    this.note = '',
    this.choices = const [],
    this.correctChoiceIndex = 0,
    this.attachments = const [],
    this.children = const [],
    this.tags = const [],
    this.completer,
    this.uuid,
  });
}

class UpdateDueTimeEvent extends CardsEvents {
  final Flashcard card;
  final String collectionUuid;
  final ReviewResult reviewResult;
  const UpdateDueTimeEvent({
    required this.card,
    required this.collectionUuid,
    required this.reviewResult,
  });
}

class MarkAllCardsEasyEvent extends CardsEvents {
  final String collectionUuid;
  final Completer<void> completer;

  const MarkAllCardsEasyEvent({
    required this.collectionUuid,
    required this.completer,
  });

  @override
  List<Object?> get props => [collectionUuid];
}

class RemoveFlashcardsEvent extends CardsEvents {
  final FlashcardCollection collection;
  final String flashcardUuid;
  const RemoveFlashcardsEvent({
    required this.collection,
    required this.flashcardUuid,
  });
}

class EditFlashcardsEvent extends CardsEvents {
  final EditFlashcardParameters parameters;
  final Completer<String?>? completer;
  const EditFlashcardsEvent({required this.parameters, this.completer});
}

class ReorderFlashcardsEvent extends CardsEvents {
  final String collectionUuid;
  final List<String> flashcardUuids;

  const ReorderFlashcardsEvent({
    required this.collectionUuid,
    required this.flashcardUuids,
  });
}

class GetDueReviewsEvent extends CardsEvents {
  final FlashcardCollection collection;
  const GetDueReviewsEvent({required this.collection});
}

class EditCollectionEvent extends CardsEvents {
  final String name;
  final String description;
  final FlashcardCollection collection;
  const EditCollectionEvent({
    required this.name,
    required this.description,
    required this.collection,
  });
}

class GetMultipleQuizOptionsEvent extends CardsEvents {
  final FlashcardCollection collection;
  final bool shuffle;

  const GetMultipleQuizOptionsEvent({
    required this.collection,
    this.shuffle = false,
  });
}

class GenerateFlashcardsEvent extends CardsEvents {
  final File? file;
  final List<File> files;
  final String? sourceUrl;
  final String prompt;
  final String notes;
  const GenerateFlashcardsEvent({
    this.file,
    this.files = const [],
    this.sourceUrl,
    this.prompt = '',
    this.notes = '',
  });
}

class SaveAllGenerateFlashcardsEvent extends CardsEvents {
  final List<Flashcard> flashcards;
  final String collectionUuid;

  const SaveAllGenerateFlashcardsEvent(
      {required this.flashcards, required this.collectionUuid});
}

class CombineCollectionsEvent extends CardsEvents {
  final FlashcardCollection mainCollection;
  final FlashcardCollection secondaryCollection;
  const CombineCollectionsEvent({
    required this.mainCollection,
    required this.secondaryCollection,
  });
}

class ImportCollectionEvent extends CardsEvents {
  final FlashcardCollection collection;
  const ImportCollectionEvent({required this.collection});
}

class ImportCollectionsEvent extends CardsEvents {
  final List<FlashcardCollection> collections;
  final Completer<void> completer;
  const ImportCollectionsEvent({
    required this.collections,
    required this.completer,
  });

  @override
  List<Object?> get props => [collections];
}
