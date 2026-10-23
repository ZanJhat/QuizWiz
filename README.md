# QuizWiz

QuizWiz is a flashcard and study app built with Flutter. This repository is an
unofficial upgraded and modified version of the original
[QuizWiz project by Dev-Salem](https://github.com/Dev-Salem/quizwiz).

The changes in this fork are maintained by [ZanJhat](https://github.com/ZanJhat).
This project is not affiliated with, endorsed by, or maintained by the original
author.

## What changed in this fork

This fork builds on the original QuizWiz app with additional study, content
creation, and portability features, including:

- Generate flashcards with Gemini AI using a prompt and up to five attachments.
- Configure the Gemini API key and model in the app's Settings screen.
- Add notes, tags, answer choices, and attachments to cards.
- Organize related questions as grouped cards.
- Export and import collections as ZIP files, including bundles containing
  multiple collection ZIP files.
- Choose the order used for review and adjust quiz text size.
- Use sound feedback while practicing.
- Download card-format templates as a text file or ZIP archive.
- Configure light or dark appearance.

The original app's core workflows are also retained: create and manage
collections, review cards using the SM-2 spaced-repetition algorithm, and
practice with multiple-choice or written-answer quizzes.

## Requirements

- Flutter SDK with Dart 3.0.3 or later.
- A Gemini API key to use AI card generation.

## Getting started

```bash
git clone https://github.com/ZanJhat/QuizWiz.git
cd QuizWiz
flutter pub get
flutter run
```

To enable AI card generation, open **Settings → Gemini AI**, enter your API
key (and model, if needed), then save. Do not commit or share your API key.
The app stores this configuration outside the application bundle.

## Built with

- Flutter and Dart
- `flutter_bloc` for state management
- Isar for local data
- Gemini API for AI-assisted card generation

## Attribution and license

The original project is available at
[Dev-Salem/quizwiz](https://github.com/Dev-Salem/quizwiz) and is licensed under
the MIT License. This fork retains the original [LICENSE](LICENSE), including
the original copyright notice. The modifications in this repository were made
by ZanJhat; the original copyright remains with its respective holder.

This is an independent fork. Please refer to the original repository for the
upstream project's history and to this repository for changes made in this
version.
