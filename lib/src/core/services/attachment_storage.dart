import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:quizwiz/src/features/cards/data/data.dart';
import 'package:uuid/uuid.dart';

class AttachmentStorage {
  static const uuid = Uuid();

  static Future<Directory> rootDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final root = Directory(p.join(dir.path, 'attachments'));
    if (!await root.exists()) {
      await root.create(recursive: true);
    }
    return root;
  }

  static Future<String> absolutePath(String relative) async {
    return p.join((await rootDir()).path, relative);
  }

  static Future<CardAttachment> saveLocalFile({
    required String collectionUuid,
    required String cardUuid,
    required File file,
    required String type,
    int playLimit = 0,
  }) async {
    final ext = p.extension(file.path);
    final fileName =
        '${cardUuid}_${DateTime.now().millisecondsSinceEpoch}$ext';
    final relative = p.join(collectionUuid, fileName);
    final dest = File(p.join((await rootDir()).path, relative));
    await dest.parent.create(recursive: true);
    await file.copy(dest.path);
    return CardAttachment(
      type: type,
      source: relative.replaceAll('\\', '/'),
      fileName: p.basename(file.path),
      isRemote: false,
      playLimit: playLimit,
    );
  }

  static Future<void> copyRelative({
    required String fromAbsolute,
    required String collectionUuid,
    required String relative,
  }) async {
    final dest = File(p.join((await rootDir()).path, relative));
    await dest.parent.create(recursive: true);
    await File(fromAbsolute).copy(dest.path);
  }

  static CardAttachment remote({
    required String url,
    required String type,
    int playLimit = 0,
  }) {
    return CardAttachment(
      type: type,
      source: url.trim(),
      fileName: url.trim(),
      isRemote: true,
      playLimit: playLimit,
    );
  }
}
