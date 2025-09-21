// Infrastructure-Adapter: implementiert das Domain-Interface.
// Ich programmiere gegen ein Repository-Interface und nutze für die Challenge ein Fake. 
// So bleiben UI/VM unabhängig vom Transport, Tests sind schnell, und die Datenquelle ist 
// später austauschbar – klassisches SoC/MVVM/4-Layer.

import 'dart:async';
import 'package:quiz_challenge/domain/quiz_repository.dart';
import 'package:quiz_challenge/domain/question.dart';

class FakeQuizRepository implements QuizRepository {
  @override
  Future<List<Question>> fetchQuestions() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return [
      Question(text: "What is 2+2?", options: ["3", "4", "5"], correctAnswer: "4"),
      Question(text: "Capital of France?", options: ["Paris", "London", "Berlin"], correctAnswer: "Paris"),
      Question(text: "What color is the sky?", options: ["Blue", "Green", "Red"], correctAnswer: "Blue"),
      Question(text: "Which language runs on the JVM?", options: ["Kotlin", "Swift", "JavaScript"], correctAnswer: "Kotlin"),
    ];
  }
}
