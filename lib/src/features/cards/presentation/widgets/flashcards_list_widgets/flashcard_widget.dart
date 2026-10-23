import 'package:flutter/material.dart';
import 'package:jiffy/jiffy.dart';
import 'package:quizwiz/src/features/cards/data/data.dart';

class FlashcardWidget extends StatelessWidget {
  final Flashcard card;
  const FlashcardWidget({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              card.question,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (card.tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Wrap(
                  spacing: 4,
                  runSpacing: 2,
                  children: card.tags
                      .map((tag) => Chip(
                            label: Text(tag),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ))
                      .toList(),
                ),
              ),
            if (card.isGroup)
              Text('${card.children.length} câu hỏi con')
            else
              Text(card.answer),
            if (card.hasFixedChoices)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  card.choices
                      .asMap()
                      .entries
                      .where((e) => e.value.trim().isNotEmpty)
                      .map((e) {
                    final letter = String.fromCharCode(65 + e.key);
                    return '$letter. ${e.value.trim()}';
                  }).join('   '),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            if (card.attachments.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${card.attachments.length} tệp đính kèm',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                'review due: ${Jiffy.parseFromDateTime(DateTime.fromMillisecondsSinceEpoch(card.dueTime)).MEd}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            )
          ],
        ),
      ),
    );
  }
}
