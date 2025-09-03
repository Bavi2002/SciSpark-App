import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:frontend/components/ai_assistant/ai_assistant_button.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:video_player/video_player.dart';

class ExperimentDetailScreen extends StatefulWidget {
  final String experimentId;
  final String title;

  const ExperimentDetailScreen({
    required this.experimentId,
    required this.title,
    super.key,
  });

  @override
  _ExperimentDetailScreenState createState() => _ExperimentDetailScreenState();
}

class _ExperimentDetailScreenState extends State<ExperimentDetailScreen> {
  Map<String, dynamic>? _experiment;
  List<int> _completedSteps = [];
  bool _isStarted = false;
  bool _isLoading = true;
  String? _error;
  FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;
  Map<int, ChewieController> _videoControllers = {};

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([_fetchExperiment(), _checkProgress()]);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchExperiment() async {
    final response = await ApiService.getExperimentById(widget.experimentId);
    setState(() {
      _experiment = response;
      // Initialize video controllers for steps with videoUrl
      for (var step in _experiment!['steps']) {
        if (step['mediaUrl'] != null && step['mediaUrl'].endsWith('.mp4')) {
          final controller = VideoPlayerController.network(step['mediaUrl']);
          _videoControllers[step['stepNumber']] = ChewieController(
            videoPlayerController: controller,
            autoPlay: false,
            looping: false,
            errorBuilder: (context, errorMessage) =>
                Center(child: Text('Video error: $errorMessage')),
          );
        }
      }
    });
  }

  Future<void> _checkProgress() async {
    final role = await AuthService.getRole();
    if (role != 'student') return; // Progress is only for students

    final progressList = await ApiService.getStudentProgress();
    final progress = progressList.firstWhere(
      (p) => p['experimentId']['_id'] == widget.experimentId,
      orElse: () => null,
    );
    if (progress != null) {
      setState(() {
        _isStarted = true;
        _completedSteps = List<int>.from(progress['completedSteps']);
      });
    }
  }

  Future<void> _startExperiment() async {
    setState(() => _isLoading = true);
    try {
      await ApiService.startExperiment(widget.experimentId);
      setState(() {
        _isStarted = true;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markStepCompleted(int stepNumber) async {
    setState(() => _isLoading = true);
    try {
      await ApiService.markStepCompleted(widget.experimentId, stepNumber);
      setState(() {
        if (!_completedSteps.contains(stepNumber)) {
          _completedSteps.add(stepNumber);
        }
        if (_experiment != null &&
            _completedSteps.length == _experiment!['steps'].length) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Experiment Completed! Badge Earned.'),
              backgroundColor: Colors.green,
            ),
          );
        }
        _error = null;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _speakStep(String text) async {
    if (_isSpeaking) {
      await _tts.stop();
      setState(() => _isSpeaking = false);
    } else {
      await _tts.speak(text);
      setState(() => _isSpeaking = true);
      _tts.setCompletionHandler(() {
        setState(() => _isSpeaking = false);
      });
    }
  }

  Map<String, dynamic>? get currentStep {
    if (_experiment == null || _experiment!['steps'] == null) return null;
    // Find the first incomplete step, or the first step if all are completed
    for (var step in _experiment!['steps']) {
      if (!_completedSteps.contains(step['stepNumber'])) {
        return step;
      }
    }
    // If all steps completed, return the last step
    return _experiment!['steps'].isNotEmpty ? _experiment!['steps'].last : null;
  }

  @override
  void dispose() {
    _tts.stop();
    _videoControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Center(
          child: Text(
            'Error: $_error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    if (_experiment == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(child: Text('Failed to load experiment')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(_experiment!['title']),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _experiment!['description'],
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Subject: ${_experiment!['subject']} | Difficulty: ${_experiment!['difficulty']}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              const Text(
                'Materials:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ..._experiment!['materials']
                  .map<Widget>(
                    (mat) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text('- $mat'),
                    ),
                  )
                  .toList(),
              const SizedBox(height: 16),
              FutureBuilder<String?>(
                future: AuthService.getRole(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.data != 'student') {
                    return const SizedBox.shrink(); // Hide start button for non-students
                  }
                  return !_isStarted
                      ? SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _startExperiment,
                            child: const Text('Start Experiment'),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Steps:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            ..._experiment!['steps'].map<Widget>((step) {
                              final stepNumber = step['stepNumber'];
                              final isCompleted = _completedSteps.contains(
                                stepNumber,
                              );
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'Step $stepNumber: ${step['instruction']}',
                                              style: const TextStyle(
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              _isSpeaking
                                                  ? Icons.stop
                                                  : Icons.volume_up,
                                              color: Colors.grey[600],
                                            ),
                                            onPressed: () =>
                                                _speakStep(step['instruction']),
                                          ),
                                        ],
                                      ),
                                      if (step['mediaUrl'] != null)
                                        step['mediaUrl'].endsWith('.mp4')
                                            ? Container(
                                                height: 200,
                                                margin: const EdgeInsets.only(
                                                  top: 8,
                                                ),
                                                child: Chewie(
                                                  controller:
                                                      _videoControllers[stepNumber]!,
                                                ),
                                              )
                                            : CachedNetworkImage(
                                                imageUrl: step['mediaUrl'],
                                                height: 200,
                                                fit: BoxFit.cover,
                                                errorWidget:
                                                    (context, url, error) =>
                                                        const Icon(Icons.error),
                                              ),
                                      if (!isCompleted)
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            onPressed: () =>
                                                _markStepCompleted(stepNumber),
                                            child: const Text(
                                              'Mark as Completed',
                                            ),
                                          ),
                                        )
                                      else
                                        const Padding(
                                          padding: EdgeInsets.only(top: 8),
                                          child: Text(
                                            'Completed',
                                            style: TextStyle(
                                              color: Colors.green,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                        );
                },
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: currentStep != null
          ? AIAssistantButton(
              experimentId: widget.experimentId,
              currentStepContext:
                  'Step ${currentStep!['stepNumber']}: ${currentStep!['instruction']}',
            )
          : null,
    );
  }
}
