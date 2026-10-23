// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:quizwiz/src/core/core.dart';
import 'package:quizwiz/src/features/cards/controller/controller.dart';
import 'package:quizwiz/src/features/cards/data/models/flashcard_collection.dart';
import 'package:quizwiz/src/features/cards/presentation/presentation.dart';

enum _CollectionCardFilter { listOrder, alphabetical, tags }

class FlashcardsListScreen extends StatefulWidget {
  final String collectionUuid;
  const FlashcardsListScreen({super.key, required this.collectionUuid});

  @override
  State<FlashcardsListScreen> createState() => _FlashcardsListScreenState();
}

class _FlashcardsListScreenState extends State<FlashcardsListScreen> {
  _CollectionCardFilter _filter = _CollectionCardFilter.alphabetical;
  Set<String> _selectedTags = {};
  bool _hideSelectedTags = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CardsBloc, CardsState>(
      buildWhen: (previous, current) =>
          current.collections != previous.collections ||
          current.collectionsRequestState != previous.collectionsRequestState,
      builder: (context, state) {
        switch (state.collectionsRequestState) {
          case RequestState.loading:
            return const LoadingWidget();
          case RequestState.error:
            return CustomErrorWidget(
              errorMessage: state.collectionsErrorMessage,
            );
          case RequestState.success:
            final matchingCollections = state.collections
                .where((element) => element.uuid == widget.collectionUuid);
            if (matchingCollections.isEmpty) {
              return const Scaffold(
                body: Center(child: Text('Không tìm thấy collection này.')),
              );
            }
            final collection = matchingCollections.first;
            final availableTags = _availableTags(collection);
            final cards = _visibleCards(collection);
            return WillPopScope(
              onWillPop: () async {
                Navigator.of(context).popUntil((route) => route.isFirst);
                return false;
              },
              child: Scaffold(
                appBar: AppBar(
                  title: Text(collection.name),
                  actions: [
                    IconButton(
                      tooltip: 'Sắp xếp thứ tự danh sách',
                      onPressed: collection.cards.length < 2
                          ? null
                          : () => _showReorderDialog(collection),
                      icon: const Icon(Icons.reorder),
                    ),
                  ],
                ),
                floatingActionButton: FloatingActionButton(
                  onPressed: () => Navigator.of(context).pushNamed(
                    Routes.createFlashcards,
                    arguments: widget.collectionUuid,
                  ),
                  child: const Icon(Icons.add),
                ),
                body: Column(
                  children: [
                    _filterToolbar(availableTags),
                    Expanded(
                      child: cards.isEmpty
                          ? Center(
                              child: Text(
                                collection.cards.isEmpty
                                    ? AppStrings.noCards
                                    : 'Không có card khớp bộ lọc tag.',
                                textAlign: TextAlign.center,
                              ),
                            )
                          : MasonryGridView.builder(
                              padding: const EdgeInsets.all(15),
                              gridDelegate:
                                  const SliverSimpleGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                              ),
                              itemCount: cards.length,
                              itemBuilder: (context, index) {
                                final card = cards[index];
                                return CustomFocusedMenuHolder(
                                  collection: collection,
                                  card: card,
                                  child: FlashcardWidget(card: card),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
        }
      },
    );
  }

  Widget _filterToolbar(List<String> availableTags) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      child: Row(
        children: [
          const Icon(Icons.filter_list),
          const SizedBox(width: 8),
          const Text('Lọc:'),
          const SizedBox(width: 8),
          DropdownButton<_CollectionCardFilter>(
            value: _filter,
            items: const [
              DropdownMenuItem(
                value: _CollectionCardFilter.listOrder,
                child: Text('Danh sách'),
              ),
              DropdownMenuItem(
                value: _CollectionCardFilter.alphabetical,
                child: Text('A–Z'),
              ),
              DropdownMenuItem(
                value: _CollectionCardFilter.tags,
                child: Text('Tag'),
              ),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _filter = value);
            },
          ),
          if (_filter == _CollectionCardFilter.tags) ...[
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showTagFilter(availableTags),
                icon: const Icon(Icons.sell_outlined, size: 18),
                label: Text(
                  _selectedTags.isEmpty
                      ? 'Chọn tag'
                      : '${_selectedTags.length} tag đã chọn',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            if (_selectedTags.isNotEmpty)
              IconButton(
                tooltip: 'Xóa bộ lọc tag',
                onPressed: () => setState(() => _selectedTags.clear()),
                icon: const Icon(Icons.clear),
              ),
          ],
        ],
      ),
    );
  }

  List<Flashcard> _visibleCards(FlashcardCollection collection) {
    final cards = collection.cards.where((card) {
      if (_filter != _CollectionCardFilter.tags || _selectedTags.isEmpty) {
        return true;
      }
      final selected = _selectedTags.map((tag) => tag.toLowerCase()).toSet();
      final matches =
          card.tags.any((tag) => selected.contains(tag.toLowerCase()));
      return _hideSelectedTags ? !matches : matches;
    }).toList();

    if (_filter != _CollectionCardFilter.listOrder) {
      cards.sort((a, b) => a.question
          .trim()
          .toLowerCase()
          .compareTo(b.question.trim().toLowerCase()));
    }
    return cards;
  }

  Future<void> _showReorderDialog(FlashcardCollection collection) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        var orderedCards = List<Flashcard>.of(collection.cards);
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Sắp xếp thứ tự danh sách'),
            content: SizedBox(
              width: double.maxFinite,
              height: MediaQuery.sizeOf(context).height * 0.55,
              child: ReorderableListView.builder(
                itemCount: orderedCards.length,
                onReorderItem: (oldIndex, newIndex) {
                  setDialogState(() {
                    final card = orderedCards.removeAt(oldIndex);
                    orderedCards.insert(newIndex, card);
                  });
                },
                itemBuilder: (context, index) {
                  final card = orderedCards[index];
                  return ListTile(
                    key: ValueKey(card.uuid),
                    title: Text(
                      card.question.isEmpty
                          ? '(Không có câu hỏi)'
                          : card.question,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: card.answer.isEmpty
                        ? null
                        : Text(
                            card.answer,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                    leading: const Icon(Icons.drag_handle),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: () {
                  dialogContext.read<CardsBloc>().add(ReorderFlashcardsEvent(
                        collectionUuid: collection.uuid,
                        flashcardUuids:
                            orderedCards.map((card) => card.uuid).toList(),
                      ));
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('Lưu thứ tự'),
              ),
            ],
          ),
        );
      },
    );
  }

  List<String> _availableTags(FlashcardCollection collection) {
    final unique = <String, String>{};
    for (final card in collection.cards) {
      for (final tag in card.tags) {
        final normalized = tag.trim();
        if (normalized.isNotEmpty) {
          unique.putIfAbsent(normalized.toLowerCase(), () => normalized);
        }
      }
    }
    final tags = unique.values.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return tags;
  }

  Future<void> _showTagFilter(List<String> availableTags) async {
    final availableKeys = availableTags.map((tag) => tag.toLowerCase()).toSet();
    final selectedTags = _selectedTags
        .where((tag) => availableKeys.contains(tag.toLowerCase()))
        .toSet();
    var hideSelectedTags = _hideSelectedTags;

    final result = await showModalBottomSheet<
        ({Set<String> selectedTags, bool hideSelectedTags})>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.72,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Lọc theo tag',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    'Card được giữ lại nếu khớp ít nhất một tag đã chọn.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(hideSelectedTags
                        ? 'Ẩn card có tag đã chọn'
                        : 'Chỉ hiện card có tag đã chọn'),
                    value: hideSelectedTags,
                    onChanged: (value) =>
                        setSheetState(() => hideSelectedTags = value),
                  ),
                  const Divider(),
                  Expanded(
                    child: availableTags.isEmpty
                        ? const Center(
                            child: Text('Collection này chưa có tag nào.'),
                          )
                        : ListView(
                            children: availableTags
                                .map((tag) => CheckboxListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(tag),
                                      value: selectedTags.any((selected) =>
                                          selected.toLowerCase() ==
                                          tag.toLowerCase()),
                                      onChanged: (checked) {
                                        setSheetState(() {
                                          selectedTags.removeWhere((selected) =>
                                              selected.toLowerCase() ==
                                              tag.toLowerCase());
                                          if (checked == true) {
                                            selectedTags.add(tag);
                                          }
                                        });
                                      },
                                    ))
                                .toList(),
                          ),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () =>
                            setSheetState(() => selectedTags.clear()),
                        child: const Text('Bỏ chọn'),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        child: const Text('Hủy'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () => Navigator.pop(
                          sheetContext,
                          (
                            selectedTags: selectedTags,
                            hideSelectedTags: hideSelectedTags,
                          ),
                        ),
                        child: const Text('Áp dụng'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (!mounted || result == null) return;
    setState(() {
      _selectedTags = result.selectedTags;
      _hideSelectedTags = result.hideSelectedTags;
    });
  }
}
