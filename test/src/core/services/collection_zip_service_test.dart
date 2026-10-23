import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizwiz/src/core/services/collection_zip_service.dart';
import 'package:quizwiz/src/features/cards/data/models/flashcard_collection.dart';

void main() {
  late Directory tempDirectory;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('quizwiz_zip_test_');
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('imports multiple collection ZIP files from one outer ZIP', () async {
    final outerArchive = Archive();
    outerArchive.addFile(_nestedCollectionZip('Biology', 'cell'));
    outerArchive.addFile(_nestedCollectionZip('History', 'empire'));
    final bytes = ZipEncoder().encode(outerArchive)!;
    final zipFile = File('${tempDirectory.path}/collections.zip');
    await zipFile.writeAsBytes(bytes);

    final collections =
        await CollectionZipService.importCollectionsFromZip(zipFile);

    expect(collections.map((collection) => collection.name),
        ['Biology', 'History']);
    expect(collections.map((collection) => collection.uuid).toSet().length, 2);
    expect(collections.map((collection) => collection.cards.single.question),
        ['cell', 'empire']);
  });

  test('imports a single collection ZIP for backward compatibility', () async {
    final innerArchive = Archive();
    innerArchive.addFile(_collectionJson('Language', 'word'));
    final zipFile = File('${tempDirectory.path}/single.zip');
    await zipFile.writeAsBytes(ZipEncoder().encode(innerArchive)!);

    final collections =
        await CollectionZipService.importCollectionsFromZip(zipFile);

    expect(collections, hasLength(1));
    expect(collections.single.name, 'Language');
    expect(collections.single.cards.single.question, 'word');
  });
}

ArchiveFile _nestedCollectionZip(String name, String question) {
  final nested = Archive()..addFile(_collectionJson(name, question));
  final bytes = ZipEncoder().encode(nested)!;
  return ArchiveFile('$name.zip', bytes.length, bytes);
}

ArchiveFile _collectionJson(String name, String question) {
  final collection = FlashcardCollection(
    name: name,
    uuid: 'source-$name',
    cards: [Flashcard(uuid: 'card-$name', question: question)],
  );
  final bytes = utf8.encode(jsonEncode(collection.toJson()));
  return ArchiveFile('collection.json', bytes.length, bytes);
}
