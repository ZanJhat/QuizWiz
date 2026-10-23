import 'package:shared_preferences/shared_preferences.dart';

class QuizDisplaySettings {
  static const reviewQuestionBeforeFlipDefault = 36.0;
  static const reviewQuestionAfterFlipDefault = 36.0;
  static const reviewAnswerAfterFlipDefault = 28.0;
  static const practiceQuestionDefault = 36.0;

  final double reviewQuestionBeforeFlipSize;
  final double reviewQuestionAfterFlipSize;
  final double reviewAnswerAfterFlipSize;
  final double practiceQuestionSize;

  const QuizDisplaySettings({
    this.reviewQuestionBeforeFlipSize = reviewQuestionBeforeFlipDefault,
    this.reviewQuestionAfterFlipSize = reviewQuestionAfterFlipDefault,
    this.reviewAnswerAfterFlipSize = reviewAnswerAfterFlipDefault,
    this.practiceQuestionSize = practiceQuestionDefault,
  });

  QuizDisplaySettings copyWith({
    double? reviewQuestionBeforeFlipSize,
    double? reviewQuestionAfterFlipSize,
    double? reviewAnswerAfterFlipSize,
    double? practiceQuestionSize,
  }) {
    return QuizDisplaySettings(
      reviewQuestionBeforeFlipSize:
          reviewQuestionBeforeFlipSize ?? this.reviewQuestionBeforeFlipSize,
      reviewQuestionAfterFlipSize:
          reviewQuestionAfterFlipSize ?? this.reviewQuestionAfterFlipSize,
      reviewAnswerAfterFlipSize:
          reviewAnswerAfterFlipSize ?? this.reviewAnswerAfterFlipSize,
      practiceQuestionSize: practiceQuestionSize ?? this.practiceQuestionSize,
    );
  }
}

class QuizDisplaySettingsStore {
  static const _reviewQuestionBeforeFlipKey =
      'quizwiz_review_question_before_flip_size';
  static const _reviewQuestionAfterFlipKey =
      'quizwiz_review_question_after_flip_size';
  static const _reviewAnswerAfterFlipKey =
      'quizwiz_review_answer_after_flip_size';
  static const _practiceQuestionKey = 'quizwiz_practice_question_size';

  static Future<QuizDisplaySettings> load() async {
    final preferences = await SharedPreferences.getInstance();
    return QuizDisplaySettings(
      reviewQuestionBeforeFlipSize: _readSize(
        preferences,
        _reviewQuestionBeforeFlipKey,
        QuizDisplaySettings.reviewQuestionBeforeFlipDefault,
      ),
      reviewQuestionAfterFlipSize: _readSize(
        preferences,
        _reviewQuestionAfterFlipKey,
        QuizDisplaySettings.reviewQuestionAfterFlipDefault,
      ),
      reviewAnswerAfterFlipSize: _readSize(
        preferences,
        _reviewAnswerAfterFlipKey,
        QuizDisplaySettings.reviewAnswerAfterFlipDefault,
      ),
      practiceQuestionSize: _readSize(
        preferences,
        _practiceQuestionKey,
        QuizDisplaySettings.practiceQuestionDefault,
      ),
    );
  }

  static Future<void> save(QuizDisplaySettings settings) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setDouble(
      _reviewQuestionBeforeFlipKey,
      settings.reviewQuestionBeforeFlipSize,
    );
    await preferences.setDouble(
      _reviewQuestionAfterFlipKey,
      settings.reviewQuestionAfterFlipSize,
    );
    await preferences.setDouble(
      _reviewAnswerAfterFlipKey,
      settings.reviewAnswerAfterFlipSize,
    );
    await preferences.setDouble(
      _practiceQuestionKey,
      settings.practiceQuestionSize,
    );
  }

  static double _readSize(
    SharedPreferences preferences,
    String key,
    double defaultValue,
  ) {
    final value = preferences.get(key);
    if (value is! num || !value.isFinite) return defaultValue;
    return value.toDouble().clamp(16, 48).toDouble();
  }
}
