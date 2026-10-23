// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:quizwiz/src/core/core.dart';
import 'package:quizwiz/src/features/cards/data/data.dart';
import 'package:quizwiz/src/features/cards/presentation/widgets/practice_cards_widgets/choose_quiz_dialog.dart';

class NoFlashcardsToReview extends StatelessWidget {
  final FlashcardCollection collection;
  final VoidCallback onAgain;
  const NoFlashcardsToReview({
    Key? key,
    required this.collection,
    required this.onAgain,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).popUntil((route) => route.isFirst);
        return false;
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Expanded(child: SizedBox()),
          Expanded(child: LottieBuilder.asset(AppStrings.completedTaskAsset)),
          Text(
            AppStrings.noFlashcardsToReview,
            style: Theme.of(context).textTheme.displaySmall,
            textAlign: TextAlign.center,
          ),
          const Expanded(child: SizedBox()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Row(
              children: [
                OutlinedButton.icon(
                    onPressed: onAgain,
                    icon: const Icon(Icons.replay),
                    label: const Text('Again')),
                const Expanded(child: SizedBox()),
                FilledButton.icon(
                    onPressed: () => showDialog(
                        context: context,
                        builder: (context) => ChooseQuizDialog(
                              collection: collection,
                            )),
                    icon: const Icon(Icons.quiz),
                    label: const Text(AppStrings.practice)),
              ],
            ),
          ),
          const SizedBox(
            height: 50,
          )
        ],
      ),
    );
  }
}
