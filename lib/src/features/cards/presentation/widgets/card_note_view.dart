import 'package:flutter/material.dart';

class CardNoteView extends StatelessWidget {
  final String note;
  final String title;

  const CardNoteView({
    super.key,
    required this.note,
    this.title = 'Note',
  });

  @override
  Widget build(BuildContext context) {
    final text = note.trim();
    if (text.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(text),
        ],
      ),
    );
  }
}
