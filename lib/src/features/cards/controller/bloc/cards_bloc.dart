import 'package:equatable/equatable.dart';
import 'package:quizwiz/src/core/core.dart';
import 'package:quizwiz/src/features/cards/controller/bloc/cards_events.dart';
import 'package:quizwiz/src/features/cards/data/data.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
part 'cards_state.dart';

class CardsBloc extends Bloc<CardsEvents, CardsState> {
  final BaseCardsRepository _baseCardsRepository;
  final Isar _isar;

  CardsBloc(this._isar, this._baseCardsRepository) : super(const CardsState()) {
    on<GetCollectionsEvent>(_getCollections);
    on<RemoveCollectionEvent>(_removeCollection);
    on<CreateCollectionsEvent>(_createCollections);
    on<AddFlashcardsEvent>(_addFlashcards);
    on<RemoveFlashcardsEvent>(_removeFlashcard);
    on<UpdateDueTimeEvent>(_updateDueTime);
    on<MarkAllCardsEasyEvent>(_markAllCardsEasy);
    on<EditFlashcardsEvent>(_editFlashcards);
    on<ReorderFlashcardsEvent>(_reorderFlashcards);
    on<GetDueReviewsEvent>(_getDueReviewsEvent);
    on<EditCollectionEvent>(_editCollection);
    on<GetMultipleQuizOptionsEvent>(_getMultipleQuizOptionsEvent);
    on<GenerateFlashcardsEvent>(_generateFlashcards);
    on<SaveAllGenerateFlashcardsEvent>(_saveAllGenerateFlashcards);
    on<CombineCollectionsEvent>(_combineCollections);
    on<ImportCollectionEvent>(_importCollection);
    on<ImportCollectionsEvent>(_importCollections);
    _isar.flashcardCollections.watchLazy().listen((event) {
      add(const GetCollectionsEvent());
    });
  }
  @override
  Future<void> close() async {
    await _isar.close();
    return super.close();
  }

  _getCollections(GetCollectionsEvent event, Emitter<CardsState> emit) async {
    emit(state.copyWith(collectionsRequestState: RequestState.loading));
    final result = await _baseCardsRepository.getCollections();
    result.fold(
        (l) => emit(state.copyWith(
            collectionsErrorMessage: l.message,
            collectionsRequestState: RequestState.error)),
        (r) => emit(state.copyWith(
            collectionsRequestState: RequestState.success, collections: r)));
  }

  _removeCollection(
      RemoveCollectionEvent event, Emitter<CardsState> emit) async {
    emit(state.copyWith(collectionsRequestState: RequestState.loading));
    final result = await _baseCardsRepository.removeCollection(event.uuid);
    result.fold(
        (l) => emit(state.copyWith(
            collectionsErrorMessage: l.message,
            collectionsRequestState: RequestState.error)),
        (r) => emit(state.copyWith(
              collectionsRequestState: RequestState.success,
            )));
  }

  _createCollections(
      CreateCollectionsEvent event, Emitter<CardsState> emit) async {
    emit(state.copyWith(collectionsRequestState: RequestState.loading));
    final result = await _baseCardsRepository.createCollection(event.name,
        description: event.description);
    result.fold(
        (l) => emit(state.copyWith(
            collectionsErrorMessage: l.message,
            collectionsRequestState: RequestState.error)),
        (r) => emit(state.copyWith(
              collectionsRequestState: RequestState.success,
            )));
    add(const GetCollectionsEvent());
  }

  Future<void> _addFlashcards(
      AddFlashcardsEvent event, Emitter<CardsState> emit) async {
    emit(state.copyWith(collectionsRequestState: RequestState.loading));
    try {
      final result = await _baseCardsRepository.addFlashcard(
        event.question,
        event.answer,
        event.collectionUuid,
        note: event.note,
        choices: event.choices,
        correctChoiceIndex: event.correctChoiceIndex,
        attachments: event.attachments,
        children: event.children,
        tags: event.tags,
        uuid: event.uuid,
      );
      await result.fold<Future<void>>((failure) async {
        emit(state.copyWith(
          collectionsErrorMessage: failure.message,
          collectionsRequestState: RequestState.error,
        ));
        if (!(event.completer?.isCompleted ?? true)) {
          event.completer!.complete(failure.message);
        }
      }, (_) async {
        await _refreshCollections(emit);
        if (!(event.completer?.isCompleted ?? true)) {
          event.completer!.complete(null);
        }
      });
    } catch (error) {
      final message = error.toString();
      emit(state.copyWith(
        collectionsErrorMessage: message,
        collectionsRequestState: RequestState.error,
      ));
      if (!(event.completer?.isCompleted ?? true)) {
        event.completer!.complete(message);
      }
    }
  }

