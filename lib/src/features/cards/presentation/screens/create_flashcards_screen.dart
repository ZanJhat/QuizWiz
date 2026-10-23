import 'package:file_picker/file_picker.dart';
import 'dart:async';
import 'dart:io';
import 'package:quizwiz/src/core/core.dart';
import 'package:quizwiz/src/features/cards/controller/controller.dart';
import 'package:quizwiz/src/features/cards/data/data.dart';
import 'package:quizwiz/src/features/cards/presentation/presentation.dart';
import 'package:quizwiz/src/features/cards/presentation/widgets/attachments/card_attachments_editor.dart';
import 'package:quizwiz/src/features/cards/presentation/widgets/create_flashcards_widgets/choices_editor.dart';
import 'package:quizwiz/src/features/cards/presentation/widgets/tags_editor.dart';
import 'package:uuid/uuid.dart';

class CreateFlashcardsScreen extends StatefulWidget {
  final String collectionUuid;
  const CreateFlashcardsScreen({
    super.key,
    required this.collectionUuid,
  });

  @override
  State<CreateFlashcardsScreen> createState() => _CreateFlashcardsScreenState();
}

class _CreateFlashcardsScreenState extends State<CreateFlashcardsScreen> {
  late final TextEditingController questionController;
  late final TextEditingController answerController;
  late final TextEditingController noteController;
  late final String _cardUuid;
  final key = GlobalKey<FormState>();
  final List<TextEditingController> _choiceControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];
  int _correctIndex = 0;
  List<CardAttachment> _attachments = [];
  List<String> _tags = [];
  final List<_ChildQuestionDraft> _children = [];
  bool _groupMode = false;
  bool _saving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    questionController = TextEditingController();
    answerController = TextEditingController();
    noteController = TextEditingController();
    _cardUuid = const Uuid().v4();
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

  List<String> get _choices =>
      _choiceControllers.map((c) => c.text.trim()).toList();

  Future<void> _saveFlashcard({required bool addAnother}) async {
    if (_saving) return;
    FocusScope.of(context).unfocus();
    if (questionController.text.trim().isEmpty) {
      key.currentState?.validate();
      return;
    }

    if (_groupMode && _children.isEmpty) {
      setState(() => _saveError = 'Thêm ít nhất một câu hỏi con.');
      return;
    }
    final invalidChildren = <int>[];
    for (var i = 0; i < _children.length; i++) {
      final draft = _children[i];
      draft.questionError = _groupMode && draft.question.text.trim().isEmpty
          ? 'Nhập câu hỏi hoặc xóa câu hỏi con này.'
          : null;
      if (draft.questionError != null) invalidChildren.add(i + 1);
    }
    if (invalidChildren.isNotEmpty) {
      setState(() => _saveError =
          'Câu hỏi con ${invalidChildren.join(', ')} còn trống. Hãy bổ sung nội dung hoặc xóa câu đó.');
      return;
    }

    final choices = _choices;
    final completer = Completer<String?>();
    setState(() {
      _saving = true;
      _saveError = null;
    });
    context.read<CardsBloc>().add(AddFlashcardsEvent(
          collectionUuid: widget.collectionUuid,
          question: questionController.text.trim(),
          answer: answerController.text.trim(),
          note: noteController.text.trim(),
          choices: choices,
          correctChoiceIndex:
              _correctIndex.clamp(0, choices.length - 1).toInt(),
          attachments: _attachments,
          tags: _tags,
          children: _groupMode
              ? _children
                  .map((child) => Flashcard(
                        uuid: child.uuid,
                        question: child.question.text.trim(),
                        answer: child.answer.text.trim(),
                        note: child.note.text.trim(),
                        choices: child.choiceControllers
                            .map((controller) => controller.text.trim())
                            .toList(),
                        correctChoiceIndex: child.correctIndex
                            .clamp(0, child.choiceControllers.length - 1)
                            .toInt(),
                        attachments: child.attachments,
                      ))
                  .toList()
              : const [],
          uuid: _cardUuid,
          completer: completer,
        ));

    final error = await completer.future;
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      setState(() => _saveError =
          'Không lưu được card: $error\nKiểm tra thông tin và thử lại.');
      return;
    }
    Navigator.of(context).pushReplacementNamed(
      addAnother ? Routes.createFlashcards : Routes.flashcardsList,
      arguments: widget.collectionUuid,
    );
  }

  Future<void> _generateWithAi() async {
    GeminiSettings settings;
    try {
      settings = await GeminiSettingsStore.load();
    } catch (error) {
      if (mounted) {
        customSnackBar(
          'Không đọc được file cấu hình Gemini. Hãy kiểm tra hoặc lưu lại cấu hình trong Cài đặt: $error',
          context,
        );
      }
      return;
    }
    if (!mounted) return;
    if (settings.apiKey.isEmpty) {
      final navigator = Navigator.of(context);
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Gemini AI chưa được cấu hình'),
          content: const Text(
            'Hãy nhập Gemini API key trong Cài đặt trước khi tạo card bằng AI.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(AppStrings.cancel),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                navigator.pushNamed(Routes.settings);
              },
              child: const Text('Mở Cài đặt'),
            ),
          ],
        ),
      );
      return;
    }

    final promptController = TextEditingController();
    final selectedFiles = <File>[];
    final request = await showDialog<({String prompt, List<File> files})>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Tạo card bằng AI'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: promptController,
                  minLines: 4,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    labelText: 'Câu lệnh',
                    hintText:
                        'Mô tả nội dung và kiểu card cần tạo. Ví dụ: Tạo 10 card trắc nghiệm từ tài liệu, tập trung vào các khái niệm chính.',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Tệp đính kèm (${selectedFiles.length}/5)',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                for (var index = 0; index < selectedFiles.length; index++)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.insert_drive_file_outlined),
                    title: Text(
                      selectedFiles[index].uri.pathSegments.last,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      tooltip: 'Xóa tệp',
                      onPressed: () => setDialogState(() {
                        selectedFiles.removeAt(index);
                      }),
                      icon: const Icon(Icons.close),
                    ),
                  ),
                OutlinedButton.icon(
                  onPressed: selectedFiles.length >= 5
                      ? null
                      : () async {
                          final result = await FilePicker.pickFiles(
                            type: FileType.any,
                            allowMultiple: true,
                          );
                          if (result == null) return;
                          if (!context.mounted) return;
                          final remaining = 5 - selectedFiles.length;
                          final picked = result.files
                              .where((item) => item.path != null)
                              .take(remaining)
                              .map((item) => File(item.path!))
                              .toList();
                          if (picked.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Không đọc được đường dẫn tệp đã chọn.',
                                ),
                              ),
                            );
                            return;
                          }
                          setDialogState(() => selectedFiles.addAll(picked));
                          if (result.files.length > remaining) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Chỉ được đính kèm tối đa 5 tệp.'),
                              ),
                            );
                          }
                        },
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Tải tệp lên (tối đa 5)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(AppStrings.cancel)),
            FilledButton(
              onPressed: () {
                if (promptController.text.trim().isEmpty &&
                    selectedFiles.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Nhập câu lệnh hoặc tải lên ít nhất một tệp.'),
                    ),
                  );
                  return;
                }
                Navigator.pop(
                  context,
                  (
                    prompt: promptController.text.trim(),
                    files: List<File>.of(selectedFiles),
                  ),
                );
              },
              child: const Text('Tạo'),
            ),
          ],
        ),
      ),
    );
    promptController.dispose();
    if (request == null) return;
    if (!mounted) return;
    context.read<CardsBloc>().add(GenerateFlashcardsEvent(
          files: request.files,
          prompt: request.prompt,
        ));
    Navigator.of(context).pushReplacementNamed(Routes.generatedFlashcards,
        arguments: widget.collectionUuid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.createFlashcards),
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            CustomForms(
                formKey: key,
                questionController: questionController,
                answerController: answerController,
                noteController: noteController),
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
              collectionUuid: widget.collectionUuid,
              cardUuid: _cardUuid,
              attachments: _attachments,
              onChanged: (items) => setState(() => _attachments = items),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Nhóm nhiều câu hỏi'),
              subtitle: const Text('Dùng cho bài nghe, video hoặc bài đọc'),
              value: _groupMode,
              onChanged: (value) => setState(() {
                _groupMode = value;
                if (value && _children.isEmpty) {
                  _children.add(_ChildQuestionDraft());
                }
              }),
            ),
            if (_groupMode) ...[
              for (var index = 0; index < _children.length; index++)
                _childEditor(index),
              OutlinedButton.icon(
                onPressed: () =>
                    setState(() => _children.add(_ChildQuestionDraft())),
                icon: const Icon(Icons.add),
                label: const Text('Thêm câu hỏi con'),
              ),
            ],
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
            const SizedBox(height: 12),
            TextButton.icon(
                key: const Key(AppStrings.generateWithAI),
                onPressed: _generateWithAi,
                icon: const Icon(Icons.rocket),
                label: const Text(AppStrings.generateWithAI)),
            const SizedBox(height: 12),
            FilledButton(
                key: const Key(AppStrings.addCard),
                onPressed:
                    _saving ? null : () => _saveFlashcard(addAnother: false),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(AppStrings.addCard)),
            const SizedBox(height: 12),
            FilledButton(
                key: const Key(AppStrings.addAnotherCard),
                onPressed:
                    _saving ? null : () => _saveFlashcard(addAnother: true),
                child: const Text(AppStrings.addAnotherCard)),
            const SizedBox(height: 24),
          ],
        ));
  }

  Widget _childEditor(int index) {
    final child = _children[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Expanded(
                  child: Text('Câu hỏi ${index + 1}',
                      style: Theme.of(context).textTheme.titleMedium)),
              if (_children.length > 1)
                IconButton(
                    onPressed: () =>
                        setState(() => _children.removeAt(index).dispose()),
                    icon: const Icon(Icons.delete_outline)),
            ]),
            TextField(
              controller: child.question,
              onChanged: (_) {
                if (child.questionError != null) {
                  setState(() => child.questionError = null);
                }
              },
              decoration: InputDecoration(
                labelText: 'Câu hỏi',
                errorText: child.questionError,
              ),
            ),
            TextField(
                controller: child.answer,
                decoration: const InputDecoration(
                    labelText: 'Đáp án (không bắt buộc)')),
            TextField(
                controller: child.note,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                    labelText: 'Note (không bắt buộc)',
                    hintText: 'Đáp án nghe, hội thoại hoặc giải thích')),
            for (var i = 0; i < child.choiceControllers.length; i++)
              Row(children: [
                Radio<int>(
                  value: i,
                  groupValue: child.correctIndex,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => child.correctIndex = value);
                    }
                  },
                ),
                Expanded(
                    child: TextField(
                        controller: child.choiceControllers[i],
                        decoration: InputDecoration(
                            labelText:
                                'Lựa chọn ${String.fromCharCode(65 + i)}'))),
              ]),
            CardAttachmentsEditor(
              collectionUuid: widget.collectionUuid,
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

class _ChildQuestionDraft {
  final String uuid = const Uuid().v4();
  final question = TextEditingController();
  final answer = TextEditingController();
  final note = TextEditingController();
  final choiceControllers = List.generate(4, (_) => TextEditingController());
  int correctIndex = 0;
  List<CardAttachment> attachments = [];
  String? questionError;

  void dispose() {
    question.dispose();
    answer.dispose();
    note.dispose();
    for (final controller in choiceControllers) {
      controller.dispose();
    }
  }
}
