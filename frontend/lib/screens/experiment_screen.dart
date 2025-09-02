import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:frontend/services/api_service.dart';
import 'package:video_player/video_player.dart';

class ExperimentDetailScreen extends StatefulWidget {
  final String experimentId;
  final String title;

  ExperimentDetailScreen({required this.experimentId, required this.title});

  @override
  _ExperimentDetailScreenState createState() => _ExperimentDetailScreenState();
}

class _ExperimentDetailScreenState extends State<ExperimentDetailScreen> {
  Map<String, dynamic>? _experiment;
  List<int> _completedSteps = [];
  bool _isStarted = false;
  FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _fetchExperiment();
    _checkProgress();
  }

  Future<void> _fetchExperiment() async {
    final response = await ApiService.request('/api/experiments/${widget.experimentId}', 'GET');
    print('Fetching experiment data... ${response.body}');
    if (response.statusCode == 200) {
      setState(() {
        _experiment = jsonDecode(response.body);
      });
    }
  }

  Future<void> _checkProgress() async {
    final progressResponse = await ApiService.request('/api/student/progress', 'GET');
    if (progressResponse.statusCode == 200) {
      final progressList = jsonDecode(progressResponse.body) as List;
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
  }

  Future<void> _startExperiment() async {
    final response = await ApiService.request('/api/student/progress/start', 'POST', body: {'experimentId': widget.experimentId});
    if (response.statusCode == 200) {
      setState(() {
        _isStarted = true;
      });
    }
  }

  Future<void> _markStepCompleted(int stepNumber) async {
    final response = await ApiService.request('/api/student/progress/step', 'POST', body: {'experimentId': widget.experimentId, 'stepNumber': stepNumber});
    if (response.statusCode == 200) {
      setState(() {
        if (!_completedSteps.contains(stepNumber)) {
          _completedSteps.add(stepNumber);
        }
        if (_completedSteps.length == _experiment!['steps'].length) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Experiment Completed! Badge Earned.')));
        }
      });
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

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_experiment == null) {
      return Scaffold(appBar: AppBar(title: Text(widget.title)), body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text(_experiment!['title'])),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_experiment!['description'], style: TextStyle(fontSize: 16)),
              SizedBox(height: 8),
              Text('Subject: ${_experiment!['subject']} | Difficulty: ${_experiment!['difficulty']}'),
              SizedBox(height: 16),
              Text('Materials:', style: TextStyle(fontWeight: FontWeight.bold)),
              ..._experiment!['materials'].map((mat) => Text('- $mat')).toList(),
              SizedBox(height: 16),
              if (!_isStarted)
                ElevatedButton(onPressed: _startExperiment, child: Text('Start Experiment'))
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Steps:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...List.generate(_experiment!['steps'].length, (index) {
                      final step = _experiment!['steps'][index];
                      final stepNumber = index + 1;
                      final isCompleted = _completedSteps.contains(stepNumber);
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(child: Text('Step $stepNumber: ${step['instruction']}')),
                                  IconButton(
                                    icon: Icon(_isSpeaking ? Icons.stop : Icons.volume_up),
                                    onPressed: () => _speakStep(step['instruction']),
                                  ),
                                ],
                              ),
                              if (step['imageUrl'] != null)
                                CachedNetworkImage(imageUrl: step['imageUrl'], height: 200, fit: BoxFit.cover),
                              if (step['videoUrl'] != null)
                                Chewie(
                                  controller: ChewieController(
                                    videoPlayerController: VideoPlayerController.network(step['videoUrl']),
                                    autoPlay: false,
                                    looping: false,
                                  ),
                                ),
                              if (!isCompleted)
                                ElevatedButton(
                                  onPressed: () => _markStepCompleted(stepNumber),
                                  child: Text('Mark as Completed'),
                                )
                              else
                                Text('Completed', style: TextStyle(color: Colors.green)),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}