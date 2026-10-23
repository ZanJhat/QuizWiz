// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:dartz/dartz.dart';
import 'package:quizwiz/src/core/core.dart';
import 'package:quizwiz/src/features/cards/data/data.dart';

import 'package:dio/dio.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

class CardsRepository implements BaseCardsRepository {
  final FlashcardLocalDataSource _flashcardDataSource;
  final CollectionLocalDataSource _collectionDataSource;
  const CardsRepository(
    this._flashcardDataSource,
    this._collectionDataSource,
  );

  @override
  EitherUnit addFlashcard(
    String question,
    String answer,
    String collectionUuid, {
    String note = '',
    List<String> choices = const [],
    int correctChoiceIndex = 0,
    List<CardAttachment> attachments = const [],
    List<Flashcard> children = const [],
    List<String> tags = const [],
    String? uuid,
  }) async {
    try {
      final result = await _flashcardDataSource.addFlashcard(
        question,
        answer,
        collectionUuid,
        note: note,
        choices: choices,
        correctChoiceIndex: correctChoiceIndex,
        attachments: attachments,
        children: children,
        tags: tags,
        uuid: uuid,
      );
      return Right(result);
    } on Exception catch (e) {
      return Left(LocalStorageFailure(message: e.toString()));
    }
  }

  @override
  EitherUnit createCollection(String name, {description = ''}) async {
    try {
      final result = await _collectionDataSource.createCollection(name,
          description: description);
      return Right(result);
    } on Exception catch (e) {
      return Left(LocalStorageFailure(message: e.toString()));
    }
  }

  @override
  EitherCollections getCollections() async {
    try {
      final result = await _collectionDataSource.getCollections();
      return Right(result);
    } on Exception catch (e) {
      return Left(LocalStorageFailure(message: e.toString()));
    }
  }

  @override
  EitherFlashcards getDueReviewCards(
    FlashcardCollection collection,
  ) async {
    try {
      final result = await _flashcardDataSource.getDueReviewCards(collection);
      return Right(result);
    } on Exception catch (e) {
      return Left(LocalStorageFailure(message: e.toString()));
    }
  }

  @override
  EitherUnit removeCollection(String uuid) async {
    try {
      final result = await _collectionDataSource.removeCollection(uuid);
      return Right(result);
    } on Exception catch (e) {
      return Left(LocalStorageFailure(message: e.toString()));
    }
  }

  @override
  EitherUnit updateDueTime(
      Flashcard card, String collectionUuid, ReviewResult reviewResult) async {
    try {
      final result = await _flashcardDataSource.updateDueTime(
          card, collectionUuid, reviewResult);
      return Right(result);
    } on Exception catch (e) {
      return Left(LocalStorageFailure(message: e.toString()));
    }
  }

  @override
  EitherUnit markAllCardsEasy(String collectionUuid) async {
    try {
      final result =
          await _flashcardDataSource.markAllCardsEasy(collectionUuid);
      return Right(result);
    } on Exception catch (e) {
      return Left(LocalStorageFailure(message: e.toString()));
    }
  }

  @override
  EitherUnit removeFlashcard(
      FlashcardCollection collection, String flashcardUuid) async {
    try {
      final result =
          await _flashcardDataSource.removeFlashcard(collection, flashcardUuid);
      return Right(result);
    } on Exception catch (e) {
      return Left(LocalStorageFailure(message: e.toString()));
    }
  }

  @override
  EitherUnit editFlashcard(EditFlashcardParameters parameters) async {
    try {
      final result = await _flashcardDataSource.editFlashcard(parameters);
      return Right(result);
    } on Exception catch (e) {
      return Left(LocalStorageFailure(message: e.toString()));
    }
  }

  @override
  EitherUnit reorderFlashcards(
      String collectionUuid, List<String> flashcardUuids) async {
    try {
      final result = await _flashcardDataSource.reorderFlashcards(
          collectionUuid, flashcardUuids);
      return Right(result);
    } on Exception catch (e) {
      return Left(LocalStorageFailure(message: e.toString()));
    }
  }

  @override
  EitherUnit editCollection(
      ({
        FlashcardCollection collection,
        String description,
        String name
      }) collection) async {
    try {
      final result = await _collectionDataSource.editCollection(collection);
      return Right(result);
    } on Exception catch (e) {
      return Left(LocalStorageFailure(message: e.toString()));
    }
  }

