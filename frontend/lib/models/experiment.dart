class ExperimentStep {
  final int stepNumber;
  final String instruction;
  final String? mediaUrl;

  ExperimentStep({required this.stepNumber, required this.instruction, this.mediaUrl});

  factory ExperimentStep.fromJson(Map<String, dynamic> json) {
    return ExperimentStep(
      stepNumber: json['stepNumber'],
      instruction: json['instruction'],
      mediaUrl: json['mediaUrl'],
    );
  }
}

class Experiment {
  final String id;
  final String title;
  final String description;
  final String subject;
  final String difficulty;
  final List<String> materials;
  final List<ExperimentStep> steps;

  Experiment({
    required this.id,
    required this.title,
    required this.description,
    required this.subject,
    required this.difficulty,
    required this.materials,
    required this.steps,
  });

  factory Experiment.fromJson(Map<String, dynamic> json) {
    return Experiment(
      id: json['_id'],
      title: json['title'],
      description: json['description'],
      subject: json['subject'],
      difficulty: json['difficulty'],
      materials: List<String>.from(json['materials']),
      steps: (json['steps'] as List).map((step) => ExperimentStep.fromJson(step)).toList(),
    );
  }
}