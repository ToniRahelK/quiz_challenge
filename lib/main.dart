// main.dart
// Einziger Ort, wo Infra konkret gebaut wird. Abhängigkeiten zeigen nach innen.
import 'package:flutter/material.dart';
import 'package:quiz_challenge/infrastructure/fake_quiz_repository.dart'; // Infrastructure
import 'package:quiz_challenge/application/start_quiz.dart';           // Application
import 'package:quiz_challenge/presentation/quiz_view_model.dart';      // Presentation Logic
import 'package:quiz_challenge/presentation/quiz_view.dart';            // UI
import 'package:quiz_challenge/presentation/progress_view.dart';        // UI
import 'package:quiz_challenge/application/quiz_session_store.dart';
import 'package:quiz_challenge/presentation/progress_view_model.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  MyApp({super.key});

  // Infrastructure
  final _repo = FakeQuizRepository();

  // Application
  late final _startQuiz = StartQuiz(_repo);

  // Presentation Logic
  late final _quizVM = QuizViewModel(startQuizUc: _startQuiz, store: _session);
  late final _progressVM = ProgressViewModel(_session);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quiz Challenge',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: Scaffold(
        appBar: AppBar(title: const Text('Quiz Challenge')),
        body: Column(
          children: [
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: QuizView(viewModel: _quizVM),
              ),
            ),
            const Divider(height: 1),
            Expanded(flex: 1, child: ProgressView(viewModel: _progressVM)),
          ],
        ),
      ),
    );
  }
}
