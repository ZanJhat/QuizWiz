import 'dart:async';

import 'package:quizwiz/src/core/core.dart';
import 'package:quizwiz/src/features/cards/controller/controller.dart';
import 'package:quizwiz/src/features/cards/data/data.dart';
import 'package:quizwiz/src/features/cards/presentation/presentation.dart';
import 'package:quizwiz/src/features/cards/presentation/widgets/attachments/card_attachments_view.dart';
import 'package:quizwiz/src/features/cards/presentation/widgets/practice_cards_widgets/choose_order_dialog.dart';
import 'package:quizwiz/src/features/cards/presentation/widgets/practice_cards_widgets/choose_quiz_dialog.dart';

class PracticeCardsScreen extends StatefulWidget {
  final FlashcardCollection collection;
  const PracticeCardsScreen({
    super.key,
    required this.collection,
  });

  @override
  State<PracticeCardsScreen> createState() => _PracticeCardsScreenState();
}

class _PracticeCardsScreenState extends State<PracticeCardsScreen> {
  bool _loaded = false;
  bool _reviewAllCards = false;
  bool _markingAllEasy = false;
  bool _leavingReview = false;
  bool _restoringPage = false;
  bool _reviewShuffle = false;
  late final PageController _pageController;
  int _currentPage = 0;
  String? _currentCardUuid;
  Future<void> _progressWrite = Future<void>.value();
  QuizDisplaySettings _displaySettings = const QuizDisplaySettings();
  List<Flashcard> _cards = const [];
  List<Flashcard> _reviewedToday = const [];
  final Set<String> _revealedCardUuids = {};
  final Set<String> _savingReviewUuids = {};
  final Set<String> _completedInAllMode = {};
  final Map<String, Flashcard> _reviewSourceByUuid = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadCards();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _leaveReview();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: _leaveReview,
            icon: const BackButtonIcon(),
          ),
          title: Text(_reviewAllCards
              ? 'Ôn lại toàn bộ bài học'
              : AppStrings.reviewFlashcard),
        ),
        body: !_loaded
            ? const LoadingWidget()
            : Column(
                children: [
                  _reviewedTodayPanel(),
                  if (widget.collection.cards.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed:
                              _markingAllEasy ? null : _markAllEasyAndPractice,
                          icon: _markingAllEasy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.done_all),
                          label: Text(_markingAllEasy
                              ? 'Đang cập nhật…'
                              : 'Đánh dấu tất cả Easy → Practice'),
                        ),
                      ),
                    ),
                  Expanded(
                    child: _cards.isEmpty
                        ? NoFlashcardsToReview(
                            collection: widget.collection,
                            onAgain: _restartWholeLesson,
                          )
                        : PageView.builder(
                            controller: _pageController,
                            itemCount: _cards.length,
                            onPageChanged: _onPageChanged,
                            itemBuilder: (context, index) {
                              return _reviewCard(_cards[index]);
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _loadCards() async {
    try {
      _displaySettings = await QuizDisplaySettingsStore.load();
    } catch (error) {
      if (mounted) {
        customSnackBar('Không tải được cỡ chữ đã lưu: $error', context);
      }
    }
    Set<String> reviewedUuids = {};
    Set<String> againUuids = {};
    var savedShuffle = false;
    var reviewProgressLoaded = true;
    List<String> savedCardUuids = const [];
    String? savedCurrentCardUuid;
    try {
      reviewedUuids =
          await DailyReviewStore.reviewedUuids(widget.collection.uuid);
      againUuids = await DailyReviewStore.againUuids(widget.collection.uuid);
      final savedOrder =
          await DailyReviewStore.reviewOrder(widget.collection.uuid);
      savedShuffle = savedOrder?.shuffle ?? false;
      savedCardUuids = savedOrder?.cardUuids ?? const [];
      savedCurrentCardUuid = savedOrder?.currentCardUuid;
      if (savedOrder != null) {
        _reviewAllCards = savedOrder.reviewAll;
      }
    } catch (error) {
      reviewProgressLoaded = false;
      if (mounted) {
        customSnackBar('Không tải được thứ tự ôn đã lưu: $error', context);
      }
    }
    if (savedCardUuids.isNotEmpty || !_reviewAllCards) {
      _reviewShuffle = savedShuffle;
    }
    final topLevelCards = widget.collection.cards;
    final reviewed = topLevelCards
        .where((card) => reviewedUuids.contains(card.uuid))
        .toList();
    final now = DateTime.now();
    final cards = topLevelCards
        .map((card) => card.reviewCard)
        .where((card) => _reviewAllCards
            ? !_completedInAllMode.contains(card.uuid) &&
                (!reviewedUuids.contains(card.uuid) ||
                    againUuids.contains(card.uuid))
            : (!reviewedUuids.contains(card.uuid) ||
                    againUuids.contains(card.uuid)) &&
                (againUuids.contains(card.uuid) ||
                    DateTime.fromMillisecondsSinceEpoch(card.dueTime)
                        .isBefore(now)))
        .toList();
    if (savedCardUuids.isNotEmpty) {
      final savedPositions = {
        for (var index = 0; index < savedCardUuids.length; index++)
          savedCardUuids[index]: index,
      };
      cards.sort((first, second) {
        final firstPosition = savedPositions[first.uuid];
        final secondPosition = savedPositions[second.uuid];
        if (firstPosition == null && secondPosition == null) {
          return topLevelCards
              .indexWhere((source) => source.uuid == first.uuid)
              .compareTo(topLevelCards
                  .indexWhere((source) => source.uuid == second.uuid));
        }
        if (firstPosition == null) return 1;
        if (secondPosition == null) return -1;
        return firstPosition.compareTo(secondPosition);
      });
    } else if (_reviewAllCards && _reviewShuffle) {
      cards.shuffle();
    }
    final savedPage = cards.indexWhere(
      (card) => card.uuid == savedCurrentCardUuid,
    );
    _reviewSourceByUuid
      ..clear()
      ..addEntries(topLevelCards.map((card) => MapEntry(card.uuid, card)));
    if (!mounted) return;
    _restoringPage = true;
    setState(() {
      _cards = cards;
      _currentPage = savedPage < 0 ? 0 : savedPage;
      _currentCardUuid = cards.isEmpty ? null : cards[_currentPage].uuid;
      _reviewedToday = reviewed;
      _loaded = true;
    });
    if (cards.isEmpty) _restoringPage = false;
    _jumpToPage(_currentPage);
    if (reviewProgressLoaded) await _saveReviewProgress();
  }

  Future<void> _leaveReview() async {
    if (_leavingReview) return;
    _leavingReview = true;
    await _saveReviewProgress();
    await _progressWrite;
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Widget _reviewedTodayPanel() {
    final total = widget.collection.cards.length;
    final progress = total == 0
        ? 0.0
        : (_reviewedToday.length / total).clamp(0.0, 1.0).toDouble();
    return ExpansionTile(
      title: Text('Đã ôn hôm nay: ${_reviewedToday.length} / $total'),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: LinearProgressIndicator(value: progress),
      ),
      children: [
        if (_reviewedToday.isEmpty)
          const ListTile(title: Text('Chưa ôn thẻ nào hôm nay'))
        else
          SizedBox(
            height:
                (_reviewedToday.length * 56.0).clamp(56.0, 224.0).toDouble(),
            child: ListView.builder(
              itemCount: _reviewedToday.length,
              itemBuilder: (context, index) => ListTile(
                dense: true,
                leading: const Icon(Icons.check_circle_outline),
                title: Text(
                  _reviewedToday[index].question,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _restartWholeLesson() async {
    final shuffle = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (_) => const ChooseOrderDialog(),
    );
    if (shuffle == null || !mounted) return;

    var progressReset = true;
    try {
      await DailyReviewStore.resetToday(widget.collection.uuid);
    } catch (_) {
      progressReset = false;
    }
    if (!mounted) return;
    setState(() {
      _reviewAllCards = true;
      _reviewShuffle = shuffle;
      _completedInAllMode.clear();
      _revealedCardUuids.clear();
      _loaded = false;
    });
    await _loadCards();
    if (!progressReset && mounted) {
      customSnackBar('Không thể xóa tiến độ ôn hôm nay', context);
    }
  }

  Widget _reviewCard(Flashcard card) {
    final revealed = _revealedCardUuids.contains(card.uuid);
    final saving = _savingReviewUuids.contains(card.uuid);
    final sourceCard = _reviewSourceByUuid[card.uuid] ?? card;
    final reviewCard = card.isGroup ? card : sourceCard.reviewCard;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: revealed || saving ? null : () => _revealCard(card.uuid),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    reviewCard.question,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontSize: revealed
                              ? _displaySettings.reviewQuestionAfterFlipSize
                              : _displaySettings.reviewQuestionBeforeFlipSize,
                        ),
                  ),
                  const SizedBox(height: 16),
                  CardAttachmentsView(attachments: sourceCard.attachments),
                  if (sourceCard.isGroup)
                    ...sourceCard.children
                        .where((child) => child.attachments.isNotEmpty)
                        .map((child) => CardAttachmentsView(
                              attachments: child.attachments,
                            )),
                  if (!revealed) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Chạm vào thẻ để xem đáp án',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ] else ...[
                    const Divider(height: 32),
                    if (sourceCard.isGroup)
                      ...sourceCard.children.asMap().entries.expand((entry) => [
                            Text(
                              entry.value.writingQuizAnswer,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    fontSize: _displaySettings
                                        .reviewAnswerAfterFlipSize,
                                  ),
                            ),
                            CardNoteView(
                              note: entry.value.note,
                              title: 'Note - câu hỏi ${entry.key + 1}',
                            ),
                          ])
                    else
                      Text(
                        reviewCard.writingQuizAnswer,
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontSize:
                                  _displaySettings.reviewAnswerAfterFlipSize,
                            ),
                      ),
                    CardNoteView(note: sourceCard.note),
                    const SizedBox(height: 24),
                    if (saving)
                      const Center(child: CircularProgressIndicator())
                    else
                      Row(
                        children: [
                          ReviewBar(
                            color: Colors.red,
                            text: 'Again',
                            onTap: () {
                              _chooseAgainOrder(card);
                            },
                          ),
                          ReviewBar(
                            color: Colors.redAccent,
                            text: 'Hard',
                            onTap: () => _rateCard(card, ReviewResult.hard),
                          ),
                          ReviewBar(
                            color: Colors.green,
                            text: 'Good',
                            onTap: () => _rateCard(card, ReviewResult.good),
                          ),
                          ReviewBar(
                            color: Colors.blue,
                            text: 'Easy',
                            onTap: () => _rateCard(card, ReviewResult.easy),
                          ),
                        ],
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _revealCard(String cardUuid) {
    setState(() => _revealedCardUuids.add(cardUuid));
  }

  Future<void> _chooseAgainOrder(Flashcard card) async {
    final shuffle = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (_) => const ChooseOrderDialog(),
    );
    if (shuffle == null || !mounted) return;

    try {
      final orderedCards = List<Flashcard>.of(_cards);
      if (shuffle) {
        orderedCards.shuffle();
      } else {
        final sourcePositions = {
          for (var index = 0; index < widget.collection.cards.length; index++)
            widget.collection.cards[index].uuid: index,
        };
        orderedCards.sort((first, second) => (sourcePositions[first.uuid] ?? 0)
            .compareTo(sourcePositions[second.uuid] ?? 0));
      }
      await _progressWrite;
      await DailyReviewStore.saveReviewOrder(
        collectionUuid: widget.collection.uuid,
        shuffle: shuffle,
        reviewAll: _reviewAllCards,
        cardUuids: orderedCards.map((item) => item.uuid),
        currentCardUuid: card.uuid,
      );
      if (!mounted) return;
      _reviewShuffle = shuffle;
      setState(() => _cards = orderedCards);
      _jumpToPage(orderedCards.indexWhere((item) => item.uuid == card.uuid));
    } catch (error) {
      if (mounted) {
        customSnackBar('Không lưu được thứ tự ôn: $error', context);
      }
    }
    if (!mounted) return;
    await _rateCard(card, ReviewResult.again);
  }

  Future<void> _rateCard(Flashcard card, ReviewResult result) async {
    if (!_savingReviewUuids.add(card.uuid)) return;
    final ratedCardIndex = _cards.indexWhere((item) => item.uuid == card.uuid);
    setState(() {});

    Object? reviewHistorySaveError;
    try {
      if (result == ReviewResult.again) {
        await DailyReviewStore.markAgain(
          collectionUuid: widget.collection.uuid,
          cardUuid: card.uuid,
        );
      } else {
        await DailyReviewStore.markReviewed(
          collectionUuid: widget.collection.uuid,
          cardUuid: card.uuid,
        );
      }
    } catch (error) {
      reviewHistorySaveError = error;
    }

    if (!mounted) return;
    if (reviewHistorySaveError != null) {
      customSnackBar(
        'Không lưu được lịch sử ôn tập: $reviewHistorySaveError',
        context,
      );
    }
    context.read<CardsBloc>().add(UpdateDueTimeEvent(
          card: _reviewSourceByUuid[card.uuid] ?? card,
          collectionUuid: widget.collection.uuid,
          reviewResult: result,
        ));
    setState(() {
      _savingReviewUuids.remove(card.uuid);
      _revealedCardUuids.remove(card.uuid);
      if (!_reviewedToday.any((reviewed) => reviewed.uuid == card.uuid)) {
        _reviewedToday = [..._reviewedToday, card];
      }
      if (result != ReviewResult.again) {
        if (_reviewAllCards) _completedInAllMode.add(card.uuid);
        _cards = _cards.where((current) => current.uuid != card.uuid).toList();
      }
      if (result == ReviewResult.again) {
        _currentPage = _cards.indexWhere((item) => item.uuid == card.uuid);
      } else if (_cards.isEmpty || ratedCardIndex <= 0) {
        _currentPage = 0;
      } else if (ratedCardIndex >= _cards.length) {
        _currentPage = _cards.length - 1;
      } else {
        _currentPage = ratedCardIndex;
      }
      _currentCardUuid = _cards.isEmpty ? null : _cards[_currentPage].uuid;
    });
    if (result != ReviewResult.again) {
      _jumpToPage(_currentPage);
    }
    await _saveReviewProgress();
  }

  void _jumpToPage(int page) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pageController.hasClients || _cards.isEmpty) return;
      final targetPage = page < 0
          ? 0
          : page >= _cards.length
              ? _cards.length - 1
              : page;
      _pageController.jumpToPage(targetPage);
      _currentPage = targetPage;
      _currentCardUuid = _cards[targetPage].uuid;
      if (_restoringPage) {
        _restoringPage = false;
        if (_loaded) unawaited(_saveReviewProgress());
      }
    });
  }

  Future<void> _saveReviewProgress() {
    final cardUuids = _cards.map((card) => card.uuid).toList();
    final currentCardUuid = _currentCardUuid;
    _progressWrite = _progressWrite.then((_) async {
      try {
        await DailyReviewStore.saveReviewOrder(
          collectionUuid: widget.collection.uuid,
          shuffle: _reviewShuffle,
          reviewAll: _reviewAllCards,
          cardUuids: cardUuids,
          currentCardUuid: currentCardUuid,
        );
      } catch (error) {
        if (mounted) {
          customSnackBar('Không lưu được tiến trình ôn: $error', context);
        }
      }
    });
    return _progressWrite;
  }

  void _onPageChanged(int index) {
    if (_restoringPage) return;
    _currentPage = index;
    _currentCardUuid =
        index >= 0 && index < _cards.length ? _cards[index].uuid : null;
    if (_loaded) unawaited(_saveReviewProgress());
  }

  Future<void> _markAllEasyAndPractice() async {
    if (_markingAllEasy || widget.collection.cards.isEmpty) return;
    setState(() => _markingAllEasy = true);

    final completed = Completer<void>();
    context.read<CardsBloc>().add(MarkAllCardsEasyEvent(
          collectionUuid: widget.collection.uuid,
          completer: completed,
        ));

    try {
      await completed.future;
      final cardUuids = widget.collection.cards.map((card) => card.uuid);
      try {
        await DailyReviewStore.markManyReviewed(
          collectionUuid: widget.collection.uuid,
          cardUuids: cardUuids,
        );
      } catch (error) {
        if (mounted) {
          customSnackBar('Không lưu được lịch sử ôn tập: $error', context);
        }
      }

      if (!mounted) return;
      setState(() {
        _markingAllEasy = false;
        _reviewAllCards = false;
        _completedInAllMode.clear();
        _revealedCardUuids.clear();
        _cards = const [];
      });
      await _loadCards();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => ChooseQuizDialog(collection: widget.collection),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _markingAllEasy = false);
      customSnackBar('Không thể cập nhật trạng thái Easy: $error', context);
    }
  }
}