  _updateDueTime(UpdateDueTimeEvent event, Emitter<CardsState> emit) async {
    emit(state.copyWith(collectionsRequestState: RequestState.loading));
    final result = await _baseCardsRepository.updateDueTime(
        event.card, event.collectionUuid, event.reviewResult);
    result.fold(
        (l) => emit(state.copyWith(
            collectionsErrorMessage: l.message,
            collectionsRequestState: RequestState.error)),
        (r) => emit(state.copyWith(
              collectionsRequestState: RequestState.success,
            )));
  }

  Future<void> _markAllCardsEasy(
      MarkAllCardsEasyEvent event, Emitter<CardsState> emit) async {
    emit(state.copyWith(collectionsRequestState: RequestState.loading));
    try {
      final result =
          await _baseCardsRepository.markAllCardsEasy(event.collectionUuid);
      result.fold((failure) {
        emit(state.copyWith(
          collectionsErrorMessage: failure.message,
          collectionsRequestState: RequestState.error,
        ));
        if (!event.completer.isCompleted) {
          event.completer.completeError(Exception(failure.message));
        }
      }, (_) {
        emit(state.copyWith(collectionsRequestState: RequestState.success));
        if (!event.completer.isCompleted) event.completer.complete();
      });
    } catch (error, stackTrace) {
      emit(state.copyWith(
        collectionsErrorMessage: error.toString(),
        collectionsRequestState: RequestState.error,
      ));
      if (!event.completer.isCompleted) {
        event.completer.completeError(error, stackTrace);
      }
    }
  }

  _removeFlashcard(
      RemoveFlashcardsEvent event, Emitter<CardsState> emit) async {
    emit(state.copyWith(collectionsRequestState: RequestState.loading));
    final result = await _baseCardsRepository.removeFlashcard(
        event.collection, event.flashcardUuid);
    result.fold(
        (l) => emit(state.copyWith(
            collectionsErrorMessage: l.message,
            collectionsRequestState: RequestState.error)), (r) {
      emit(state.copyWith(
        collectionsRequestState: RequestState.success,
      ));
    });
  }

  Future<void> _editFlashcards(
      EditFlashcardsEvent event, Emitter<CardsState> emit) async {
    emit(state.copyWith(collectionsRequestState: RequestState.loading));
    try {
      final result = await _baseCardsRepository.editFlashcard(event.parameters);
      await result.fold<Future<void>>((failure) async {
        emit(state.copyWith(
          collectionsErrorMessage: failure.message,
          collectionsRequestState: RequestState.error,
        ));
        if (!(event.completer?.isCompleted ?? true)) {
          event.completer!.complete(failure.message);
        }
      }, (_) async {
        await _refreshCollections(emit);
        if (!(event.completer?.isCompleted ?? true)) {
          event.completer!.complete(null);
        }
      });
    } catch (error) {
      final message = error.toString();
      emit(state.copyWith(
        collectionsErrorMessage: message,
        collectionsRequestState: RequestState.error,
      ));
      if (!(event.completer?.isCompleted ?? true)) {
        event.completer!.complete(message);
      }
    }
  }

  Future<void> _refreshCollections(Emitter<CardsState> emit) async {
    final result = await _baseCardsRepository.getCollections();
    result.fold(
      (failure) => emit(state.copyWith(
        collectionsErrorMessage: failure.message,
        collectionsRequestState: RequestState.success,
      )),
      (collections) => emit(state.copyWith(
        collections: collections,
        collectionsErrorMessage: '',
        collectionsRequestState: RequestState.success,
      )),
    );
  }

  Future<void> _reorderFlashcards(
      ReorderFlashcardsEvent event, Emitter<CardsState> emit) async {
    emit(state.copyWith(collectionsRequestState: RequestState.loading));
    final result = await _baseCardsRepository.reorderFlashcards(
        event.collectionUuid, event.flashcardUuids);
    await result.fold<Future<void>>(
      (failure) async {
        emit(state.copyWith(
          collectionsErrorMessage: failure.message,
          collectionsRequestState: RequestState.error,
        ));
      },
      (_) => _refreshCollections(emit),
    );
  }

  _getDueReviewsEvent(
      GetDueReviewsEvent event, Emitter<CardsState> emit) async {
    emit(state.copyWith(
      flashcardRequestState: RequestState.loading,
      flashcardErrorMessage: '',
    ));
    final result = await _baseCardsRepository.getDueReviewCards(
      event.collection,
    );
    result.fold(
        (l) => emit(state.copyWith(
            flashcardErrorMessage: l.message,
            flashcardRequestState: RequestState.error)),
        (r) => emit(state.copyWith(
              flashcards: r,
              flashcardRequestState: RequestState.success,
            )));
  }

