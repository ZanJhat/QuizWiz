// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

part 'flashcard_collection.g.dart';

@collection
class FlashcardCollection {
  String name;
  String description;
  List<Flashcard> cards;
  Id id = Isar.autoIncrement;
  @Index(unique: true, replace: true, type: IndexType.hash)
  final String uuid;
  FlashcardCollection({
    required this.name,
    required this.uuid,
    this.description = '',
    this.cards = const [],
  });

  FlashcardCollection copyWith({
    String? name,
    String? description,
    List<Flashcard>? cards,
    Id? id,
    String? uuid,
  }) {
    final collection = FlashcardCollection(
      name: name ?? this.name,
      description: description ?? this.description,
      cards: cards ?? this.cards,
      uuid: uuid ?? this.uuid,
    );
    // Keep the Isar primary key when updating an existing collection. Without
    // this, every copy is inserted with autoIncrement and relies on the unique
    // UUID index to replace the old row.
    collection.id = id ?? this.id;
    return collection;
  }

  Map<String, dynamic> toJson() {
    return {
      'version': 4,
      'name': name,
      'description': description,
      'uuid': uuid,
      'cards': cards.map((c) => c.toJson()).toList(),
    };
  }

  factory FlashcardCollection.fromJson(Map<String, dynamic> map) {
    return FlashcardCollection(
      name: map['name']?.toString() ?? 'untitled',
      description: map['description']?.toString() ?? '',
      uuid: map['uuid']?.toString() ?? const Uuid().v4(),
      cards: (map['cards'] as List? ?? [])
          .map((e) => Flashcard.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

@embedded
class Flashcard {
  String question;
  String answer;
  String note;
  int dueTime;
  double interval;
  double factor;
  int repetitions;
  final String uuid;
  List<String> choices;
  int correctChoiceIndex;
  List<CardAttachment> attachments;
  List<Flashcard> children;
  List<String> tags;
  Flashcard({
    this.uuid = '',
    this.question = '',
    this.answer = '',
    this.note = '',
    this.dueTime = 0,
    this.interval = 1.0,
    this.factor = 2.5,
    this.repetitions = 0,
    this.choices = const [],
    this.correctChoiceIndex = 0,
    this.attachments = const [],
    this.children = const [],
    this.tags = const [],
  });

  bool get isGroup => children.isNotEmpty;

  List<Flashcard> get questions => isGroup ? children : [this];

  Flashcard get reviewCard => isGroup
      ? copyWith(
          question: children.map((child) => child.question).join('\n'),
          answer: children
              .map((child) => '${child.question}\n${child.writingQuizAnswer}')
              .join('\n\n'),
          children: const [],
        )
      : this;

  bool get hasFixedChoices => choices.any((choice) => choice.trim().isNotEmpty);

  List<String> get filledChoices =>
      choices.map((c) => c.trim()).where((c) => c.isNotEmpty).toList();

  /// Older cards can have no stored slots. Treat those as four blank slots so
  /// letter-based quizzes remain usable without changing the serialized data.
  List<String> get choiceSlots =>
      choices.isEmpty ? List<String>.filled(4, '') : choices;

  int get resolvedCorrectChoiceIndex {
    final slots = choiceSlots;
    var index = correctChoiceIndex;
    if (index < -0x7fffffff) {
      // Malformed embedded-card values retain the selected slot in the low byte.
      final recoveredIndex = index & 0xff;
      if (recoveredIndex < slots.length) index = recoveredIndex;
    }
    return index.clamp(0, slots.length - 1).toInt();
  }

  String get correctChoiceLetter =>
      String.fromCharCode(65 + resolvedCorrectChoiceIndex);

  String get writingQuizAnswer {
    if (answer.trim().isNotEmpty) return answer.trim();
    final correctChoice = choiceSlots[resolvedCorrectChoiceIndex].trim();
    return correctChoice.isNotEmpty ? correctChoice : correctChoiceLetter;
  }

  String get resolvedAnswer {
    final slots = choiceSlots;
    final correctChoice = slots[resolvedCorrectChoiceIndex].trim();
    if (correctChoice.isNotEmpty) {
      return correctChoice;
    }
    return answer;
  }

  Flashcard copyWith({
    String? question,
    String? answer,
    String? note,
    int? dueTime,
    double? interval,
    double? factor,
    int? repetitions,
    String? uuid,
    List<String>? choices,
    int? correctChoiceIndex,
    List<CardAttachment>? attachments,
    List<Flashcard>? children,
    List<String>? tags,
  }) {
    return Flashcard(
      question: question ?? this.question,
      answer: answer ?? this.answer,
      note: note ?? this.note,
      dueTime: dueTime ?? this.dueTime,
      interval: interval ?? this.interval,
      factor: factor ?? this.factor,
      repetitions: repetitions ?? this.repetitions,
      uuid: uuid ?? this.uuid,
      choices: choices ?? this.choices,
      correctChoiceIndex: correctChoiceIndex ?? this.correctChoiceIndex,
      attachments: attachments ?? this.attachments,
      children: children ?? this.children,
      tags: tags ?? this.tags,
    );
  }

  factory Flashcard.fromMap(Map<String, dynamic> map) {
    return Flashcard.fromJson(map);
  }

  factory Flashcard.fromJson(Map<String, dynamic> map) {
    final rawChoices = map['choices'] as List? ?? const [];
    final choices = rawChoices.map((e) => e.toString()).toList();
    final answer =
        map['answer']?.toString() ?? map['definition']?.toString() ?? '';
    var correct = 0;
    final rawIndex = map['correctChoiceIndex'];
    if (rawIndex is int) {
      correct = rawIndex;
    } else if (rawIndex != null) {
      correct = int.tryParse(rawIndex.toString()) ?? 0;
    } else if (choices.isNotEmpty) {
      final match = choices.indexWhere((c) => c.trim() == answer.trim());
      if (match >= 0) correct = match;
    }
    return Flashcard(
      question: map['question']?.toString() ?? map['term']?.toString() ?? '',
      answer: answer,
      note: map['note']?.toString() ?? '',
      uuid: map['uuid']?.toString().isNotEmpty == true
          ? map['uuid'].toString()
          : const Uuid().v4(),
      dueTime: map['dueTime'] is int ? map['dueTime'] as int : 0,
      interval: (map['interval'] as num?)?.toDouble() ?? 1.0,
      factor: (map['factor'] as num?)?.toDouble() ?? 2.5,
      repetitions: map['repetitions'] as int? ?? 0,
      choices: choices,
      correctChoiceIndex: correct,
      children: (map['children'] as List? ?? [])
          .map((e) => Flashcard.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      tags: (map['tags'] as List? ?? const [])
          .map((tag) => tag.toString())
          .toList(),
      attachments: (map['attachments'] as List? ?? [])
          .map((e) =>
              CardAttachment.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'question': question,
      'answer': answer,
      'note': note,
      'dueTime': dueTime,
      'interval': interval,
      'factor': factor,
      'repetitions': repetitions,
      'choices': choices,
      'correctChoiceIndex': resolvedCorrectChoiceIndex,
      'attachments': attachments.map((a) => a.toJson()).toList(),
      'children': children.map((card) => card.toJson()).toList(),
      'tags': tags,
    };
  }
}

@embedded
class CardAttachment {
  /// image | video | audio | embed
  static const supportedTypes = ['image', 'video', 'audio', 'embed'];

  String type;

  /// Relative local path or remote URL
  String source;
  String fileName;
  bool isRemote;

  /// 0 = unlimited plays
  int playLimit;

  CardAttachment({
    this.type = 'image',
    this.source = '',
    this.fileName = '',
    this.isRemote = false,
    this.playLimit = 0,
  });

  bool get isUnlimited => playLimit <= 0;

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'source': source,
      'fileName': fileName,
      'isRemote': isRemote,
      'playLimit': playLimit,
    };
  }

  factory CardAttachment.fromJson(Map<String, dynamic> map) {
    return CardAttachment(
      type: map['type']?.toString() ?? 'image',
      source: map['source']?.toString() ?? '',
      fileName: map['fileName']?.toString() ?? '',
      isRemote: map['isRemote'] == true,
      playLimit: map['playLimit'] is int
          ? map['playLimit'] as int
          : int.tryParse('${map['playLimit']}') ?? 0,
    );
  }

  CardAttachment copyWith({
    String? type,
    String? source,
    String? fileName,
    bool? isRemote,
    int? playLimit,
  }) {
    return CardAttachment(
      type: type ?? this.type,
      source: source ?? this.source,
      fileName: fileName ?? this.fileName,
      isRemote: isRemote ?? this.isRemote,
      playLimit: playLimit ?? this.playLimit,
    );
  }
}
