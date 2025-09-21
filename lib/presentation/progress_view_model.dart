import 'package:flutter/foundation.dart';
import 'package:quiz_challenge/application/quiz_session_store.dart';

class ProgressViewModel {
  final QuizSessionStore store;
  ProgressViewModel(this.store);

  ValueListenable<Progress> get progress => store.progress;   
}
