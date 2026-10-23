import 'package:flutter_test/flutter_test.dart';
import 'package:quizwiz/src/core/services/quiz_display_settings_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('loads defaults and persists customized font sizes', () async {
    final defaults = await QuizDisplaySettingsStore.load();
    expect(
      defaults.reviewQuestionBeforeFlipSize,
      QuizDisplaySettings.reviewQuestionBeforeFlipDefault,
    );
    expect(
      defaults.reviewQuestionAfterFlipSize,
      QuizDisplaySettings.reviewQuestionAfterFlipDefault,
    );
    expect(
      defaults.reviewAnswerAfterFlipSize,
      QuizDisplaySettings.reviewAnswerAfterFlipDefault,
    );
    expect(
      defaults.practiceQuestionSize,
      QuizDisplaySettings.practiceQuestionDefault,
    );

    const customized = QuizDisplaySettings(
      reviewQuestionBeforeFlipSize: 24,
      reviewQuestionAfterFlipSize: 26,
      reviewAnswerAfterFlipSize: 20,
      practiceQuestionSize: 32,
    );
    await QuizDisplaySettingsStore.save(customized);

    final restored = await QuizDisplaySettingsStore.load();
    expect(restored.reviewQuestionBeforeFlipSize, 24);
    expect(restored.reviewQuestionAfterFlipSize, 26);
    expect(restored.reviewAnswerAfterFlipSize, 20);
    expect(restored.practiceQuestionSize, 32);
  });

  test('keeps stored font sizes within the supported range', () async {
    SharedPreferences.setMockInitialValues({
      'quizwiz_review_question_before_flip_size': 100.0,
    });

    final settings = await QuizDisplaySettingsStore.load();

    expect(settings.reviewQuestionBeforeFlipSize, 48);
  });
}
