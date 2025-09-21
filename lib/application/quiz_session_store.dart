import 'package:flutter/foundation.dart';

class Progress {
  final int current, total, score;
  const Progress({required this.current, required this.total, required this.score});
  double get fraction => total == 0 ? 0 : current / total;
  static const zero = Progress(current: 0, total: 0, score: 0);
}

class QuizSessionStore {
  final ValueNotifier<Progress> progress = ValueNotifier(Progress.zero);

  void reset({required int total}) {
    progress.value = Progress(current: 0, total: total, score: 0);
  }

  void advance({required bool correct}) {
    final p = progress.value;
    if (p.current >= p.total) return;                  // Clamp: nie über das Ende hinaus
    progress.value = Progress(
      current: p.current + 1,
      total: p.total,
      score: p.score + (correct ? 1 : 0),
    );
  }

  void dispose() => progress.dispose();
}
