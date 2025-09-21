


// Voraussetzungen im Produktionscode:
// - enum QuizState { initial, loading, question, finished }
// - QuizViewModel nutzt StartQuiz (Use-Case) + QuizSessionStore (Application-Store)
// - Domain-Entity Question mit isCorrect(answer)

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_challenge/domain/question.dart';
import 'package:quiz_challenge/domain/quiz_repository.dart';// Interface für das Testeigene Fake repo
import 'package:quiz_challenge/application/start_quiz.dart';
import 'package:quiz_challenge/application/quiz_session_store.dart';
import 'package:quiz_challenge/presentation/quiz_view_model.dart';


// Fake-Repo: liefert eine vordefinierte Liste oder wirft gezielt.
class TestQuizRepository implements QuizRepository {
  final Future<List<Question>> Function() _impl;
  TestQuizRepository(this._impl);

  @override
  Future<List<Question>> fetchQuestions() => _impl();
}

// Testdaten
List<Question> sampleQuestions() => [
  Question(text: '2+2?', options: ['3', '4'], correctAnswer: '4'),
  Question(text: 'Capital?', options: ['Paris', 'Berlin'], correctAnswer: 'Paris'),
];

// Progress-Prüfung
void expectProgress(
  QuizSessionStore store, {
  required int current,
  required int total,
  required int score,
}) {
  final p = store.progress.value;
  expect(p.current, current);
  expect(p.total, total);
  expect(p.score, score);
}

