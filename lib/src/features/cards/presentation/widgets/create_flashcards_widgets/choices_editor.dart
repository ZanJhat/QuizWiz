import 'package:flutter/material.dart';

class ChoicesEditor extends StatelessWidget {
  final List<TextEditingController> controllers;
  final int correctIndex;
  final ValueChanged<int> onCorrectChanged;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  const ChoicesEditor({
    super.key,
    required this.controllers,
    required this.correctIndex,
    required this.onCorrectChanged,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Lựa chọn trắc nghiệm cố định (A–H)',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Giữ nguyên vị trí A–H, kể cả ô trống. Nếu ô đáp án đúng để trống, Multiple Choice dùng đáp án Writing và bổ sung lựa chọn từ card khác khi có thể. Khi đáp án Writing trống, Writing quiz nhận nội dung ô đúng; nếu ô đó cũng trống thì nhập chữ cái tương ứng.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        ...List.generate(controllers.length, (index) {
          final letter = String.fromCharCode(65 + index);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Radio<int>(
                  value: index,
                  groupValue: correctIndex,
                  onChanged: (value) {
                    if (value != null) onCorrectChanged(value);
                  },
                ),
                Expanded(
                  child: TextFormField(
                    controller: controllers[index],
                    decoration: InputDecoration(
                      labelText: 'Đáp án $letter',
                    ),
                  ),
                ),
                if (controllers.length > 2)
                  IconButton(
                    onPressed: () => onRemove(index),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
              ],
            ),
          );
        }),
        if (controllers.length < 8)
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Thêm lựa chọn'),
          ),
      ],
    );
  }
}
