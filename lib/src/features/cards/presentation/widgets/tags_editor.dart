import 'package:flutter/material.dart';

class TagsEditor extends StatefulWidget {
  final List<String> tags;
  final ValueChanged<List<String>> onChanged;

  const TagsEditor({
    super.key,
    required this.tags,
    required this.onChanged,
  });

  @override
  State<TagsEditor> createState() => _TagsEditorState();
}

class _TagsEditorState extends State<TagsEditor> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.tags.join(', '));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          textInputAction: TextInputAction.done,
          onChanged: (value) => widget.onChanged(_parseTags(value)),
          decoration: const InputDecoration(
            labelText: 'Tag',
            hintText: 'Unit1, Listening, Part1',
            helperText: 'Nhập nhiều tag, phân cách bằng dấu phẩy',
            prefixIcon: Icon(Icons.sell_outlined),
          ),
        ),
        if (widget.tags.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: widget.tags
                  .map(
                    (tag) => InputChip(
                      label: Text(tag),
                      onDeleted: () => _removeTag(tag),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }

  List<String> _parseTags(String value) {
    final tags = <String>[];
    final seen = <String>{};
    for (final part in value.split(',')) {
      final tag = part.trim();
      if (tag.isEmpty || !seen.add(tag.toLowerCase())) continue;
      tags.add(tag);
    }
    return tags;
  }

  void _removeTag(String tag) {
    final remaining = widget.tags
        .where((item) => item.toLowerCase() != tag.toLowerCase())
        .toList();
    _controller
      ..text = remaining.join(', ')
      ..selection = TextSelection.collapsed(offset: _controller.text.length);
    widget.onChanged(remaining);
  }
}