  @override
  EitherMultiple getMultipleChoiceOptions(
      FlashcardCollection collection) async {
    try {
      final result =
          await _flashcardDataSource.getMultipleChoiceOptions(collection);
      return Right(result);
    } on Exception catch (e) {
      return Left(LocalStorageFailure(message: e.toString()));
    }
  }

  @override
  EitherFlashcards generateFlashcards({
    File? file,
    List<File> files = const [],
    String? sourceUrl,
    String prompt = '',
    String notes = '',
  }) async {
    try {
      final settings = await GeminiSettingsStore.load();
      final apiKey = settings.apiKey.trim();
      if (apiKey.isEmpty) {
        return const Left(
            NetworkFailure(message: 'Hãy nhập Gemini API key trong Cài đặt.'));
      }
      final modelName = settings.model.trim().isEmpty
          ? GeminiSettingsStore.defaultModel
          : settings.model.trim();

      final trimmedPrompt =
          prompt.trim().isNotEmpty ? prompt.trim() : notes.trim();
      final userPromptBlock = trimmedPrompt.isEmpty
          ? ''
          : '''
Yêu cầu của người dùng (bắt buộc tuân thủ):
"""
$trimmedPrompt
"""
''';

      final currentTemplate = await CardTemplateService.renderLatestTemplate();
      final generationPrompt = '''
Bạn là trợ lý tạo thẻ học tập Flashcard từ tài liệu đính kèm.
Hãy đọc tài liệu và tạo danh sách các thẻ câu hỏi - câu trả lời.
$userPromptBlock
Hãy tuân thủ chính xác mẫu định dạng mới nhất bên dưới. Trả về một JSON object Collection, không Markdown/code fence. Giữ nguyên cấu trúc, tên trường và kiểu dữ liệu trong mẫu. answer là đáp án Writing riêng, có thể để trống; choices giữ nguyên thứ tự các ô A-H kể cả ô trống; correctChoiceIndex xác định đáp án Multiple Choice theo vị trí và đếm từ 0. Không xóa ô trống, không sắp xếp choices và không ghi đè answer bằng lựa chọn. Khi answer trống, Writing quiz nhận nội dung của ô đúng nếu ô đó có chữ; nếu ô đúng trống thì nhận chữ cái tương ứng A-H. Nếu không cần trắc nghiệm, dùng choices: []. Không tạo hay giả lập tệp đính kèm; nếu tài liệu không cung cấp media thật thì dùng attachments: [].

MẪU ĐỊNH DẠNG HIỆN HÀNH:
$currentTemplate
''';

      String? jsonText;
      if (sourceUrl != null) {
        final response = await Dio().post<Map<String, dynamic>>(
          'https://generativelanguage.googleapis.com/v1beta/models/${Uri.encodeComponent(modelName)}:generateContent',
          options: Options(headers: {
            'x-goog-api-key': apiKey,
            'Content-Type': 'application/json',
          }),
          data: {
            'contents': [
              {
                'parts': [
                  {'text': '$generationPrompt\n\nTài liệu cần đọc: $sourceUrl'}
                ]
              }
            ],
            'tools': [
              {'url_context': {}}
            ],
            'generationConfig': {'responseMimeType': 'application/json'}
          },
        );
        final candidates = response.data?['candidates'] as List?;
        final candidate = candidates == null || candidates.isEmpty
            ? null
            : candidates.first as Map?;
        final content = candidate?['content'] as Map?;
        final parts = content?['parts'] as List?;
        jsonText = parts
            ?.whereType<Map>()
            .map((part) => part['text']?.toString() ?? '')
            .join('\n');
      } else if (file != null || files.isNotEmpty || prompt.trim().isNotEmpty) {
        final sourceFiles = file == null ? files : [file, ...files];
        if (sourceFiles.length > 5) {
          return const Left(NetworkFailure(
            message: 'Chỉ được đính kèm tối đa 5 tệp.',
          ));
        }
        final model = GenerativeModel(model: modelName, apiKey: apiKey);
        final parts = <Part>[
          TextPart(generationPrompt),
          for (final sourceFile in sourceFiles)
            await _filePart(sourceFile, apiKey),
        ];
        final response = await model.generateContent([Content.multi(parts)]);
        jsonText = response.text;
      }
      if (jsonText == null || jsonText.trim().isEmpty) {
        return const Left(
            NetworkFailure(message: 'Gemini không trả về kết quả'));
      }

      final decoded = _decodeJsonList(jsonText);
      if (decoded == null) {
        return const Left(
            NetworkFailure(message: 'Gemini trả về JSON không hợp lệ'));
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      final List<Flashcard> flashcards = decoded.map<Flashcard>((item) {
        final map = Map<String, dynamic>.from(item as Map);
        return Flashcard.fromJson({
          ...map,
          'uuid': const Uuid().v4(),
          'dueTime': now,
        });
      }).toList();

      return Right(_normalizeGroups(flashcards));
    } catch (e) {
      return Left(NetworkFailure(message: 'Lỗi Gemini: ${e.toString()}'));
    }
  }

  List<Flashcard> _normalizeGroups(List<Flashcard> cards) {
    return cards.map((card) {
      if (card.children.isNotEmpty) {
        return card.copyWith(
          uuid: card.uuid.isEmpty ? const Uuid().v4() : card.uuid,
          dueTime: card.dueTime == 0
              ? DateTime.now().millisecondsSinceEpoch
              : card.dueTime,
          children: card.children
              .map((child) => child.copyWith(
                    uuid: child.uuid.isEmpty ? const Uuid().v4() : child.uuid,
                    dueTime: child.dueTime == 0
                        ? DateTime.now().millisecondsSinceEpoch
                        : child.dueTime,
                  ))
              .toList(),
        );
      }
      return card;
    }).toList();
  }

  Future<Part> _filePart(File file, String apiKey) async {
    final ext = p.extension(file.path).replaceFirst('.', '').toLowerCase();
    const mimeTypes = <String, String>{
      'pdf': 'application/pdf',
      'png': 'image/png',
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'webp': 'image/webp',
      'heic': 'image/heic',
      'heif': 'image/heif',
      'mp3': 'audio/mpeg',
      'wav': 'audio/wav',
      'm4a': 'audio/mp4',
      'aac': 'audio/aac',
      'ogg': 'audio/ogg',
      'flac': 'audio/flac',
      'mp4': 'video/mp4',
      'mpeg': 'video/mpeg',
      'mpg': 'video/mpeg',
      'mov': 'video/quicktime',
      'webm': 'video/webm',
      'avi': 'video/x-msvideo',
      'doc': 'application/msword',
      'docx':
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'ppt': 'application/vnd.ms-powerpoint',
      'pptx':
          'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'xls': 'application/vnd.ms-excel',
      'xlsx':
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'zip': 'application/zip',
    };

    const textExtensions = {
      'txt',
      'md',
      'markdown',
      'csv',
      'tsv',
      'json',
      'jsonl',
      'html',
      'htm',
      'xml',
      'yaml',
      'yml',
      'css',
      'js',
      'ts',
      'dart',
      'py',
      'java',
      'c',
      'h',
      'cpp',
      'cs',
      'go',
      'rs',
      'sql',
      'log',
      'tex',
      'rtf',
      'sh',
      'ps1',
      'ipynb'
    };
    if (textExtensions.contains(ext)) {
      final text = await file.readAsString();
      return TextPart('Nội dung tệp ${file.uri.pathSegments.last}:\n$text');
    }

    if (const {'docx', 'pptx', 'xlsx', 'odt', 'odp', 'ods'}.contains(ext)) {
      final extracted = await _extractOfficeText(file, ext);
      if (extracted.trim().isNotEmpty) {
        return TextPart('Nội dung tệp ${p.basename(file.path)}:\n$extracted');
      }
    }

    final mimeType = mimeTypes[ext] ?? 'application/octet-stream';
    const inlineExtensions = {
      'pdf',
      'png',
      'jpg',
      'jpeg',
      'webp',
      'heic',
      'heif',
      'mp3',
      'wav',
      'm4a',
      'aac',
      'ogg',
      'flac',
      'mp4',
      'mpeg',
      'mpg',
      'mov',
      'webm',
      'avi'
    };
    if (inlineExtensions.contains(ext) &&
        await file.length() <= 18 * 1024 * 1024) {
      return DataPart(mimeType, await file.readAsBytes());
    }
    return FilePart(await _uploadFile(file, mimeType, apiKey));
  }

  Future<String> _extractOfficeText(File file, String extension) async {
    final archive = ZipDecoder().decodeBytes(await file.readAsBytes());
    final xmlFiles = archive.files.where((entry) => entry.isFile);
    String contentOf(ArchiveFile entry) => utf8.decode(
          entry.content as List<int>,
          allowMalformed: true,
        );
    String decodeXml(String value) => value
            .replaceAll('&lt;', '<')
            .replaceAll('&gt;', '>')
            .replaceAll('&quot;', '"')
            .replaceAll('&apos;', "'")
            .replaceAll('&amp;', '&')
            .replaceAllMapped(RegExp(r'&#(x[\da-fA-F]+|\d+);'), (match) {
          final entity = match.group(1)!;
          final codePoint = entity.startsWith('x')
              ? int.parse(entity.substring(1), radix: 16)
              : int.parse(entity);
          return String.fromCharCode(codePoint);
        });
    List<String> textNodes(String xml, RegExp pattern) => pattern
        .allMatches(xml)
        .map((match) => decodeXml(match.group(1) ?? '').trim())
        .where((text) => text.isNotEmpty)
        .toList();

    if (extension == 'docx') {
      final document = xmlFiles.where(
          (entry) => entry.name.replaceAll('\\', '/') == 'word/document.xml');
      if (document.isEmpty) return '';
      return textNodes(contentOf(document.first),
              RegExp(r'<w:t[^>]*>(.*?)</w:t>', dotAll: true))
          .join(' ');
    }

    if (extension == 'pptx') {
      final slides = xmlFiles
          .where((entry) => RegExp(r'^ppt/slides/slide\d+\.xml$')
              .hasMatch(entry.name.replaceAll('\\', '/')))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      return slides
          .map((slide) => textNodes(contentOf(slide),
                  RegExp(r'<a:t[^>]*>(.*?)</a:t>', dotAll: true))
              .join(' '))
          .where((text) => text.isNotEmpty)
          .join('\n');
    }

    if (extension == 'xlsx') {
      final shared = xmlFiles.where((entry) =>
          entry.name.replaceAll('\\', '/') == 'xl/sharedStrings.xml');
      final sharedStrings = shared.isEmpty
          ? <String>[]
          : RegExp(r'<si\b[^>]*>(.*?)</si>', dotAll: true)
              .allMatches(contentOf(shared.first))
              .map((match) => textNodes(match.group(1)!,
                      RegExp(r'<t[^>]*>(.*?)</t>', dotAll: true))
                  .join(''))
              .toList();
      final sheets = xmlFiles
          .where((entry) => RegExp(r'^xl/worksheets/sheet\d+\.xml$')
              .hasMatch(entry.name.replaceAll('\\', '/')))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      return sheets
          .map((sheet) {
            final xml = contentOf(sheet);
            return RegExp(r'<row\b[^>]*>(.*?)</row>', dotAll: true)
                .allMatches(xml)
                .map((row) {
                  return RegExp(r'<c\b([^>]*)>(.*?)</c>', dotAll: true)
                      .allMatches(row.group(1)!)
                      .map((cell) {
                        final attributes = cell.group(1)!;
                        final value = cell.group(2)!;
                        final sharedIndex = RegExp(r'\bt="s"')
                                .hasMatch(attributes)
                            ? int.tryParse(RegExp(r'<v>(.*?)</v>', dotAll: true)
                                    .firstMatch(value)
                                    ?.group(1) ??
                                '')
                            : null;
                        if (sharedIndex != null &&
                            sharedIndex >= 0 &&
                            sharedIndex < sharedStrings.length) {
                          return sharedStrings[sharedIndex];
                        }
                        return textNodes(
                          value,
                          RegExp(r'<(?:v|t)[^>]*>(.*?)</(?:v|t)>',
                              dotAll: true),
                        ).join(' ');
                      })
                      .where((value) => value.isNotEmpty)
                      .join('\t');
                })
                .where((row) => row.isNotEmpty)
                .join('\n');
          })
          .where((sheet) => sheet.isNotEmpty)
          .join('\n');
    }

    final contentXml = xmlFiles
        .where((entry) => entry.name.replaceAll('\\', '/') == 'content.xml');
    if (contentXml.isEmpty) return '';
    return textNodes(contentOf(contentXml.first),
            RegExp(r'<text:[^>]*>(.*?)</text:[^>]*>', dotAll: true))
        .join(' ');
  }

  Future<Uri> _uploadFile(File file, String mimeType, String apiKey) async {
    final dio = Dio();
    final start = await dio.post<dynamic>(
      'https://generativelanguage.googleapis.com/upload/v1beta/files',
      options: Options(headers: {
        'x-goog-api-key': apiKey,
        'X-Goog-Upload-Protocol': 'resumable',
        'X-Goog-Upload-Command': 'start',
        'X-Goog-Upload-Header-Content-Length': '${await file.length()}',
        'X-Goog-Upload-Header-Content-Type': mimeType,
        'Content-Type': 'application/json',
      }),
      data: {
        'file': {'display_name': p.basename(file.path)}
      },
    );
    final uploadUrl = start.headers.value('x-goog-upload-url');
    if (uploadUrl == null || uploadUrl.isEmpty) {
      throw const FormatException('Gemini không trả về địa chỉ tải tệp');
    }

    final finalized = await dio.post<Map<String, dynamic>>(
      uploadUrl,
      data: await file.readAsBytes(),
      options: Options(headers: {
        'x-goog-upload-offset': '0',
        'x-goog-upload-command': 'upload, finalize',
        'Content-Length': '${await file.length()}',
      }),
    );
    var uploaded =
        finalized.data?['file'] as Map<String, dynamic>? ?? finalized.data;
    var state = uploaded?['state']?.toString();
    final name = uploaded?['name']?.toString();
    if (name == null || name.isEmpty) {
      throw const FormatException('Không xác định được tệp vừa tải lên');
    }

    for (var attempt = 0; state != 'ACTIVE' && attempt < 30; attempt++) {
      if (state == 'FAILED') {
        throw const FormatException('Gemini không thể xử lý tệp này');
      }
      await Future<void>.delayed(const Duration(seconds: 1));
      final status = await dio.get<Map<String, dynamic>>(
        'https://generativelanguage.googleapis.com/v1beta/$name',
        options: Options(headers: {'x-goog-api-key': apiKey}),
      );
      uploaded = status.data?['file'] as Map<String, dynamic>? ?? status.data;
      state = uploaded?['state']?.toString();
    }
    final uri = uploaded?['uri']?.toString();
    if (state != 'ACTIVE' || uri == null || uri.isEmpty) {
      throw const FormatException('Gemini chưa hoàn tất xử lý tệp');
    }
    return Uri.parse(uri);
  }

  List<dynamic>? _decodeJsonList(String raw) {
    var text = raw.trim();
    if (text.startsWith('```')) {
      text = text.replaceFirst(RegExp(r'^```(?:json)?'), '').trim();
      if (text.endsWith('```')) {
        text = text.substring(0, text.length - 3).trim();
      }
    }
    try {
      final decoded = jsonDecode(text);
      if (decoded is List) return decoded;
      if (decoded is Map && decoded['cards'] is List) {
        return decoded['cards'] as List;
      }
    } catch (_) {}
    return null;
  }

  @override
  EitherUnit saveAllGeneratedFlashcard(
      String collectionUuid, List<Flashcard> flashcards) async {
    try {
      final result = await _flashcardDataSource.saveAllGeneratedFlashcard(
          collectionUuid, flashcards);
      return Right(result);
    } on Exception catch (e) {
      return Left(LocalStorageFailure(message: e.toString()));
    }
  }

  @override
  EitherUnit combineCollections(FlashcardCollection mainCollection,
      FlashcardCollection secondaryCollection) async {
    try {
      final result = await _collectionDataSource.combineCollections(
          mainCollection, secondaryCollection);
      return Right(result);
    } on Exception catch (e) {
      return Left(LocalStorageFailure(message: e.toString()));
    }
  }

  @override
  EitherUnit importCollection(FlashcardCollection collection) async {
    try {
      final result = await _collectionDataSource.importCollection(collection);
      return Right(result);
    } on Exception catch (e) {
      return Left(LocalStorageFailure(message: e.toString()));
    }
  }

  @override
  EitherUnit importCollections(List<FlashcardCollection> collections) async {
    try {
      final result = await _collectionDataSource.importCollections(collections);
      return Right(result);
    } on Exception catch (error) {
      return Left(LocalStorageFailure(message: error.toString()));
    }
  }
}
