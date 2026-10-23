// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:math';

import 'package:quizwiz/src/features/cards/data/data.dart';

class MultipleChoiceQuiz {
  final String question;
  final List<String> options;
  final String rightAnswer;
  final int correctChoiceIndex;
  final List<int> optionSlotIndices;
  final Flashcard? card;
  final List<MultipleChoiceQuiz> children;
  const MultipleChoiceQuiz({
    required this.question,
    required this.options,
    this.rightAnswer = '',
    this.correctChoiceIndex = 0,
    this.optionSlotIndices = const [],
    this.card,
    this.children = const [],
  });

  bool get isGroup => children.isNotEmpty;

  int get correctSlotIndex {
    if (optionSlotIndices.length == options.length) {
      return correctChoiceIndex;
    }
    final answerIndex = options.indexOf(rightAnswer);
    return answerIndex >= 0 ? answerIndex : correctChoiceIndex;
  }

  int slotIndexAt(int optionIndex) => optionSlotIndices.length == options.length
      ? optionSlotIndices[optionIndex]
      : optionIndex;

  factory MultipleChoiceQuiz.fromCollection(
      {required Flashcard card, required FlashcardCollection collection}) {
    Flashcard? parent;
    for (final candidate in [
      ...collection.cards,
      ...collection.cards.expand((item) => item.children),
    ]) {
      if (candidate.children.any((child) => child.uuid == card.uuid)) {
        parent = candidate;
        break;
      }
    }
    final slots = card.choiceSlots;
    final correctIndex = card.resolvedCorrectChoiceIndex;
    final answer = card.answer.trim();
    final optionTexts = List<String>.filled(slots.length, '');
    final used = <String>{};

    for (var i = 0; i < slots.length; i++) {
      final value = slots[i].trim();
      if (value.isNotEmpty) {
        optionTexts[i] = value;
        used.add(value.toLowerCase());
      }
    }

    if (answer.isNotEmpty) {
      if (optionTexts[correctIndex].isEmpty) {
        optionTexts[correctIndex] = answer;
        used.add(answer.toLowerCase());
      }

      final candidates = <String>[];
      for (final other in [
        ...collection.cards,
        ...collection.cards.expand((item) => item.children),
      ]) {
        if (identical(other, card) ||
            (card.uuid.isNotEmpty && other.uuid == card.uuid)) {
          continue;
        }
        candidates.add(other.answer.trim());
        candidates.addAll(other.choices.map((choice) => choice.trim()));
      }
      final random = Random();
      candidates
        ..removeWhere(
            (value) => value.isEmpty || used.contains(value.toLowerCase()))
        ..shuffle(random);

      var candidateIndex = 0;
      for (var i = 0; i < optionTexts.length; i++) {
        if (optionTexts[i].isNotEmpty) continue;
        while (candidateIndex < candidates.length &&
            used.contains(candidates[candidateIndex].toLowerCase())) {
          candidateIndex++;
        }
        if (candidateIndex >= candidates.length) break;
        final candidate = candidates[candidateIndex++];
        optionTexts[i] = candidate;
        used.add(candidate.toLowerCase());
      }
    }

    final options = <String>[];
    final optionSlotIndices = <int>[];
    for (var i = 0; i < optionTexts.length; i++) {
      // With no writing answer, empty slots still represent the letters A-H.
      // Otherwise, omit unfilled distractor slots when the collection has no
      // remaining candidate, while retaining the original letter positions.
      if (answer.isNotEmpty && optionTexts[i].isEmpty) continue;
      options.add(optionTexts[i]);
      optionSlotIndices.add(i);
    }

    return MultipleChoiceQuiz(
      question: card.question,
      options: options,
      rightAnswer: optionTexts[correctIndex],
      correctChoiceIndex: correctIndex,
      optionSlotIndices: optionSlotIndices,
      card: parent == null || card.attachments.isNotEmpty
          ? card
          : card.copyWith(attachments: parent.attachments),
    );
  }
}