void main() {
  group('QuizViewModel (FSM & Progress über Application-Store)', () {
    late QuizSessionStore store;

    setUp(() {
      // Neuer Store vor jedem Test (keine Seiteneffekte zwischen Tests)!!!!
      store = QuizSessionStore();
    });

    tearDown(() {
      store.dispose();
    });

    test('Start: initial → loading → question, Store reset, erste Frage sichtbar', () async {
      // Arrange
      final repo = TestQuizRepository(() async => sampleQuestions());
      final vm = QuizViewModel(startQuizUc: StartQuiz(repo), store: store);

      // Assert Ausgangszustand
      expect(vm.state, QuizState.initial);
      expectProgress(store, current: 0, total: 0, score: 0);

      // Act + Assert Übergang zu loading
      final f = vm.startQuiz();
      expect(vm.state, QuizState.loading);

      // Assert nach Abschluss: question + Progress reset
      await f;
      expect(vm.state, QuizState.question);
      expectProgress(store, current: 0, total: 2, score: 0);

      // Erste Frage kohärent zum Index 0
      expect(vm.currentQuestion!.text, '2+2?');
    });

    test('Antworten: korrekt erhöht Score, beide erhöhen current; nach letzter Antwort finished', () async {
      final vm = QuizViewModel(
        startQuizUc: StartQuiz(TestQuizRepository(() async => sampleQuestions())),
        store: store,
      );

      await vm.startQuiz(); 

      // 1) Korrekte Antwort → score +1, current +1
      vm.answerQuestion('4');
      expectProgress(store, current: 1, total: 2, score: 1);
      expect(vm.state, QuizState.question);
      expect(vm.currentQuestion!.text, 'Capital?'); // zweite Frage bei Index 1

      // 2) Falsche Antwort → score unverändert, current +1 → finished
      vm.answerQuestion('Berlin');
      expectProgress(store, current: 2, total: 2, score: 1);
      expect(vm.state, QuizState.finished);

      // Keine aktuelle Frage mehr
      expect(vm.currentQuestion, isNull);
    });

    test('Retry: setzt Fortschritt zurück und lädt neu', () async {
      final vm = QuizViewModel(
        startQuizUc: StartQuiz(TestQuizRepository(() async => sampleQuestions())),
        store: store,
      );

      await vm.startQuiz();
      vm.answerQuestion('4'); // eine richtig
      expectProgress(store, current: 1, total: 2, score: 1);

      await vm.retry();

      // Nach retry: wieder geladen, question-State, Fortschritt zurückgesetzt
      expect(vm.state, QuizState.question);
      expectProgress(store, current: 0, total: 2, score: 0);
      expect(vm.currentQuestion, isNotNull);
    });

    test('Loading-Guard: zweiter startQuiz-Aufruf während loading hat keine Nebenwirkung', () async {
      // Arrange: Use-Case liefert erst, wenn completer erfüllt wird
      final completer = Completer<List<Question>>();
      final repo = TestQuizRepository(() => completer.future);
      final vm = QuizViewModel(startQuizUc: StartQuiz(repo), store: store);

      // 1. Start → loading
      final f1 = vm.startQuiz();
      expect(vm.state, QuizState.loading);

      // 2. Start während loading → darf nichts tun / nicht crashen
      final f2 = vm.startQuiz();
      expect(vm.state, QuizState.loading);
      await f2; // sollte sauber zurückkehren

      // Ladevorgang beenden
      completer.complete(sampleQuestions());
      await f1;

      // Ergebnis: normaler Übergang nach question, Progress reset
      expect(vm.state, QuizState.question);
      expectProgress(store, current: 0, total: 2, score: 0);
    });

    test('Fehlerpfad: StartQuiz wirft -> error gesetzt, zurück zu initial, Store unverändert', () async {
      final err = Exception('boom');
      final repo = TestQuizRepository(() async => throw err);
      final vm = QuizViewModel(startQuizUc: StartQuiz(repo), store: store);

      await vm.startQuiz();

      expect(vm.error, isNotNull);
      expect(vm.state, QuizState.initial);         // oder: dein definierter error-State
      expectProgress(store, current: 0, total: 0, score: 0);
    });

    test('Leere Liste: sofort finished (0/0/0), keine aktuelle Frage', () async {
      final repo = TestQuizRepository(() async => const <Question>[]);
      final vm = QuizViewModel(startQuizUc: StartQuiz(repo), store: store);

      await vm.startQuiz();

      expect(vm.state, QuizState.finished);        // Design-Entscheidung Option A
      expectProgress(store, current: 0, total: 0, score: 0);
      expect(vm.currentQuestion, isNull);

      // No-Op: Antworten im finished-State haben keine Wirkung
      vm.answerQuestion('egal');
      expect(vm.state, QuizState.finished);
      expectProgress(store, current: 0, total: 0, score: 0);
    });

    test('No-Op: answerQuestion() in initial/loading hat keine Wirkung', () async {
      // initial
      final vm = QuizViewModel(
        startQuizUc: StartQuiz(TestQuizRepository(() async => sampleQuestions())),
        store: store,
      );
      vm.answerQuestion('egal');
      expect(vm.state, QuizState.initial);
      expectProgress(store, current: 0, total: 0, score: 0);

      // loading
      final completer = Completer<List<Question>>();
      final vm2 = QuizViewModel(
        startQuizUc: StartQuiz(TestQuizRepository(() => completer.future)),
        store: QuizSessionStore(), // frischer Store
      );
      vm2.startQuiz(); // -> loading
      expect(vm2.state, QuizState.loading);
      vm2.answerQuestion('egal'); // No-Op im loading
      expect(vm2.state, QuizState.loading);
      completer.complete(sampleQuestions());
      await Future.microtask(() {}); // event loop tick
    });

    test('Kohärenz: currentQuestion passt immer zum current-Index im Store', () async {
      final vm = QuizViewModel(
        startQuizUc: StartQuiz(TestQuizRepository(() async => sampleQuestions())),
        store: store,
      );
      await vm.startQuiz();

      // Index 0 → erste Frage
      expect(vm.currentIndex, 0);
      expect(vm.currentQuestion!.text, '2+2?');

      // Eine Antwort → Index 1 → zweite Frage
      vm.answerQuestion('4');
      expect(vm.currentIndex, 1);
      expect(vm.currentQuestion!.text, 'Capital?');

      // Noch eine Antwort → current == total → keine Frage mehr
      vm.answerQuestion('Paris');
      expect(vm.currentIndex, 2);
      expect(vm.currentQuestion, isNull);
    });
  });
}
