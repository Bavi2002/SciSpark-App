import 'package:flutter/material.dart';

class ProgressProvider with ChangeNotifier {
  // Map of experimentId to list of completed step indices
  Map<String, List<int>> _completedSteps = {};

  Map<String, List<int>> get completedSteps => _completedSteps;

  void toggleStepCompletion(String experimentId, int stepIndex) {
    if (!_completedSteps.containsKey(experimentId)) {
      _completedSteps[experimentId] = [];
    }
    if (_completedSteps[experimentId]!.contains(stepIndex)) {
      _completedSteps[experimentId]!.remove(stepIndex);
    } else {
      _completedSteps[experimentId]!.add(stepIndex);
    }
    notifyListeners();
  }

  bool isStepCompleted(String experimentId, int stepIndex) {
    return _completedSteps[experimentId]?.contains(stepIndex) ?? false;
  }

  bool isExperimentCompleted(String experimentId, int totalSteps) {
    return _completedSteps[experimentId]?.length == totalSteps;
  }

  void clearProgress() {
    _completedSteps.clear();
    notifyListeners();
  }
}