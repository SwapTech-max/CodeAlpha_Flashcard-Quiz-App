import 'package:hive/hive.dart';

part 'flashcard_model.g.dart';

@HiveType(typeId: 0)
class Flashcard extends HiveObject {
  @HiveField(0)
  String question;

  @HiveField(1)
  String answer;

  @HiveField(2)
  String type; // 'single' or 'mcq'

  @HiveField(3)
  List<String>? options;

  Flashcard({
    required this.question,
    required this.answer,
    this.type = 'single',
    this.options,
  });
}