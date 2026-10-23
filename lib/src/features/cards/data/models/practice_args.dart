import 'package:quizwiz/src/features/cards/data/data.dart';

class PracticeArgs {
  final FlashcardCollection collection;

  const PracticeArgs({required this.collection});
}

class QuizArgs {
  final FlashcardCollection collection;
  final bool shuffle;

  const QuizArgs({required this.collection, this.shuffle = false});
}
