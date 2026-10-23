import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:quizwiz/src/core/services/export_directory_service.dart';

class GeminiSettings {
  final String apiKey;
  final String model;

  const GeminiSettings({required this.apiKey, required this.model});
}

class GeminiSettingsStore {
  static const defaultModel = 'gemini-3.8-flash';
  static const fileName = 'gemini_config.json';

  static Future<File> _configFile() async {
    final directory = await ExportDirectoryService.directory();
    return File(p.join(directory.path, fileName));
  }

  static Future<GeminiSettings> load() async {
    final file = await _configFile();
    if (!await file.exists()) {
      return const GeminiSettings(apiKey: '', model: defaultModel);
    }

    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map<String, dynamic> ||
        decoded['apiKey'] is! String ||
        decoded['model'] is! String) {
      throw const FormatException(
        'File cấu hình Gemini phải có apiKey và model dạng chuỗi.',
      );
    }
    return GeminiSettings(
      apiKey: (decoded['apiKey'] as String).trim(),
      model: (decoded['model'] as String).trim().isEmpty
          ? defaultModel
          : (decoded['model'] as String).trim(),
    );
  }

  static Future<void> save({
    required String apiKey,
    required String model,
  }) async {
    final file = await _configFile();
    await file.parent.create(recursive: true);
    final settings = {
      'apiKey': apiKey.trim(),
      'model': model.trim().isEmpty ? defaultModel : model.trim(),
    };
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(settings),
      flush: true,
    );
  }
}
