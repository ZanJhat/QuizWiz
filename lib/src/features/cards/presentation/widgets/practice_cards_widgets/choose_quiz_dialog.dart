// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:quizwiz/src/core/core.dart';
import 'package:quizwiz/src/features/cards/controller/controller.dart';
import 'package:quizwiz/src/features/cards/data/data.dart';
import 'package:quizwiz/src/features/cards/presentation/widgets/practice_cards_widgets/choose_order_dialog.dart';

class ChooseQuizDialog extends StatelessWidget {
  final FlashcardCollection collection;
  const ChooseQuizDialog({
    Key? key,
    required this.collection,
  }) : super(key: key);

  bool get _canTakeMcq {
    return collection.cards.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text(AppStrings.quizType),
      alignment: Alignment.center,
      contentPadding: const EdgeInsets.all(25),
      children: [
        Column(
          children: [
            CustomListTile(
                text: AppStrings.multipleChoice,
                icon: Icons.quiz,
                onPressed: () async {
                  if (!_canTakeMcq) {
                    customSnackBar("Collection chưa có card nào", context);
                    Navigator.of(context).pop();
                    return;
                  }
                  final shuffle = await showDialog<bool>(
                    context: context,
                    builder: (_) => const ChooseOrderDialog(),
                  );
                  if (shuffle == null || !context.mounted) return;
                  final navigator = Navigator.of(context);
                  final cardsBloc = context.read<CardsBloc>();
                  navigator.pop();
                  cardsBloc.add(GetMultipleQuizOptionsEvent(
                    collection: collection,
                    shuffle: shuffle,
                  ));
                  navigator.pushNamed(
                    Routes.quiz,
                    arguments:
                        QuizArgs(collection: collection, shuffle: shuffle),
                  );
                }),
            CustomListTile(
                text: AppStrings.writingQuiz,
                icon: Icons.edit,
                onPressed: () async {
                  final shuffle = await showDialog<bool>(
                    context: context,
                    builder: (_) => const ChooseOrderDialog(),
                  );
                  if (shuffle == null || !context.mounted) return;
                  final navigator = Navigator.of(context);
                  navigator.pop();
                  navigator.pushNamed(
                    Routes.writingQuiz,
                    arguments:
                        QuizArgs(collection: collection, shuffle: shuffle),
                  );
                }),
          ],
        )
      ],
    );
  }
}

class CustomListTile extends StatelessWidget {
  final String text;
  final IconData icon;
  final Function() onPressed;
  const CustomListTile({
    Key? key,
    required this.text,
    required this.icon,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: ListTile(
        leading: Icon(icon),
        title: Text(text),
      ),
    );
  }
}
