// start_quiz.dart
// Use-Case: kapselt die Orchestrierung "Fragen laden".
// VM kennt nur diesen Use-Case, nicht die Infrastruktur.
import 'dart:async';
import 'package:quiz_challenge/domain/quiz_repository.dart';
import 'package:quiz_challenge/domain/question.dart';

class StartQuiz {
  final QuizRepository repo;
  StartQuiz(this.repo);

  Future<List<Question>> call() => repo.fetchQuestions();
}
