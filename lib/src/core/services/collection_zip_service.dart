import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:quizwiz/src/core/services/attachment_storage.dart';
import 'package:quizwiz/src/core/services/export_directory_service.dart';
import 'package:quizwiz/src/features/cards/data/data.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

class CollectionZipService {
  static const _uuid = Uuid();

  static Future<File> exportToZip(FlashcardCollection collection) async {
    final archive = Archive();
    final payload = collection.toJson();
    final jsonBytes =
        utf8.encode(const JsonEncoder.withIndent('  ').convert(payload));
    archive
        .addFile(ArchiveFile('collection.json', jsonBytes.length, jsonBytes));

    final root = await AttachmentStorage.rootDir();
    for (final attachment in collection.cards.expand(_attachmentsForCard)) {
      if (attachment.isRemote || attachment.source.isEmpty) continue;
      final file = File(p.join(root.path, attachment.source));
      if (!await file.exists()) continue;
      final bytes = await file.readAsBytes();
      final zipPath = 'attachments/${attachment.source}'.replaceAll('\\', '/');
      archive.addFile(ArchiveFile(zipPath, bytes.length, bytes));
    }

    final encoded = ZipEncoder().encode(archive);
    if (encoded == null) {
      throw Exception('Không thể tạo file zip');
    }
    final safeName = collection.name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    return ExportDirectoryService.saveBytes('$safeName-quizwiz.zip', encoded);
  }

  static Iterable<CardAttachment> _attachmentsForCard(Flashcard card) sync* {
    yield* card.attachments;
    for (final child in card.children) {
      yield* _attachmentsForCard(child);
    }
  }

  static Future<File> shareCollection(FlashcardCollection collection) async {
    final zip = await exportToZip(collection);
    await Share.shareXFiles(
      [XFile(zip.path)],
      text: 'QuizWiz collection: ${collection.name}',
    );
    return zip;
  }

  static Future<FlashcardCollection> importFromZip(File zipFile) async {
    final collections = await importCollectionsFromZip(zipFile);
    if (collections.length != 1) {
      throw FormatException(
        'File ZIP chứa ${collections.length} collection; hãy dùng chức năng nhập nhiều collection.',
      );
    }
    return collections.single;
  }

  static Future<List<FlashcardCollection>> importCollectionsFromZip(
      File zipFile) async {
    final archive = ZipDecoder().decodeBytes(await zipFile.readAsBytes());
    if (_containsCollectionJson(archive)) {
      return [await _importCollectionArchive(archive)];
    }

    final collectionArchives = archive.files
        .where((file) =>
            file.isFile && p.extension(file.name).toLowerCase() == '.zip')
        .toList();
    if (collectionArchives.isEmpty) {
      throw const FormatException(
        'File ZIP không chứa collection.json hoặc các file ZIP collection.',
      );
    }

    final collections = <FlashcardCollection>[];
    for (final nestedZip in collectionArchives) {
      try {
        final nestedArchive =
            ZipDecoder().decodeBytes(nestedZip.content as List<int>);
        if (!_containsCollectionJson(nestedArchive)) {
          throw const FormatException('Thiếu collection.json');
        }
        collections.add(await _importCollectionArchive(nestedArchive));
      } catch (error) {
        throw FormatException(
          'Không thể nhập "${nestedZip.name}": $error',
        );
      }
    }
    return collections;
  }

  static bool _containsCollectionJson(Archive archive) =>
      archive.files.any((file) =>
          file.isFile &&
          p.posix.basename(file.name.replaceAll('\\', '/')) ==
              'collection.json');

  static Future<FlashcardCollection> _importCollectionArchive(
      Archive archive) async {
    ArchiveFile? jsonFile;
    for (final file in archive.files) {
      final name = file.name.replaceAll('\\', '/');
      if (file.isFile && p.posix.basename(name) == 'collection.json') {
        jsonFile = file;
        break;
      }
    }
    if (jsonFile == null) {
      throw Exception('File zip không chứa collection.json');
    }
    final map = jsonDecode(utf8.decode(jsonFile.content as List<int>))
        as Map<String, dynamic>;
    final imported = FlashcardCollection.fromJson(map);
    final newCollectionUuid = _uuid.v4();
    final extractRoot =
        await Directory.systemTemp.createTemp('quizwiz_import_');
    try {
      final newCards = <Flashcard>[];
      for (final card in imported.cards) {
        newCards.add(await _importCard(
          card,
          archive: archive,
          extractRoot: extractRoot,
          collectionUuid: newCollectionUuid,
        ));
      }
      return FlashcardCollection(
        name: imported.name,
        description: imported.description,
        uuid: newCollectionUuid,
        cards: newCards,
      );
    } finally {
      if (await extractRoot.exists()) await extractRoot.delete(recursive: true);
    }
  }

  static Future<Flashcard> _importCard(
    Flashcard card, {
    required Archive archive,
    required Directory extractRoot,
    required String collectionUuid,
  }) async {
    final cardUuid = _uuid.v4();
    final attachments = await _importAttachments(
      card.attachments,
      archive: archive,
      extractRoot: extractRoot,
      collectionUuid: collectionUuid,
      cardUuid: cardUuid,
    );
    final children = <Flashcard>[];
    for (final child in card.children) {
      children.add(await _importCard(
        child,
        archive: archive,
        extractRoot: extractRoot,
        collectionUuid: collectionUuid,
      ));
    }
    return card.copyWith(
      uuid: cardUuid,
      attachments: attachments,
      children: children,
      dueTime: DateTime.now().millisecondsSinceEpoch,
    );
  }

  static Future<List<CardAttachment>> _importAttachments(
    List<CardAttachment> attachments, {
    required Archive archive,
    required Directory extractRoot,
    required String collectionUuid,
    required String cardUuid,
  }) async {
    final importedAttachments = <CardAttachment>[];
    for (final attachment in attachments) {
      if (attachment.isRemote) {
        importedAttachments.add(attachment);
        continue;
      }
      final zipRelative = attachment.source.replaceAll('\\', '/');
      final segments = p.posix.split(zipRelative);
      if (p.posix.isAbsolute(zipRelative) ||
          segments.any((part) => part == '..' || part.isEmpty)) {
        continue;
      }
      final archivePath = 'attachments/$zipRelative';
      ArchiveFile? mediaFile;
      for (final candidate in archive.files) {
        if (candidate.isFile &&
            candidate.name.replaceAll('\\', '/') == archivePath) {
          mediaFile = candidate;
          break;
        }
      }
      if (mediaFile == null) continue;
      final sourceFile = File(p.join(
        extractRoot.path,
        '${_uuid.v4()}${p.extension(attachment.fileName.isEmpty ? zipRelative : attachment.fileName)}',
      ));
      await sourceFile.writeAsBytes(mediaFile.content as List<int>);
      final saved = await AttachmentStorage.saveLocalFile(
        collectionUuid: collectionUuid,
        cardUuid: cardUuid,
        file: sourceFile,
        type: attachment.type,
        playLimit: attachment.playLimit,
      );
      importedAttachments.add(saved.copyWith(fileName: attachment.fileName));
    }
    return importedAttachments;
  }

  static Future<File?> pickZip() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['zip'],
    );
    final path = result?.files.single.path;
    if (path == null) return null;
    return File(path);
  }
}
