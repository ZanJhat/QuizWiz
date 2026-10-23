import 'package:flutter/material.dart';

class CustomForms extends StatelessWidget {
  final TextEditingController questionController;
  final TextEditingController answerController;
  final TextEditingController? noteController;
  final GlobalKey<FormState> formKey;
  const CustomForms(
      {super.key,
      required this.questionController,
      required this.answerController,
      this.noteController,
      required this.formKey});

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          TextFormField(
            key: const Key("question"),
            controller: questionController,
            maxLines: 2,
            minLines: 1,
            validator: (value) => value?.trim().isEmpty != false
                ? 'Nhập nội dung câu hỏi.'
                : null,
            decoration: const InputDecoration(
              label: Text("Term (question)"),
            ),
          ),
          const SizedBox(
            height: 30,
          ),
          TextFormField(
            key: const Key("answer"),
            maxLines: 4,
            minLines: 1,
            controller: answerController,
            decoration: const InputDecoration(
              label: Text("Writing answer (optional)"),
            ),
          ),
          if (noteController != null) ...[
            const SizedBox(height: 20),
            TextFormField(
              key: const Key('note'),
              controller: noteController,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Note (không bắt buộc)',
                hintText: 'Đáp án nghe, hội thoại hoặc giải thích',
              ),
            ),
          ],
        ],
      ),
    );
  }
}
