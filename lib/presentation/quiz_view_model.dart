// MVVM: hält UI-State, orchestriert Use-Cases. Keine Infrastruktur-Imports.
import 'dart:async';                     // wegen Future<void>
import 'package:flutter/foundation.dart';
import 'package:quiz_challenge/domain/question.dart';
import 'package:quiz_challenge/application/start_quiz.dart';
import 'package:quiz_challenge/application/quiz_session_store.dart';        // Single Source of Truth für Fortschritt

enum QuizState { initial, loading, question, finished }

class QuizViewModel extends ChangeNotifier {
  final StartQuiz startQuizUc;
  final QuizSessionStore store;          // geteilter Fortschritts-Store (Application-Schicht)

  QuizViewModel({required this.startQuizUc, required this.store});

  // Interner UI-State (nur Fragen & FSM-Zustand bleiben hier)
  List<Question> _questions = const [];
  QuizState _state = QuizState.initial;
  Object? _error;

  // ---- Read-only API für die View ----
  QuizState get state => _state;
  Object? get error => _error;

  // Fortschritt kommt ausschließlich aus dem Store (Single Source of Truth)
  int get currentIndex => store.progress.value.current;
  int get totalQuestions => store.progress.value.total;
  int get score => store.progress.value.score;

  // Kohärenz: currentQuestion wird aus currentIndex abgeleitet.
  Question? get currentQuestion =>
      (currentIndex < _questions.length) ? _questions[currentIndex] : null;

  // Startet das Quiz:
  // - Reentrancy-Guard: zweiter Aufruf während loading hat keine Wirkung
  // - Fehlerpfad: error setzen, zurück in stabilen Zustand (idle)
  // - Leere Liste: sofort finished (keine Null-UI in 'question')
  Future<void> startQuiz() async {
    if (_state == QuizState.loading) return;        // Guard: doppelte Starts verhindern
    _setState(QuizState.loading);
    _error = null;                                   // vorherigen Fehler zurücksetzen

    try {
      _questions = await startQuizUc();              // Use-Case statt Repo direkt
      store.reset(total: _questions.length);         // Fortschritt im Store setzen

      if (_questions.isEmpty) {                      // Edge Case: keine Fragen
        _setState(QuizState.finished);               // klare FSM, keine Null-UI
        return;
      }

      _setState(QuizState.question);
    } catch (e) {
      _error = e;                                    // Fehler merken
      _setState(QuizState.initial);                     // zurück in stabilen Zustand (oder eigener error-State)
      // WICHTIG: Store NICHT anfassen -> bleibt 0/0/0
    }
  }

  // Antwortet auf die aktuelle Frage:
  // - Nur im Zustand 'question' aktiv (No-Op-Guards)
  // - Scoring über Domain-Regel (Question.isCorrect)
  // - Fortschritt ausschließlich über den Store fortschreiben
  // - Zustand anhand des Fortschritts umschalten (question -> finished)
  void answerQuestion(String answer) {
    if (_state != QuizState.question) return;        // Guard: nur im Frage-Modus
    final q = currentQuestion;
    if (q == null) return;                           // Guard: z. B. leere Liste

    final correct = q.isCorrect(answer);             // Fachregel in Domain
    store.advance(correct: correct);                 // Fortschritt im Store erhöhen
    // HINWEIS: Der Store sollte intern "clampen" (current nicht > total).
    // Siehe QuizSessionStore.advance(): if (p.current >= p.total) return;

    // Zustand aktualisieren: bei letzter Frage -> finished
    _setState(
      currentIndex >= _questions.length
        ? QuizState.finished
        : QuizState.question,
    );
  }

  // Neustart:
  // - Setzt lokalen Fehler/Fagenliste zurück
  // - Lädt erneut über startQuiz()
  Future<void> retry() async {
    _questions = const [];
    _error = null;
    await startQuiz();
  }

  // --- intern: einheitliches State-Set + Benachrichtigung ---
  void _setState(QuizState s) {
    _state = s;
    notifyListeners();                               // Views reagieren via AnimatedBuilder/Listenables
  }
}
