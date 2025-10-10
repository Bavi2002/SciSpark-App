import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:frontend/components/ai_assistant/ai_assistant_button.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/screens/edit_experiment_screen.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

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
  String? _userRole;
  FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;
  Map<int, YoutubePlayerController> _videoControllers = {};

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    if (!mounted) return;
    debugPrint('Initializing ExperimentDetailScreen');
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _fetchUserRole(),
        _fetchExperiment(),
        _checkProgress(),
      ]);
    } catch (e) {
      debugPrint('Initialize error: $e');
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchUserRole() async {
    final role = await AuthService.getRole();
    if (mounted) {
      setState(() => _userRole = role);
    }
  }

  Future<void> _fetchExperiment() async {
    debugPrint('Fetching experiment: ${widget.experimentId}');
    final response = await ApiService.getExperimentById(widget.experimentId);
    if (mounted) {
      setState(() {
        _experiment = response;
        for (var step in _experiment!['steps']) {
          if (step['mediaUrl'] != null) {
            final videoId = YoutubePlayer.convertUrlToId(step['mediaUrl']);
            if (videoId != null) {
              _videoControllers[step['stepNumber']] = YoutubePlayerController(
                initialVideoId: videoId,
                flags: const YoutubePlayerFlags(
                  autoPlay: false,
                  mute: false,
                  disableDragSeek: false,
                  loop: false,
                  enableCaption: false,
                ),
              );
            }
          }
        }
      });
    }
  }

  Future<void> _checkProgress() async {
    final role = _userRole ?? await AuthService.getRole();
    if (role != 'student') return;

    debugPrint('Checking progress for experiment: ${widget.experimentId}');
    final progressList = await ApiService.getStudentProgress();
    final progress = progressList.firstWhere(
      (p) => p['experimentId']['_id'] == widget.experimentId,
      orElse: () => null,
    );
    if (progress != null && mounted) {
      setState(() {
        _isStarted = true;
        _completedSteps = List<int>.from(progress['completedSteps']);
      });
    }
  }

  Future<void> _startExperiment() async {
    if (!mounted) return;
    debugPrint('Starting experiment: ${widget.experimentId}');
    setState(() => _isLoading = true);
    try {
      await ApiService.startExperiment(widget.experimentId);
      if (mounted) {
        setState(() {
          _isStarted = true;
          _error = null;
        });
      }
    } catch (e) {
      debugPrint('Start experiment error: $e');
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _markStepCompleted(int stepNumber) async {
    if (!mounted) return;
    debugPrint('Marking step $stepNumber completed');
    setState(() => _isLoading = true);
    try {
      await ApiService.markStepCompleted(widget.experimentId, stepNumber);
      if (mounted) {
        setState(() {
          if (!_completedSteps.contains(stepNumber)) {
            _completedSteps.add(stepNumber);
          }
          if (_experiment != null && _completedSteps.length == _experiment!['steps'].length) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Experiment Completed! Badge Earned.'),
                backgroundColor: Colors.green,
              ),
            );
          }
          _error = null;
        });
      }
    } catch (e) {
      debugPrint('Mark step completed error: $e');
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteExperiment() async {
    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Experiment'),
        content: const Text('Are you sure you want to delete this experiment? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    debugPrint('Deleting experiment: ${widget.experimentId}');
    setState(() => _isLoading = true);
    try {
      await ApiService.deleteExperiment(widget.experimentId);
      if (mounted) {
        Navigator.pop(context); // Return to ExperimentListScreen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Experiment deleted successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Delete experiment error: $e');
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _speakStep(String text) async {
    if (!mounted) return;
    debugPrint('Speaking step: $text');
    if (_isSpeaking) {
      await _tts.stop();
      if (mounted) {
        setState(() => _isSpeaking = false);
      }
    } else {
      await _tts.speak(text);
      if (mounted) {
        setState(() => _isSpeaking = true);
      }
      _tts.setCompletionHandler(() {
        debugPrint('TTS completed');
        if (mounted) {
          setState(() => _isSpeaking = false);
        }
      });
    }
  }

  Map<String, dynamic>? get currentStep {
    if (_experiment == null || _experiment!['steps'] == null) return null;
    for (var step in _experiment!['steps']) {
      if (!_completedSteps.contains(step['stepNumber'])) {
        return step;
      }
    }
    return _experiment!['steps'].isNotEmpty ? _experiment!['steps'].last : null;
  }

  @override
  void dispose() {
    debugPrint('Disposing ExperimentDetailScreen');
    _tts.stop();
    _videoControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('Building ExperimentDetailScreen');
    if (_isLoading || _userRole == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red))),
      );
    }

    if (_experiment == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(child: Text('Failed to load experiment')),
      );
    }

    final isStudent = _userRole == 'student';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(_experiment!['title']),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          if (_userRole == 'teacher') ...[
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit Experiment',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditExperimentScreen(experiment: _experiment!),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'Delete Experiment',
              onPressed: _deleteExperiment,
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_experiment!['thumbnail'] != null &&
                  RegExp(r'\.(jpg|jpeg|png)$', caseSensitive: false).hasMatch(_experiment!['thumbnail']))
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: _experiment!['thumbnail'],
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Container(
                      height: 200,
                      color: Colors.grey[200],
                      child: const Center(
                        child: Text(
                          'Failed to load thumbnail',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
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
              const Text('Materials:', style: TextStyle(fontWeight: FontWeight.bold)),
              ..._experiment!['materials'].map<Widget>((mat) => Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text('- $mat'),
                  )).toList(),
              const SizedBox(height: 16),
              if (isStudent && !_isStarted)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _startExperiment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Start Experiment',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              const Text('Steps:', style: TextStyle(fontWeight: FontWeight.bold)),
              ..._experiment!['steps'].map<Widget>((step) {
                final stepNumber = step['stepNumber'];
                final isCompleted = _completedSteps.contains(stepNumber);
                final videoId = step['mediaUrl'] != null ? YoutubePlayer.convertUrlToId(step['mediaUrl']) : null;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Step $stepNumber: ${step['instruction']}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                _isSpeaking ? Icons.stop : Icons.volume_up,
                                color: Colors.grey[600],
                              ),
                              onPressed: () => _speakStep(step['instruction']),
                            ),
                          ],
                        ),
                        if (step['mediaUrl'] != null && videoId != null)
                          Container(
                            height: 200,
                            margin: const EdgeInsets.only(top: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: YoutubePlayer(
                                controller: _videoControllers[stepNumber]!,
                                showVideoProgressIndicator: true,
                                progressIndicatorColor: Colors.black,
                                progressColors: const ProgressBarColors(
                                  playedColor: Colors.black,
                                  handleColor: Colors.black45,
                                ),
                              ),
                            ),
                          )
                        else if (step['mediaUrl'] != null)
                          Container(
                            height: 200,
                            margin: const EdgeInsets.only(top: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Icon(Icons.videocam_off, color: Colors.grey, size: 48),
                            ),
                          ),
                        if (isStudent && _isStarted && !isCompleted)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => _markStepCompleted(stepNumber),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Mark as Completed',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                            ),
                          )
                        else if (isStudent && isCompleted)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              'Completed',
                              style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(_error!, style: const TextStyle(color: Colors.red)),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: currentStep != null
          ? AIAssistantButton(
              experimentId: widget.experimentId,
              currentStepContext: 'Step ${currentStep!['stepNumber']}: ${currentStep!['instruction']}',
            )
          : null,
    );
  }
}