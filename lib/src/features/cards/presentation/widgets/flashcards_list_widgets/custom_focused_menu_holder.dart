import 'package:flutter/material.dart';
import 'package:focused_menu/focused_menu.dart';
import 'package:focused_menu/modals.dart';
import 'package:quizwiz/src/core/core.dart';
import 'package:quizwiz/src/features/cards/controller/controller.dart';
import 'package:quizwiz/src/features/cards/data/data.dart';

class CustomFocusedMenuHolder extends StatelessWidget {
  final Widget child;
  final FlashcardCollection collection;
  final Flashcard card;
  const CustomFocusedMenuHolder({
    Key? key,
    required this.collection,
    required this.card,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FocusedMenuHolder(
        menuBoxDecoration: const BoxDecoration(color: Colors.black),
        onPressed: () {},
        menuItems: [
          FocusedMenuItem(
              backgroundColor: Theme.of(context).cardColor,
              title: const Text(
                AppStrings.delete,
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                context.read<CardsBloc>().add(RemoveFlashcardsEvent(
                    collection: collection, flashcardUuid: card.uuid));
              }),
          FocusedMenuItem(
              backgroundColor: Theme.of(context).cardColor,
              title: const Text(AppStrings.edit),
              onPressed: () {
                Navigator.of(context).pushNamed(Routes.editFlashcard,
                    arguments: EditFlashcardParameters(
                        question: card.question,
                        answer: card.answer,
                        note: card.note,
                        collection: collection,
                        flashcard: card,
                        choices: card.choices,
                        correctChoiceIndex: card.correctChoiceIndex,
                        attachments: card.attachments));
              })
        ],
        child: child);
  }
}
