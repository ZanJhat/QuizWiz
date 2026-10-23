import 'package:quizwiz/src/core/core.dart';
import 'package:quizwiz/src/core/services/quiz_feedback.dart';
import 'package:quizwiz/src/features/cards/controller/controller.dart';
import 'package:quizwiz/src/features/cards/data/data.dart';
import 'package:quizwiz/src/features/cards/presentation/presentation.dart';

class MultipleChoiceQuizScreen extends StatefulWidget {
  final QuizArgs? args;
  const MultipleChoiceQuizScreen({super.key, this.args});

  @override
  State<MultipleChoiceQuizScreen> createState() =>
      _MultipleChoiceQuizScreenState();
}

class _MultipleChoiceQuizScreenState extends State<MultipleChoiceQuizScreen> {
  bool showCorrectAnswer = false;
  late final PageController _controller;
  final int _slideDuration = 400;
  int? _selected;
  final Map<int, int> _groupSelections = {};
  int? _revealedGroupIndex;
  QuizDisplaySettings _displaySettings = const QuizDisplaySettings();

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _loadDisplaySettings();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.multipleChoice),
      ),
      body: BlocBuilder<CardsBloc, CardsState>(
        builder: (context, state) {
          switch (state.quizRequestState) {
            case RequestState.loading:
              return const LoadingWidget();
            case RequestState.error:
              return CustomErrorWidget(
                errorMessage: state.quizErrorMessage,
              );
            case RequestState.success:
              return MultipleChoiceQuizBody(
                  quiz: state.multipleChoices,
                  controller: _controller,
                  showCorrectAnswer: showCorrectAnswer,
                  selectedOption: _selected,
                  selectedGroupOptions: _groupSelections,
                  revealedGroupIndex: _revealedGroupIndex,
                  questionFontSize: _displaySettings.practiceQuestionSize,
                  onTap: _onTap,
                  onSubmitGroup: _submitGroup,
                  onNextGroup: _nextGroup,
                  onNextCard: _nextCard);
          }
        },
      ),
    );
  }

  Future<void> _onTap(int index, int childIndex, int choiceSlotIndex,
      List<MultipleChoiceQuiz> quiz) async {
    final current = quiz[index];
    if (current.isGroup) {
      if (_revealedGroupIndex == index) return;
      setState(() => _groupSelections[childIndex] = choiceSlotIndex);
      return;
    }
    if (showCorrectAnswer) return;
    final isCorrect = choiceSlotIndex == current.correctSlotIndex;
    if (isCorrect) {
      await QuizFeedback.correct();
    } else {
      await QuizFeedback.wrong();
    }
    setState(() {
      showCorrectAnswer = true;
      _selected = choiceSlotIndex;
    });
  }

  Future<void> _submitGroup(int index, List<MultipleChoiceQuiz> quiz) async {
    if (_revealedGroupIndex == index) return;
    final group = quiz[index];
    for (var childIndex = 0; childIndex < group.children.length; childIndex++) {
      final child = group.children[childIndex];
      final selected = _groupSelections[childIndex];
      if (selected == null) return;
      if (selected == child.correctSlotIndex) {
        await QuizFeedback.correct();
      } else {
        await QuizFeedback.wrong();
      }
    }
    if (!mounted) return;
    setState(() => _revealedGroupIndex = index);
  }

  void _nextGroup(int index, List<MultipleChoiceQuiz> quiz) {
    if (index == quiz.length - 1) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    setState(() {
      _groupSelections.clear();
      _revealedGroupIndex = null;
    });
    _controller.nextPage(
      duration: Duration(milliseconds: _slideDuration),
      curve: Curves.easeInOut,
    );
  }

  void _nextCard(int index, List<MultipleChoiceQuiz> quiz) {
    if (index == quiz.length - 1) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    setState(() {
      showCorrectAnswer = false;
      _selected = null;
    });
    _controller.nextPage(
      duration: Duration(milliseconds: _slideDuration),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _loadDisplaySettings() async {
    try {
      final settings = await QuizDisplaySettingsStore.load();
      if (mounted) setState(() => _displaySettings = settings);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tải được cỡ chữ đã lưu: $error')),
      );
    }
  }
}