  _editCollection(EditCollectionEvent event, Emitter<CardsState> emit) async {
    emit(state.copyWith(collectionsRequestState: RequestState.loading));
    final result = await _baseCardsRepository.editCollection((
      collection: event.collection,
      name: event.name,
      description: event.description
    ));
    result.fold((l) {
      emit(state.copyWith(
          collectionsErrorMessage: l.message,
          collectionsRequestState: RequestState.error));
    }, (r) {
      emit(state.copyWith(
        collectionsRequestState: RequestState.success,
      ));
    });
  }

  _getMultipleQuizOptionsEvent(
      GetMultipleQuizOptionsEvent event, Emitter<CardsState> emit) async {
    emit(state.copyWith(quizRequestState: RequestState.loading));
    try {
      final result =
          await _baseCardsRepository.getMultipleChoiceOptions(event.collection);
      result.fold(
          (l) => emit(state.copyWith(
              quizRequestState: RequestState.error,
              quizErrorMessage: l.message)), (r) {
        final quizzes = List<MultipleChoiceQuiz>.of(r);
        if (event.shuffle) quizzes.shuffle();
        emit(state.copyWith(
          quizRequestState: RequestState.success,
          collectionsRequestState: RequestState.success,
          quizErrorMessage: '',
          multipleChoices: quizzes,
        ));
      });
    } catch (error) {
      emit(state.copyWith(
        quizRequestState: RequestState.error,
        quizErrorMessage: error.toString(),
      ));
    }
  }

  _generateFlashcards(
      GenerateFlashcardsEvent event, Emitter<CardsState> emit) async {
    emit(state.copyWith(flashcardRequestState: RequestState.loading));
    final result = await _baseCardsRepository.generateFlashcards(
      file: event.file,
      files: event.files,
      sourceUrl: event.sourceUrl,
      prompt: event.prompt,
      notes: event.notes,
    );
    result.fold(
        (l) => emit(state.copyWith(
            flashcardRequestState: RequestState.error,
            flashcardErrorMessage: l.message)),
        (r) => emit(state.copyWith(
            flashcardRequestState: RequestState.success,
            collectionsRequestState: RequestState.success,
            flashcards: r)));
  }

  _saveAllGenerateFlashcards(
      SaveAllGenerateFlashcardsEvent event, Emitter<CardsState> emit) async {
    emit(state.copyWith(collectionsRequestState: RequestState.loading));
    final result = await _baseCardsRepository.saveAllGeneratedFlashcard(
        event.collectionUuid, event.flashcards);
    result.fold(
        (l) => emit(state.copyWith(
            collectionsErrorMessage: l.message,
            collectionsRequestState: RequestState.error)),
        (r) => emit(state.copyWith(
              collectionsRequestState: RequestState.success,
            )));
  }

  _combineCollections(
      CombineCollectionsEvent event, Emitter<CardsState> emit) async {
    emit(state.copyWith(collectionsRequestState: RequestState.loading));
    final result = await _baseCardsRepository.combineCollections(
        event.mainCollection, event.secondaryCollection);
    result.fold(
        (l) => emit(state.copyWith(
            collectionsErrorMessage: l.message,
            collectionsRequestState: RequestState.error)),
        (r) => emit(state.copyWith(
              collectionsRequestState: RequestState.success,
            )));
  }

  _importCollection(
      ImportCollectionEvent event, Emitter<CardsState> emit) async {
    emit(state.copyWith(collectionsRequestState: RequestState.loading));
    final result =
        await _baseCardsRepository.importCollection(event.collection);
    result.fold(
        (l) => emit(state.copyWith(
            collectionsErrorMessage: l.message,
            collectionsRequestState: RequestState.error)),
        (r) => emit(state.copyWith(
              collectionsRequestState: RequestState.success,
            )));
    add(const GetCollectionsEvent());
  }

  Future<void> _importCollections(
      ImportCollectionsEvent event, Emitter<CardsState> emit) async {
    emit(state.copyWith(collectionsRequestState: RequestState.loading));
    final result =
        await _baseCardsRepository.importCollections(event.collections);
    result.fold((failure) {
      emit(state.copyWith(
        collectionsErrorMessage: failure.message,
        collectionsRequestState: RequestState.error,
      ));
      if (!event.completer.isCompleted) {
        event.completer.completeError(Exception(failure.message));
      }
    }, (_) {
      emit(state.copyWith(collectionsRequestState: RequestState.success));
      if (!event.completer.isCompleted) event.completer.complete();
    });
    add(const GetCollectionsEvent());
  }
}
