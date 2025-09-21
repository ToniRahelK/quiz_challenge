// quiz_repository.dart
// Domain-Interface (Port). Keine Infrastruktur-Details.
import 'dart:async'; // für Future, da ausgelagert aus main
import 'question.dart';

abstract class QuizRepository {
  Future<List<Question>> fetchQuestions();
}
