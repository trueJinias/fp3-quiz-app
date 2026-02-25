class Question {
  final int id;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final String? imagePath;

  Question({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    this.imagePath,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as int,
      question: json['question'] as String,
      options: (json['options'] as List<dynamic>).map((e) => e as String).toList(),
      correctIndex: json['correctIndex'] as int,
      explanation: json['explanation'] as String,
      imagePath: json['imagePath'] as String?,
    );
  }
}
