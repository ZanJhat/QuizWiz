import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:quizwiz/src/core/core.dart';
import 'package:quizwiz/src/core/services/attachment_storage.dart';
import 'package:quizwiz/src/features/cards/data/data.dart';

class CardAttachmentsEditor extends StatelessWidget {
  final String collectionUuid;
  final String cardUuid;
  final List<CardAttachment> attachments;
  final ValueChanged<List<CardAttachment>> onChanged;

  const CardAttachmentsEditor({
    super.key,
    required this.collectionUuid,
    required this.cardUuid,
    required this.attachments,
    required this.onChanged,
  });

  Future<void> _pick(BuildContext context, String type) async {
    FileType fileType = FileType.any;
    List<String>? extensions;
    switch (type) {
      case 'image':
        fileType = FileType.image;
        break;
      case 'video':
        fileType = FileType.video;
        break;
      case 'audio':
        fileType = FileType.custom;
        extensions = const ['mp3', 'wav', 'm4a', 'aac', 'ogg'];
        break;
    }
    final result = await FilePicker.pickFiles(
      type: fileType,
      allowedExtensions: extensions,
    );
    final path = result?.files.single.path;
    if (path == null) return;
    final limit = await _askPlayLimit(context, type);
    if (limit == null) return;
    final saved = await AttachmentStorage.saveLocalFile(
      collectionUuid: collectionUuid,
      cardUuid: cardUuid,
      file: File(path),
      type: type,
      playLimit: limit,
    );
    onChanged([...attachments, saved]);
  }

  Future<void> _addEmbed(BuildContext context) async {
    final controller = TextEditingController();
    final url = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nhúng liên kết'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'https://... (ảnh, video, audio, YouTube...)',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(AppStrings.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Thêm')),
        ],
      ),
    );
    if (url == null || url.isEmpty) return;
    final type = MediaUrl.guessType(url);
    final limit = await _askPlayLimit(context, type);
    if (limit == null) return;
    onChanged([
      ...attachments,
      AttachmentStorage.remote(url: url, type: type, playLimit: limit),
    ]);
  }

  Future<int?> _askPlayLimit(BuildContext context, String type) async {
    if (type == 'image' || type == 'embed') return 0;
    var unlimited = true;
    var limit = 3;
    return showDialog<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Giới hạn số lần phát'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Không giới hạn'),
                  value: unlimited,
                  onChanged: (v) => setState(() => unlimited = v),
                ),
                if (!unlimited)
                  TextFormField(
                    initialValue: '$limit',
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Số lần phát'),
                    onChanged: (v) => limit = int.tryParse(v) ?? limit,
                  ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(AppStrings.cancel)),
              FilledButton(
                  onPressed: () =>
                      Navigator.pop(context, unlimited ? 0 : limit),
                  child: const Text('Xong')),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tệp đính kèm', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () => _pick(context, 'image'),
              icon: const Icon(Icons.image),
              label: const Text('Ảnh'),
            ),
            OutlinedButton.icon(
              onPressed: () => _pick(context, 'video'),
              icon: const Icon(Icons.videocam),
              label: const Text('Video'),
            ),
            OutlinedButton.icon(
              onPressed: () => _pick(context, 'audio'),
              icon: const Icon(Icons.audiotrack),
              label: const Text('Audio'),
            ),
            OutlinedButton.icon(
              onPressed: () => _addEmbed(context),
              icon: const Icon(Icons.link),
              label: const Text('Nhúng link'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...attachments.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(_iconFor(item.type)),
            title: Text(
              item.fileName.isEmpty ? item.source : item.fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(item.isRemote
                ? 'Link • ${_limitLabel(item)}'
                : 'Tệp tải lên • ${_limitLabel(item)}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                final next = [...attachments]..removeAt(index);
                onChanged(next);
              },
            ),
          );
        }),
      ],
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'video':
        return Icons.videocam;
      case 'audio':
        return Icons.audiotrack;
      case 'embed':
        return Icons.link;
      default:
        return Icons.image;
    }
  }

  String _limitLabel(CardAttachment item) {
    if (item.type == 'image' || item.isUnlimited) return 'không giới hạn';
    return 'tối đa ${item.playLimit} lần phát';
  }
}
