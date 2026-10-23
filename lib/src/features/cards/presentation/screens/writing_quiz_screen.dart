import 'package:quizwiz/src/core/core.dart';
import 'package:quizwiz/src/core/services/quiz_feedback.dart';
import 'package:quizwiz/src/features/cards/data/data.dart';
import 'package:quizwiz/src/features/cards/presentation/presentation.dart';
import 'package:quizwiz/src/features/cards/presentation/widgets/attachments/card_attachments_view.dart';

class WritingQuizScreen extends StatefulWidget {
  final List<Flashcard> flashcards;
  const WritingQuizScreen({
    super.key,
    required this.flashcards,
  });

  @override
  State<WritingQuizScreen> createState() => _WritingQuizScreenState();
}

class _WritingQuizScreenState extends State<WritingQuizScreen> {
  late final PageController _pageController;
  late final List<Flashcard> _cards;
  final Map<String, TextEditingController> _answerControllers = {};
  final Set<int> _revealedCards = {};
  QuizDisplaySettings _displaySettings = const QuizDisplaySettings();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadDisplaySettings();
    _cards = widget.flashcards;
    for (var cardIndex = 0; cardIndex < _cards.length; cardIndex++) {
      final card = _cards[cardIndex];
      final questions = card.isGroup ? card.children : [card];
      for (var questionIndex = 0;
          questionIndex < questions.length;
          questionIndex++) {
        _answerControllers[_answerKey(cardIndex, questionIndex)] =
            TextEditingController();
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final controller in _answerControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.writingQuiz)),
      body: _cards.isEmpty
          ? const Center(child: Text('Không còn câu hỏi'))
          : PageView.builder(
              physics: const NeverScrollableScrollPhysics(),
              controller: _pageController,
              itemCount: _cards.length,
              itemBuilder: (context, index) => _cardPage(index, _cards[index]),
            ),
    );
  }

  Widget _cardPage(int cardIndex, Flashcard card) {
    final revealed = _revealedCards.contains(cardIndex);
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              card.question,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontSize: _displaySettings.practiceQuestionSize,
                  ),
            ),
            const SizedBox(height: 12),
            CardAttachmentsView(attachments: card.attachments),
            if (card.isGroup) ...[
              const SizedBox(height: 12),
              ...List.generate(card.children.length, (questionIndex) {
                final child = card.children[questionIndex];
                return _answerEditor(
                  cardIndex: cardIndex,
                  questionIndex: questionIndex,
                  card: child,
                  label: 'Câu hỏi ${questionIndex + 1}',
                  revealed: revealed,
                  showChildAttachments: child.attachments.isNotEmpty &&
                      !_sameAttachments(child.attachments, card.attachments),
                );
              }),
              if (revealed) CardNoteView(note: card.note),
              if (!revealed)
                FilledButton.icon(
                  onPressed: () => _checkGroup(cardIndex, card),
                  icon: const Icon(Icons.check),
                  label: const Text('Kiểm tra cả nhóm'),
                )
              else
                FilledButton.icon(
                  onPressed: () => _nextCard(cardIndex),
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Card tiếp theo'),
                ),
            ] else ...[
              const SizedBox(height: 24),
              _answerEditor(
                cardIndex: cardIndex,
                questionIndex: 0,
                card: card,
                label: 'Đáp án của bạn',
                revealed: revealed,
              ),
              if (revealed)
                FilledButton.icon(
                  onPressed: () => _nextCard(cardIndex),
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Next'),
                )
              else
                FilledButton.icon(
                  onPressed: () => _checkSingle(cardIndex, card),
                  icon: const Icon(Icons.check),
                  label: const Text('Kiểm tra đáp án'),
                ),
            ],
            SizedBox(height: constraints.maxHeight * 0.04),
          ],
        ),
      ),
    );
  }

  Widget _answerEditor({
    required int cardIndex,
    required int questionIndex,
    required Flashcard card,
    required String label,
    required bool revealed,
    bool showChildAttachments = false,
  }) {
    final controller =
        _answerControllers[_answerKey(cardIndex, questionIndex)]!;
    final answer = card.writingQuizAnswer;
    final correct = _isCorrect(answer, controller.text);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            if (cardIndex >= 0 && _cards[cardIndex].isGroup) ...[
              const SizedBox(height: 6),
              Text(
                card.question,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: _displaySettings.practiceQuestionSize,
                    ),
              ),
            ],
            if (showChildAttachments)
              CardAttachmentsView(attachments: card.attachments),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              enabled: !revealed,
              minLines: 1,
              maxLines: 3,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                if (!_cards[cardIndex].isGroup) _checkSingle(cardIndex, card);
              },
              decoration: const InputDecoration(
                labelText: 'Nhập đáp án',
                border: OutlineInputBorder(),
              ),
            ),
            if (revealed) ...[
              const SizedBox(height: 12),
              Text(
                'Đáp án: $answer',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                correct ? 'Chính xác' : 'Chưa chính xác',
                style: TextStyle(
                  color: correct ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              CardNoteView(note: card.note),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _checkSingle(int cardIndex, Flashcard card) async {
    if (_revealedCards.contains(cardIndex)) return;
    final controller = _answerControllers[_answerKey(cardIndex, 0)]!;
    if (_isCorrect(card.writingQuizAnswer, controller.text)) {
      await QuizFeedback.correct();
    } else {
      await QuizFeedback.wrong();
    }
    if (!mounted) return;
    setState(() => _revealedCards.add(cardIndex));
  }

  Future<void> _checkGroup(int cardIndex, Flashcard card) async {
    if (_revealedCards.contains(cardIndex)) return;
    for (var questionIndex = 0;
        questionIndex < card.children.length;
        questionIndex++) {
      final child = card.children[questionIndex];
      final controller =
          _answerControllers[_answerKey(cardIndex, questionIndex)]!;
      if (_isCorrect(child.writingQuizAnswer, controller.text)) {
        await QuizFeedback.correct();
      } else {
        await QuizFeedback.wrong();
      }
    }
    if (!mounted) return;
    setState(() => _revealedCards.add(cardIndex));
  }

  void _nextCard(int cardIndex) {
    if (cardIndex == _cards.length - 1) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  String _answerKey(int cardIndex, int questionIndex) =>
      '$cardIndex:$questionIndex';

  bool _isCorrect(String answer, String userInput) =>
      answer.trim().toLowerCase() == userInput.trim().toLowerCase();

  bool _sameAttachments(
      List<CardAttachment> first, List<CardAttachment> second) {
    if (first.length != second.length) return false;
    for (var index = 0; index < first.length; index++) {
      if (first[index].source != second[index].source ||
          first[index].type != second[index].type) {
        return false;
      }
    }
    return true;
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
