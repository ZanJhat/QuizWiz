// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:quizwiz/src/features/cards/data/data.dart';
import 'package:quizwiz/src/features/cards/presentation/presentation.dart';
import 'package:quizwiz/src/features/cards/presentation/widgets/attachments/card_attachments_view.dart';

class MultipleChoiceQuizBody extends StatelessWidget {
  final List<MultipleChoiceQuiz> quiz;
  final PageController controller;
  final bool showCorrectAnswer;
  final int? selectedOption;
  final Map<int, int> selectedGroupOptions;
  final int? revealedGroupIndex;
  final double questionFontSize;
  final void Function(int cardIndex, int childIndex, int choiceSlotIndex,
      List<MultipleChoiceQuiz> quiz) onTap;
  final Future<void> Function(int cardIndex, List<MultipleChoiceQuiz> quiz)
      onSubmitGroup;
  final void Function(int cardIndex, List<MultipleChoiceQuiz> quiz) onNextGroup;
  final void Function(int cardIndex, List<MultipleChoiceQuiz> quiz) onNextCard;

  const MultipleChoiceQuizBody({
    Key? key,
    required this.quiz,
    required this.controller,
    required this.showCorrectAnswer,
    required this.onTap,
    required this.onSubmitGroup,
    required this.onNextGroup,
    required this.onNextCard,
    required this.questionFontSize,
    this.selectedOption,
    this.selectedGroupOptions = const {},
    this.revealedGroupIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (quiz.isEmpty) {
      return const Center(child: Text('Không còn câu hỏi'));
    }
    return PageView.builder(
      controller: controller,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: quiz.length,
      itemBuilder: (context, index) => quiz[index].isGroup
          ? _groupPage(context, index)
          : _singlePage(context, index),
    );
  }

  Widget _singlePage(BuildContext context, int index) {
    final question = quiz[index];
    return LayoutBuilder(
      builder: (context, constraints) => ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          _questionTitle(context, question.question, questionFontSize),
          CardAttachmentsView(
              attachments: question.card?.attachments ?? const []),
          const SizedBox(height: 8),
          ...List.generate(question.options.length, (optionIndex) {
            final option = question.options[optionIndex];
            final slotIndex = question.slotIndexAt(optionIndex);
            Color? color;
            if (showCorrectAnswer) {
              if (slotIndex == question.correctSlotIndex) {
                color = Colors.green;
              } else if (slotIndex == selectedOption) {
                color = Colors.red;
              }
            }
            return _optionTile(
              context: context,
              width: constraints.maxWidth,
              option: option,
              slotIndex: slotIndex,
              color: color,
              onTap: () => onTap(index, 0, slotIndex, quiz),
            );
          }),
          if (showCorrectAnswer) CardNoteView(note: question.card?.note ?? ''),
          if (showCorrectAnswer)
            FilledButton.icon(
              onPressed: () => onNextCard(index, quiz),
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Card tiếp theo'),
            ),
        ],
      ),
    );
  }

  Widget _groupPage(BuildContext context, int cardIndex) {
    final group = quiz[cardIndex];
    final revealed = revealedGroupIndex == cardIndex;
    final answeredAll = List.generate(group.children.length, (index) => index)
        .every(selectedGroupOptions.containsKey);
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      children: [
        _questionTitle(context, group.question, questionFontSize),
        CardAttachmentsView(attachments: group.card?.attachments ?? const []),
        const SizedBox(height: 8),
        ...List.generate(group.children.length, (childIndex) {
          final child = group.children[childIndex];
          final selected = selectedGroupOptions[childIndex];
          return Card(
            margin: const EdgeInsets.only(bottom: 14),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Câu hỏi ${childIndex + 1}\n${child.question}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: questionFontSize,
                        ),
                  ),
                  if (child.card?.attachments.isNotEmpty == true &&
                      !_sameAttachments(
                        child.card!.attachments,
                        group.card?.attachments ?? const [],
                      ))
                    CardAttachmentsView(attachments: child.card!.attachments),
                  ...List.generate(child.options.length, (optionIndex) {
                    final option = child.options[optionIndex];
                    final slotIndex = child.slotIndexAt(optionIndex);
                    Color? color;
                    if (revealed) {
                      if (slotIndex == child.correctSlotIndex) {
                        color = Colors.green;
                      } else if (slotIndex == selected) {
                        color = Colors.red;
                      }
                    } else if (slotIndex == selected) {
                      color = Theme.of(context).colorScheme.primaryContainer;
                    }
                    return _optionTile(
                      context: context,
                      width: double.infinity,
                      option: option,
                      slotIndex: slotIndex,
                      color: color,
                      onTap: revealed
                          ? null
                          : () => onTap(cardIndex, childIndex, slotIndex, quiz),
                    );
                  }),
                  if (revealed) CardNoteView(note: child.card?.note ?? ''),
                ],
              ),
            ),
          );
        }),
        if (revealed) CardNoteView(note: group.card?.note ?? ''),
        if (!revealed)
          FilledButton.icon(
            onPressed:
                answeredAll ? () => onSubmitGroup(cardIndex, quiz) : null,
            icon: const Icon(Icons.check),
            label: const Text('Kiểm tra cả nhóm'),
          )
        else
          FilledButton.icon(
            onPressed: () => onNextGroup(cardIndex, quiz),
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Card tiếp theo'),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _questionTitle(
          BuildContext context, String question, double fontSize) =>
      Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          question,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontSize: fontSize,
              ),
        ),
      );

  Widget _optionTile({
    required BuildContext context,
    required double width,
    required String option,
    required int slotIndex,
    required Color? color,
    required VoidCallback? onTap,
  }) {
    final letter = String.fromCharCode(65 + slotIndex);
    return InkWell(
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        margin: const EdgeInsets.symmetric(vertical: 4),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color ?? Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          option.isEmpty ? letter : '$letter. $option',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

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
}
