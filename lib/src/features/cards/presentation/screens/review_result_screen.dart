import 'package:auto_size_text/auto_size_text.dart';
import 'package:quizwiz/src/core/core.dart';
import 'package:quizwiz/src/features/cards/controller/controller.dart';
import 'package:quizwiz/src/features/cards/data/data.dart';
import 'package:quizwiz/src/features/cards/presentation/presentation.dart';
import 'package:quizwiz/src/features/cards/presentation/widgets/attachments/card_attachments_view.dart';

class ReviewResultScreen extends StatefulWidget {
  final (Flashcard card, FlashcardCollection collection) cardAndCollection;
  const ReviewResultScreen({super.key, required this.cardAndCollection});

  @override
  State<ReviewResultScreen> createState() => _ReviewResultScreenState();
}

class _ReviewResultScreenState extends State<ReviewResultScreen> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final card = widget.cardAndCollection.$1;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: 104,
        leading: TextButton.icon(
          onPressed: () => _addReview(ReviewResult.again),
          icon: const Icon(Icons.replay, size: 18),
          label: const Text('Again'),
        ),
      ),
      body: LayoutBuilder(builder: (context, size) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Expanded(child: SizedBox()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: size.maxHeight / 5),
                child: AutoSizeText(
                  card.question,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displaySmall,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CardAttachmentsView(attachments: card.attachments),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: size.maxHeight / 3.5),
                child: AutoSizeText(
                  card.writingQuizAnswer,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
            ),
            const Expanded(child: SizedBox()),
            Row(
              children: [
                ReviewBar(
                    color: Colors.red,
                    onTap: () => _addReview(ReviewResult.again),
                    text: "Again"),
                ReviewBar(
                    color: Colors.redAccent,
                    onTap: () => _addReview(ReviewResult.hard),
                    text: "Hard"),
                ReviewBar(
                    color: Colors.green,
                    onTap: () => _addReview(ReviewResult.good),
                    text: "Good"),
                ReviewBar(
                    color: Colors.blue,
                    onTap: () => _addReview(ReviewResult.easy),
                    text: "Easy"),
              ],
            ),
            const SizedBox(
              height: 25,
            )
          ],
        );
      }),
    );
  }

  Future<void> _addReview(ReviewResult result) async {
    if (_saving) return;
    setState(() => _saving = true);
    final card = widget.cardAndCollection.$1;
    final collection = widget.cardAndCollection.$2;
    try {
      if (result == ReviewResult.again) {
        await DailyReviewStore.markAgain(
          collectionUuid: collection.uuid,
          cardUuid: card.uuid,
        );
      } else {
        await DailyReviewStore.markReviewed(
          collectionUuid: collection.uuid,
          cardUuid: card.uuid,
        );
      }
    } catch (_) {
      // Continue scheduling the card if local history storage is unavailable.
    }
    if (!mounted) return;
    context.read<CardsBloc>().add(UpdateDueTimeEvent(
        card: card, collectionUuid: collection.uuid, reviewResult: result));
    Navigator.of(context).pop(result);
  }
}
