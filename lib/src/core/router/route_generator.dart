import 'package:quizwiz/src/core/router/routes.dart';
import 'package:quizwiz/src/core/widgets/error_widget.dart';
import 'package:quizwiz/src/features/cards/data/data.dart';
import 'package:quizwiz/src/features/cards/presentation/presentation.dart';
import 'package:quizwiz/src/features/cards/presentation/screens/writing_quiz_screen.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (context) => const HomeScreen());
      case Routes.createFlashcards:
        var uuid = settings.arguments as String;
        return MaterialPageRoute(
            builder: (context) => CreateFlashcardsScreen(
                  collectionUuid: uuid,
                ));
      case Routes.flashcardsList:
        var collectionUuid = settings.arguments as String;
        return MaterialPageRoute(
          builder: (context) =>
              FlashcardsListScreen(collectionUuid: collectionUuid),
        );
      case Routes.practiceCards:
        final args = settings.arguments;
        if (args is PracticeArgs) {
          return MaterialPageRoute(
            builder: (context) => PracticeCardsScreen(
              collection: args.collection,
            ),
          );
        }
        return MaterialPageRoute(
          builder: (context) => PracticeCardsScreen(
            collection: args as FlashcardCollection,
          ),
        );
      case Routes.reviewResult:
        var cardAndCollection = settings.arguments as (
          Flashcard card,
          FlashcardCollection collection
        );
        return MaterialPageRoute(
          builder: (context) => ReviewResultScreen(
            cardAndCollection: cardAndCollection,
          ),
        );
      case Routes.editFlashcard:
        var parameters = settings.arguments as EditFlashcardParameters;
        return MaterialPageRoute(
            builder: (context) => EditFlashcardScreen(
                  parameters: parameters,
                ));
      case Routes.quiz:
        final args = settings.arguments;
        return MaterialPageRoute(
            builder: (context) => MultipleChoiceQuizScreen(
                  args: args is QuizArgs ? args : null,
                ));
      case Routes.generatedFlashcards:
        var collectionUuid = settings.arguments as String;
        return MaterialPageRoute(
            builder: (context) =>
                GeneratedFlashcardsScreen(collectionUuid: collectionUuid));
      case Routes.writingQuiz:
        final args = settings.arguments;
        if (args is QuizArgs) {
          final cards = [...args.collection.cards];
          if (args.shuffle) cards.shuffle();
          return MaterialPageRoute(
            builder: (context) => WritingQuizScreen(
              flashcards: cards,
            ),
          );
        }
        return MaterialPageRoute(
          builder: (context) =>
              WritingQuizScreen(flashcards: args as List<Flashcard>),
        );
      case Routes.settings:
        return MaterialPageRoute(builder: (context) => const SettingsScreen());
      default:
        return MaterialPageRoute(
          builder: (context) => const CustomErrorWidget(),
        );
    }
  }
}
