// progress_view.dart
import 'package:flutter/material.dart';
import 'package:quiz_challenge/presentation/progress_view_model.dart';
import 'package:quiz_challenge/application/quiz_session_store.dart';

class ProgressView extends StatelessWidget {
  final ProgressViewModel viewModel;
  const ProgressView({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Progress>(
      valueListenable: viewModel.progress,
      builder: (_, p, __) {
        final shown = p.total == 0 ? 0 : (p.current < p.total ? p.current + 1 : p.total);
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Frage $shown von ${p.total}'),
            const SizedBox(height: 8),
            SizedBox(width: 220, child: LinearProgressIndicator(value: p.fraction)),
            const SizedBox(height: 8),
            Text('Score: ${p.score}'),
          ],
        );
      },
    );
  }
}
