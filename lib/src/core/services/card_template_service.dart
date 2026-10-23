import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:quizwiz/src/core/services/export_directory_service.dart';
import 'package:quizwiz/src/features/cards/data/models/flashcard_collection.dart';

class CardTemplateService {
  static const _assetPath = 'assets/templates/card_template.txt';
  static const _schemaMarker = '{{GENERATED_SCHEMA_EXAMPLES}}';

  /// Render the checked-in guide with live serialization examples. The models'
  /// toJson() methods are the source of truth for every exported field name.
  static Future<String> renderLatestTemplate() async {
    final guide = await rootBundle.loadString(_assetPath);
    const sampleSource = 'sample-collection/sample-card/sample-image.png';
    final collection = FlashcardCollection(
      name: 'Ví dụ collection',
      description: 'Mô tả collection',
      uuid: 'collection-uuid',
      cards: [
        Flashcard(
          uuid: 'card-quiz-uuid',
          question: 'Thủ đô của Việt Nam là gì?',
          answer: 'Hà Nội',
          dueTime: 0,
          interval: 1,
          factor: 2.5,
          repetitions: 0,
          choices: ['Huế', 'Hà Nội', 'Đà Nẵng', 'Cần Thơ'],
          correctChoiceIndex: 1,
          note: 'Có thể ghi thêm cách phát âm hoặc thông tin cần nhớ.',
          tags: ['Geography', 'Unit1'],
        ),
        Flashcard(
          uuid: 'card-attachment-uuid',
          question: 'Mô tả nội dung trong hình.',
          answer: 'Ví dụ câu trả lời',
          dueTime: 0,
          interval: 1,
          factor: 2.5,
          repetitions: 0,
          choices: const [],
          correctChoiceIndex: 0,
          note: 'Ghi chú được mở sau khi người học lật thẻ.',
          attachments: [
            CardAttachment(
              type: 'image',
              source: sampleSource,
              fileName: 'sample-image.png',
              isRemote: false,
              playLimit: 0,
            ),
          ],
        ),
        Flashcard(
          uuid: 'card-letter-answer-uuid',
          question: 'Chọn đáp án đúng trong các ô A–D.',
          answer: '',
          dueTime: 0,
          interval: 1,
          factor: 2.5,
          repetitions: 0,
          choices: ['', '', '', ''],
          correctChoiceIndex: 2,
        ),
        Flashcard(
          uuid: 'listening-group-uuid',
          question: 'Bài nghe: đặt vé tàu',
          answer: '',
          dueTime: 0,
          interval: 1,
          factor: 2.5,
          repetitions: 0,
          attachments: [
            CardAttachment(
              type: 'audio',
              source: 'listening/train-booking.mp3',
              fileName: 'train-booking.mp3',
            ),
          ],
          tags: ['Listening', 'Part1'],
          note: 'Nghe kỹ giờ tàu khởi hành trong cuộc hội thoại.',
          children: [
            Flashcard(
              uuid: 'listening-question-1-uuid',
              question: 'When does the train leave?',
              answer: 'At 10:30',
              dueTime: 0,
              interval: 1,
              factor: 2.5,
              repetitions: 0,
              choices: ['At 9:30', 'At 10:30', 'At 11:30', ''],
              correctChoiceIndex: 1,
              note: 'Đáp án được nhắc trong phần đặt vé tàu.',
            ),
          ],
        ),
      ],
    );
    final payload = collection.toJson();
    final schema = const JsonEncoder.withIndent('  ').convert(payload);
    final version = payload['version']?.toString() ?? 'không xác định';
    return guide
        .replaceAll(_schemaMarker, schema)
        .replaceAll('{{COLLECTION_FORMAT_VERSION}}', version)
        .replaceAll(
          '{{ATTACHMENT_TYPES}}',
          CardAttachment.supportedTypes.join(', '),
        );
  }

  static Future<String> saveTextTemplate() async {
    final content = await renderLatestTemplate();
    final file = await ExportDirectoryService.saveBytes(
      'quizwiz_card_template.txt',
      utf8.encode(content),
    );
    return file.path;
  }

  static Future<String> saveTemplateZip() async {
    final content = await renderLatestTemplate();
    final archive = Archive();
    final bytes = utf8.encode(content);
    archive.addFile(ArchiveFile('card_template.txt', bytes.length, bytes));
    final encoded = ZipEncoder().encode(archive);
    if (encoded == null) throw Exception('Không thể tạo ZIP mẫu Card');
    final file = await ExportDirectoryService.saveBytes(
      'quizwiz_card_template.zip',
      encoded,
    );
    return file.path;
  }
}
