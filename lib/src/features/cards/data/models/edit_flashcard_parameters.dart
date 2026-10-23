// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:quizwiz/src/features/cards/data/data.dart';

class EditFlashcardParameters {
  final String question;
  final String answer;
  final String? note;
  final FlashcardCollection collection;
  final Flashcard flashcard;
  final List<String> choices;
  final int correctChoiceIndex;
  final List<CardAttachment> attachments;
  final List<Flashcard>? children;
  final List<String>? tags;
  const EditFlashcardParameters({
    required this.question,
    required this.answer,
    this.note,
    required this.collection,
    required this.flashcard,
    this.choices = const [],
    this.correctChoiceIndex = 0,
    this.attachments = const [],
    this.children,
    this.tags,
  });

  EditFlashcardParameters copyWith({
    String? question,
    String? answer,
    String? note,
    FlashcardCollection? collection,
    Flashcard? flashcard,
    List<String>? choices,
    int? correctChoiceIndex,
    List<CardAttachment>? attachments,
    List<Flashcard>? children,
    List<String>? tags,
  }) {
    return EditFlashcardParameters(
      question: question ?? this.question,
      answer: answer ?? this.answer,
      note: note ?? this.note,
      collection: collection ?? this.collection,
      flashcard: flashcard ?? this.flashcard,
      choices: choices ?? this.choices,
      correctChoiceIndex: correctChoiceIndex ?? this.correctChoiceIndex,
      attachments: attachments ?? this.attachments,
      children: children ?? this.children,
      tags: tags ?? this.tags,
    );
  }
}
