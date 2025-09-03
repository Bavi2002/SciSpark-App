class Experiment {
  final String id;
  final String user;
  final String title;
  final String description;
  final String subject;
  final String difficulty;
  final List<String> materials;
  final List<Step> steps;
  final DateTime createdAt;

  Experiment({
    required this.id,
    required this.user,
    required this.title,
    required this.description,
    required this.subject,
    required this.difficulty,
    required this.materials,
    required this.steps,
    required this.createdAt,
  });

  factory Experiment.fromJson(Map<String, dynamic> json) {
    return Experiment(
      id: json['_id'].toString(),
      user: json['user'].toString(),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      subject: json['subject'] ?? '',
      difficulty: json['difficulty'] ?? '',
      materials: List<String>.from(json['materials'] ?? []),
      steps: (json['steps'] as List<dynamic>?)
              ?.map((step) => Step.fromJson(step as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'user': user,
      'title': title,
      'description': description,
      'subject': subject,
      'difficulty': difficulty,
      'materials': materials,
      'steps': steps.map((step) => step.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class Step {
  final int stepNumber;
  final String instruction;
  final String? mediaUrl;

  Step({
    required this.stepNumber,
    required this.instruction,
    this.mediaUrl,
  });

  factory Step.fromJson(Map<String, dynamic> json) {
    return Step(
      stepNumber: json['stepNumber'] ?? 0,
      instruction: json['instruction'] ?? '',
      mediaUrl: json['mediaUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stepNumber': stepNumber,
      'instruction': instruction,
      'mediaUrl': mediaUrl,
    };
  }
}