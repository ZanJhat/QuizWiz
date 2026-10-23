import 'dart:async';

import 'package:quizwiz/src/core/core.dart';
import 'package:quizwiz/src/features/cards/controller/controller.dart';
import 'package:quizwiz/src/features/cards/data/data.dart';
import 'package:quizwiz/src/features/cards/presentation/presentation.dart';
import 'package:quizwiz/src/features/cards/presentation/widgets/attachments/card_attachments_editor.dart';
import 'package:quizwiz/src/features/cards/presentation/widgets/create_flashcards_widgets/choices_editor.dart';
import 'package:quizwiz/src/features/cards/presentation/widgets/tags_editor.dart';
import 'package:uuid/uuid.dart';

class EditFlashcardScreen extends StatefulWidget {
  final EditFlashcardParameters parameters;
  const EditFlashcardScreen({super.key, required this.parameters});

  @override
  State<EditFlashcardScreen> createState() => _EditFlashcardScreenState();
}

class _EditFlashcardScreenState extends State<EditFlashcardScreen> {
  late final TextEditingController questionController;
  late final TextEditingController answerController;
  late final TextEditingController noteController;
  final key = GlobalKey<FormState>();
  late List<TextEditingController> _choiceControllers;
  late int _correctIndex;
  late List<CardAttachment> _attachments;
  late List<String> _tags;
  late List<_EditableChildQuestionDraft> _children;
  String? _childrenError;
  String? _saveError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    questionController =
        TextEditingController(text: widget.parameters.question);
    answerController = TextEditingController(text: widget.parameters.answer);
    noteController = TextEditingController(
        text: widget.parameters.note ?? widget.parameters.flashcard.note);
    final existing = widget.parameters.flashcard.choices.isNotEmpty
        ? widget.parameters.flashcard.choices
        : widget.parameters.choices;
    final starter = existing.isEmpty ? ['', '', '', ''] : [...existing];
    _correctIndex = widget.parameters.flashcard.resolvedCorrectChoiceIndex;
    _correctIndex = _correctIndex.clamp(0, starter.length - 1).toInt();
    if (starter[_correctIndex].trim().isEmpty &&
        answerController.text.trim().isNotEmpty) {
      starter[_correctIndex] = answerController.text.trim();
    }
    _choiceControllers =
        starter.map((e) => TextEditingController(text: e)).toList();
    if (_choiceControllers.length < 2) {
      _choiceControllers.add(TextEditingController());
    }
    _attachments = widget.parameters.attachments.isNotEmpty
        ? [...widget.parameters.attachments]
        : [...widget.parameters.flashcard.attachments];
    _tags = [...widget.parameters.flashcard.tags];
    _children = widget.parameters.flashcard.children
        .map(_EditableChildQuestionDraft.fromCard)
        .toList();
  }

  @override
  void dispose() {
    questionController.dispose();
    answerController.dispose();
    noteController.dispose();
    for (final c in _choiceControllers) {
      c.dispose();
    }
    for (final child in _children) {
      child.dispose();
    }
    super.dispose();
  }

  Future<void> _editFlashcard() async {
    if (_saving) return;
    FocusScope.of(context).unfocus();
    if (questionController.text.trim().isEmpty) {
      key.currentState?.validate();
      return;
    }

    final invalidChildren =
        _children.where((child) => child.question.text.trim().isEmpty).length;
    if (invalidChildren > 0) {
      setState(() => _childrenError =
          '$invalidChildren câu hỏi con đang để trống. Hãy nhập nội dung hoặc xóa câu đó.');
      return;
    }

    final choices = _choiceControllers.map((c) => c.text.trim()).toList();
    final completer = Completer<String?>();
    setState(() {
      _saving = true;
      _saveError = null;
      _childrenError = null;
    });
    context.read<CardsBloc>().add(EditFlashcardsEvent(
          parameters: widget.parameters.copyWith(
            question: questionController.text.trim(),
            answer: answerController.text.trim(),
            note: noteController.text.trim(),
            choices: choices,
            correctChoiceIndex:
                _correctIndex.clamp(0, choices.length - 1).toInt(),
            attachments: _attachments,
            tags: _tags,
            children: _children.map((child) => child.toFlashcard()).toList(),
          ),
          completer: completer,
        ));

    final error = await completer.future;
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      setState(() => _saveError = 'Không lưu được thay đổi: $error');
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.editFlashcard),
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            CustomForms(
                questionController: questionController,
                answerController: answerController,
                noteController: noteController,
                formKey: key),
            const SizedBox(height: 24),
            ChoicesEditor(
              controllers: _choiceControllers,
              correctIndex: _correctIndex,
              onCorrectChanged: (v) => setState(() => _correctIndex = v),
              onAdd: () => setState(
                  () => _choiceControllers.add(TextEditingController())),
              onRemove: (index) {
                setState(() {
                  _choiceControllers.removeAt(index).dispose();
                  if (index < _correctIndex) {
                    _correctIndex--;
                  } else if (_correctIndex >= _choiceControllers.length) {
                    _correctIndex = _choiceControllers.length - 1;
                  }
                });
              },
            ),
            const SizedBox(height: 12),
            TagsEditor(
              tags: _tags,
              onChanged: (tags) => setState(() => _tags = tags),
            ),
            const SizedBox(height: 16),
            CardAttachmentsEditor(
              collectionUuid: widget.parameters.collection.uuid,
              cardUuid: widget.parameters.flashcard.uuid,
              attachments: _attachments,
              onChanged: (items) => setState(() => _attachments = items),
            ),
            const SizedBox(height: 20),
            Text('Câu hỏi con', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (_childrenError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _childrenError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (_children.isEmpty) const Text('Card này chưa có câu hỏi con.'),
            for (var index = 0; index < _children.length; index++)
              _childEditor(index),
            OutlinedButton.icon(
              onPressed: () => setState(() {
                _children.add(_EditableChildQuestionDraft());
                _childrenError = null;
              }),
              icon: const Icon(Icons.add),
              label: const Text('Thêm câu hỏi con'),
            ),
            if (_saveError != null) ...[
              const SizedBox(height: 12),
              Material(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _saveError!,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
                key: const Key(AppStrings.editFlashcard),
                onPressed: _saving ? null : _editFlashcard,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(AppStrings.editFlashcard)),
            const SizedBox(height: 20),
          ],
        ));
  }

  Widget _childEditor(int index) {
    final child = _children[index];
    return Card(
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Câu hỏi ${index + 1}',
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                IconButton(
                  tooltip: 'Xóa câu hỏi con',
                  onPressed: () => setState(() {
                    _children.removeAt(index).dispose();
                    _childrenError = null;
                  }),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            TextField(
              controller: child.question,
              onChanged: (_) => setState(() => _childrenError = null),
              decoration: const InputDecoration(labelText: 'Câu hỏi'),
            ),
            TextField(
              controller: child.answer,
              decoration:
                  const InputDecoration(labelText: 'Đáp án Writing (tùy chọn)'),
            ),
            TextField(
              controller: child.note,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Note (không bắt buộc)',
                hintText: 'Đáp án nghe, hội thoại hoặc giải thích',
              ),
            ),
            for (var choiceIndex = 0;
                choiceIndex < child.choiceControllers.length;
                choiceIndex++)
              Row(
                children: [
                  Radio<int>(
                    value: choiceIndex,
                    groupValue: child.correctIndex,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => child.correctIndex = value);
                      }
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: child.choiceControllers[choiceIndex],
                      decoration: InputDecoration(
                        labelText:
                            'Lựa chọn ${String.fromCharCode(65 + choiceIndex)}',
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Xóa lựa chọn',
                    onPressed: child.choiceControllers.length <= 2
                        ? null
                        : () => setState(() {
                              child.choiceControllers
                                  .removeAt(choiceIndex)
                                  .dispose();
                              if (choiceIndex < child.correctIndex) {
                                child.correctIndex--;
                              } else if (child.correctIndex >=
                                  child.choiceControllers.length) {
                                child.correctIndex =
                                    child.choiceControllers.length - 1;
                              }
                            }),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                ],
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(
                    () => child.choiceControllers.add(TextEditingController())),
                icon: const Icon(Icons.add),
                label: const Text('Thêm lựa chọn'),
              ),
            ),
            CardAttachmentsEditor(
              collectionUuid: widget.parameters.collection.uuid,
              cardUuid: child.uuid,
              attachments: child.attachments,
              onChanged: (attachments) =>
                  setState(() => child.attachments = attachments),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditableChildQuestionDraft {
  final Flashcard? original;
  final String uuid;
  final TextEditingController question;
  final TextEditingController answer;
  final TextEditingController note;
  final List<TextEditingController> choiceControllers;
  int correctIndex;
  List<CardAttachment> attachments;

  _EditableChildQuestionDraft({Flashcard? original})
      : original = original,
        uuid = original?.uuid.isNotEmpty == true
            ? original!.uuid
            : const Uuid().v4(),
        question = TextEditingController(text: original?.question ?? ''),
        answer = TextEditingController(text: original?.answer ?? ''),
        note = TextEditingController(text: original?.note ?? ''),
        choiceControllers = (original?.choices.isNotEmpty == true
                ? original!.choices
                : List<String>.filled(4, ''))
            .map((choice) => TextEditingController(text: choice))
            .toList(),
        correctIndex = original?.resolvedCorrectChoiceIndex ?? 0,
        attachments = [...?original?.attachments] {
    if (choiceControllers.length < 2) {
      choiceControllers.add(TextEditingController());
    }
    correctIndex = correctIndex.clamp(0, choiceControllers.length - 1).toInt();
    if (choiceControllers[correctIndex].text.trim().isEmpty &&
        original?.answer.trim().isNotEmpty == true) {
      choiceControllers[correctIndex].text = original!.answer.trim();
    }
  }

  factory _EditableChildQuestionDraft.fromCard(Flashcard card) =>
      _EditableChildQuestionDraft(original: card);

  Flashcard toFlashcard() {
    final base = original ??
        Flashcard(
          uuid: uuid,
          dueTime: DateTime.now().millisecondsSinceEpoch,
        );
    return base.copyWith(
      uuid: uuid,
      question: question.text.trim(),
      answer: answer.text.trim(),
      note: note.text.trim(),
      choices: choiceControllers.map((choice) => choice.text.trim()).toList(),
      correctChoiceIndex:
          correctIndex.clamp(0, choiceControllers.length - 1).toInt(),
      attachments: attachments,
    );
  }

  void dispose() {
    question.dispose();
    answer.dispose();
    note.dispose();
    for (final choice in choiceControllers) {
      choice.dispose();
    }
  }
}
