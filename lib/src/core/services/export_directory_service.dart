import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ExportDirectoryService {
  static const _channel = MethodChannel('quizwiz/export_storage');
  static const androidPath = '/storage/emulated/0/QuizWiz';

  static Future<bool> hasAccess() async {
    if (!Platform.isAndroid) return true;
    return await _channel.invokeMethod<bool>('hasExportAccess') ?? false;
  }

  /// Opens Android's all-files access settings, or asks for legacy storage
  /// permission on older Android versions. Returns true when access is ready.
  static Future<bool> requestAccess() async {
    if (!Platform.isAndroid) return true;
    return await _channel.invokeMethod<bool>('requestExportAccess') ?? false;
  }

  static Future<Directory> directory() async {
    if (Platform.isAndroid) {
      final path = await _channel.invokeMethod<String>('getExportDirectory');
      if (path == null || path.isEmpty) {
        throw const ExportDirectoryPermissionException();
      }
      return Directory(path);
    }

    final base = await getDownloadsDirectory() ??
        await getApplicationDocumentsDirectory();
    return Directory(p.join(base.path, 'QuizWiz'));
  }

  static Future<File> saveBytes(String fileName, List<int> bytes) async {
    final dir = await directory();
    await dir.create(recursive: true);
    final file = File(p.join(dir.path, fileName));
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }
}

class ExportDirectoryPermissionException implements Exception {
  const ExportDirectoryPermissionException();

  @override
  String toString() =>
      'Cần cấp quyền truy cập bộ nhớ trong Cài đặt trước khi lưu vào ${ExportDirectoryService.androidPath}';
}
