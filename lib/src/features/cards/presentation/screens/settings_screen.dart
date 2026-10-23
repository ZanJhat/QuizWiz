import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quizwiz/src/core/theme/cubit/theme_cubit.dart';
import 'package:quizwiz/src/core/services/card_template_service.dart';
import 'package:quizwiz/src/core/services/export_directory_service.dart';
import 'package:quizwiz/src/core/services/gemini_settings_store.dart';
import 'package:quizwiz/src/core/services/quiz_display_settings_store.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  final _apiKeyController = TextEditingController();
  final _modelController = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  bool _showApiKey = false;
  bool _hasExportAccess = !Platform.isAndroid;
  QuizDisplaySettings _displaySettings = const QuizDisplaySettings();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
    _refreshExportAccess();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _apiKeyController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshExportAccess();
  }

  Future<void> _loadSettings() async {
    var settings = const GeminiSettings(
      apiKey: '',
      model: GeminiSettingsStore.defaultModel,
    );
    String? settingsError;
    try {
      settings = await GeminiSettingsStore.load();
    } catch (error) {
      settingsError = 'Không đọc được file cấu hình Gemini: $error';
    }
    var displaySettings = const QuizDisplaySettings();
    try {
      displaySettings = await QuizDisplaySettingsStore.load();
    } catch (error) {
      settingsError ??= 'Không tải được cài đặt cỡ chữ: $error';
    }
    if (!mounted) return;
    _apiKeyController.text = settings.apiKey;
    _modelController.text = settings.model;
    setState(() {
      _displaySettings = displaySettings;
      _loading = false;
    });
    if (settingsError != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(settingsError)));
    }
  }

  Future<void> _saveDisplaySettings() async {
    try {
      await QuizDisplaySettingsStore.save(_displaySettings);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không lưu được cỡ chữ: $error')),
      );
    }
  }

  Future<void> _refreshExportAccess() async {
    final hasAccess = await ExportDirectoryService.hasAccess();
    if (mounted) setState(() => _hasExportAccess = hasAccess);
  }

  Future<void> _saveSettings() async {
    setState(() => _saving = true);
    try {
      await GeminiSettingsStore.save(
        apiKey: _apiKeyController.text,
        model: _modelController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã lưu cấu hình Gemini vào thư mục QuizWiz'),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không lưu được cấu hình: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _requestExportAccess() async {
    try {
      final granted = await ExportDirectoryService.requestAccess();
      await _refreshExportAccess();
      if (!mounted) return;
      final message = granted || _hasExportAccess
          ? 'Đã bật quyền lưu vào thư mục QuizWiz'
          : 'Hãy bật “Cho phép quản lý tất cả tệp”, quay lại app rồi kiểm tra lại.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không mở được cài đặt quyền: $error')),
      );
    }
  }

  Future<void> _downloadTemplate({required bool asZip}) async {
    try {
      if (Platform.isAndroid && !_hasExportAccess) {
        await _requestExportAccess();
        if (!mounted || !_hasExportAccess) return;
      }
      final path = asZip
          ? await CardTemplateService.saveTemplateZip()
          : await CardTemplateService.saveTextTemplate();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã lưu mẫu tại: $path')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể tải mẫu: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Giao diện',
                    style: Theme.of(context).textTheme.titleLarge),
                BlocBuilder<ThemeCubit, ThemeMode>(
                  builder: (context, themeMode) => SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: Icon(themeMode == ThemeMode.dark
                        ? Icons.dark_mode_outlined
                        : Icons.light_mode_outlined),
                    title: const Text('Giao diện tối'),
                    subtitle: Text(themeMode == ThemeMode.dark
                        ? 'Đang bật chế độ tối'
                        : 'Đang bật chế độ sáng'),
                    value: themeMode == ThemeMode.dark,
                    onChanged: (isDark) => context
                        .read<ThemeCubit>()
                        .setTheme(isDark ? ThemeMode.dark : ThemeMode.light),
                  ),
                ),
                const Divider(height: 36),
                Text('Cỡ chữ khi học',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                _fontSizeSetting(
                  title: 'Ôn tập - câu hỏi trước khi lật',
                  value: _displaySettings.reviewQuestionBeforeFlipSize,
                  onChanged: (value) => setState(() {
                    _displaySettings = _displaySettings.copyWith(
                      reviewQuestionBeforeFlipSize: value,
                    );
                  }),
                ),
                _fontSizeSetting(
                  title: 'Ôn tập - câu hỏi sau khi lật',
                  value: _displaySettings.reviewQuestionAfterFlipSize,
                  onChanged: (value) => setState(() {
                    _displaySettings = _displaySettings.copyWith(
                      reviewQuestionAfterFlipSize: value,
                    );
                  }),
                ),
                _fontSizeSetting(
                  title: 'Ôn tập - đáp án sau khi lật',
                  value: _displaySettings.reviewAnswerAfterFlipSize,
                  onChanged: (value) => setState(() {
                    _displaySettings = _displaySettings.copyWith(
                      reviewAnswerAfterFlipSize: value,
                    );
                  }),
                ),
                _fontSizeSetting(
                  title: 'Luyện tập - câu hỏi',
                  value: _displaySettings.practiceQuestionSize,
                  onChanged: (value) => setState(() {
                    _displaySettings = _displaySettings.copyWith(
                      practiceQuestionSize: value,
                    );
                  }),
                ),
                const Divider(height: 36),
                Text('Gemini AI',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                const Text(
                  'Cấu hình được lưu trong file gemini_config.json ở thư mục QuizWiz bên ngoài. Không có API key mặc định; hãy nhập key của bạn tại đây.',
                ),
                const SizedBox(height: 4),
                Text(
                  Platform.isAndroid
                      ? '${ExportDirectoryService.androidPath}/${GeminiSettingsStore.fileName}'
                      : 'QuizWiz/${GeminiSettingsStore.fileName} trong thư mục Downloads hoặc Documents',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _apiKeyController,
                  obscureText: !_showApiKey,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                    labelText: 'Gemini API key',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      tooltip: _showApiKey ? 'Ẩn API key' : 'Hiện API key',
                      onPressed: () =>
                          setState(() => _showApiKey = !_showApiKey),
                      icon: Icon(_showApiKey
                          ? Icons.visibility_off
                          : Icons.visibility),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _modelController,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Tên Gemini model',
                    hintText: GeminiSettingsStore.defaultModel,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _saving ? null : _saveSettings,
                  icon: const Icon(Icons.save),
                  label: Text(_saving ? 'Đang lưu…' : 'Lưu cấu hình Gemini'),
                ),
                const Divider(height: 36),
                Text('Mẫu định dạng Card',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                const Text(
                  'Mẫu TXT được cập nhật schema trực tiếp từ model Card/Collection hiện tại. AI trong ứng dụng cũng đọc chính mẫu này mỗi lần tạo card.',
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _downloadTemplate(asZip: false),
                  icon: const Icon(Icons.text_snippet_outlined),
                  label: const Text('Tải mẫu Card (.txt)'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _downloadTemplate(asZip: true),
                  icon: const Icon(Icons.folder_zip_outlined),
                  label: const Text('Tải bộ mẫu Card (.zip)'),
                ),
                const Divider(height: 36),
                Text('Thư mục xuất',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  Platform.isAndroid
                      ? ExportDirectoryService.androidPath
                      : 'Thư mục QuizWiz trong Downloads (hoặc Documents nếu Downloads không khả dụng)',
                ),
                const SizedBox(height: 8),
                Text(
                  _hasExportAccess
                      ? 'Đã có quyền lưu. File ZIP collection và mẫu tải xuống sẽ nằm trong thư mục này.'
                      : 'Cần quyền Android “Quản lý tất cả tệp” để lưu cùng cấp với Download và dễ tìm bằng trình quản lý tệp.',
                ),
                if (Platform.isAndroid) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _requestExportAccess,
                    icon: Icon(_hasExportAccess
                        ? Icons.check_circle_outline
                        : Icons.folder_open_outlined),
                    label: Text(_hasExportAccess
                        ? 'Kiểm tra quyền lưu'
                        : 'Cấp quyền lưu thư mục QuizWiz'),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _fontSizeSetting({
    required String title,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(title),
          trailing: Text('${value.round()}'),
        ),
        Slider(
          min: 16,
          max: 48,
          divisions: 32,
          value: value.clamp(16, 48).toDouble(),
          label: value.round().toString(),
          onChanged: onChanged,
          onChangeEnd: (_) => _saveDisplaySettings(),
        ),
      ],
    );
  }
}
