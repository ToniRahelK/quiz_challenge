// domain
// Domain-Entity, framework-frei. Fachlogik gehört hierher (SoC).
class Question {
  final String text;
  final List<String> options;
  final String correctAnswer;

  Question({
    required this.text,
    required this.options,
    required this.correctAnswer,
  });
  
  // Die Fachlogik liegt in der Domain, nicht in UI oder ViewModel.
  bool isCorrect(String answer) => answer == correctAnswer;
}

