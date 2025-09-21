// quiz_view.dart
// Reine Darstellung. Lauscht auf VM (AnimatedBuilder). Kein HTTP/Infra hier.
import 'package:flutter/material.dart';
import 'quiz_view_model.dart';

class QuizView extends StatefulWidget {
  final QuizViewModel viewModel;
  const QuizView({super.key, required this.viewModel});

  @override
  State<QuizView> createState() => _QuizViewState();
}

class _QuizViewState extends State<QuizView> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.startQuiz(); // Start im Lifecycle
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.viewModel,
      builder: (_, __) {
        final vm = widget.viewModel;

        if (vm.state == QuizState.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (vm.state == QuizState.finished) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Quiz Finished! Your Score: ${vm.score}"),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: vm.retry, child: const Text("Retry")),
            ],
          );
        }
        if (vm.state == QuizState.question && vm.currentQuestion != null) {
          final q = vm.currentQuestion!;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(q.text, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 20),
              ...q.options.map((o) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: ElevatedButton(
                  onPressed: () => vm.answerQuestion(o),
                  child: Text(o),
                ),
              )),
            ],
          );
        }
        // idle + optionaler Fehlerpfad
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (vm.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Fehler beim Laden',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ElevatedButton(onPressed: vm.startQuiz, child: const Text("Start Quiz")),
          ],
        );
      },
    );
  }
}
