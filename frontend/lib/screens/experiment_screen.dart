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

  // Theme colors
  final Color _primaryColor = const Color.fromRGBO(124, 58, 237, 1);
  final Color _backgroundColor = const Color(0xFFF8F9FA);
  final Color _cardColor = Colors.white;
  final Color _textColor = Colors.black87;
  final Color _secondaryTextColor = Colors.black54;

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
          if (_experiment != null &&
              _completedSteps.length == _experiment!['steps'].length) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('🎉 Experiment Completed! Badge Earned.'),
                backgroundColor: _primaryColor,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
        content: const Text(
          'Are you sure you want to delete this experiment? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: _primaryColor)),
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
          SnackBar(
            content: const Text('Experiment deleted successfully.'),
            backgroundColor: _primaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
        backgroundColor: _backgroundColor,
        appBar: AppBar(
          title: Text(widget.title),
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _primaryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.science_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              CircularProgressIndicator(color: _primaryColor),
              const SizedBox(height: 16),
              Text(
                'Loading Experiment...',
                style: TextStyle(
                  fontSize: 16,
                  color: _secondaryTextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: _backgroundColor,
        appBar: AppBar(
          title: Text(widget.title),
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: _primaryColor,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Failed to Load Experiment',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _textColor,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  _error!,
                  style: TextStyle(fontSize: 14, color: _secondaryTextColor),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _initialize,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_experiment == null) {
      return Scaffold(
        backgroundColor: _backgroundColor,
        appBar: AppBar(
          title: Text(widget.title),
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('Failed to load experiment')),
      );
    }

    final isStudent = _userRole == 'student';
    final totalSteps = _experiment!['steps'].length;
    final completedCount = _completedSteps.length;
    final progress = totalSteps > 0 ? completedCount / totalSteps : 0.0;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 70,
        leadingWidth: 56,
        titleSpacing: 0,
        leading: Container(
          margin: const EdgeInsets.only(left: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Color(0xFF562866),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF562866), Color(0xFF7C3AED)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.science_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _experiment!['title'],
                    style: const TextStyle(
                      color: Color(0xFF562866),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text(
                    'Experiment Details',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (_userRole == 'teacher') ...[
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF562866).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.edit_rounded,
                  size: 20,
                  color: Color(0xFF562866),
                ),
                tooltip: 'Edit Experiment',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          EditExperimentScreen(experiment: _experiment!),
                    ),
                  );
                },
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.delete_rounded,
                  size: 20,
                  color: Colors.red.shade600,
                ),
                tooltip: 'Delete Experiment',
                onPressed: _deleteExperiment,
              ),
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail Section
              if (_experiment!['thumbnail'] != null &&
                  RegExp(
                    r'\.(jpg|jpeg|png)$',
                    caseSensitive: false,
                  ).hasMatch(_experiment!['thumbnail']))
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: CachedNetworkImage(
                      imageUrl: _experiment!['thumbnail'],
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        color: _primaryColor.withOpacity(0.1),
                        child: Center(
                          child: Icon(
                            Icons.science_rounded,
                            color: _primaryColor.withOpacity(0.5),
                            size: 60,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              // Experiment Info Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _primaryColor.withOpacity(0.1)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _experiment!['title'],
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _experiment!['description'],
                      style: TextStyle(
                        fontSize: 16,
                        color: _secondaryTextColor,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildInfoChip(
                          icon: Icons.category_rounded,
                          text: _experiment!['subject'] ?? 'Science',
                        ),
                        const SizedBox(width: 12),
                        _buildInfoChip(
                          icon: Icons.speed_rounded,
                          text: _experiment!['difficulty'] ?? 'Beginner',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Progress Section for Students
              if (isStudent && _isStarted)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _primaryColor.withOpacity(0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.trending_up_rounded,
                              color: _primaryColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Your Progress',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: _textColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.grey[200],
                          color: _primaryColor,
                          minHeight: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$completedCount/$totalSteps steps completed',
                            style: TextStyle(
                              fontSize: 14,
                              color: _secondaryTextColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${(progress * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 14,
                              color: _primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              // Start Button for Students
              if (isStudent && !_isStarted) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _startExperiment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_arrow_rounded, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Start Experiment',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Materials Section
              const SizedBox(height: 24),
              _buildSectionHeader('Materials Required', Icons.science_rounded),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _primaryColor.withOpacity(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ..._experiment!['materials'].asMap().entries.map((entry) {
                      final index = entry.key;
                      final material = entry.value;
                      return Container(
                        margin: EdgeInsets.only(
                          bottom: index == _experiment!['materials'].length - 1
                              ? 0
                              : 12,
                        ),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _backgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _primaryColor.withOpacity(0.05),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: _primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.check_circle_rounded,
                                color: _primaryColor,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                material,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: _textColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),

              // Steps Section
              const SizedBox(height: 32),
              _buildSectionHeader('Experiment Steps', Icons.list_alt_rounded),
              const SizedBox(height: 16),
              ..._experiment!['steps'].map<Widget>((step) {
                final stepNumber = step['stepNumber'];
                final isCompleted = _completedSteps.contains(stepNumber);
                final videoId = step['mediaUrl'] != null
                    ? YoutubePlayer.convertUrlToId(step['mediaUrl'])
                    : null;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: _cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isCompleted
                          ? _primaryColor
                          : _primaryColor.withOpacity(0.1),
                      width: isCompleted ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Step Header
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? _primaryColor.withOpacity(0.05)
                              : Colors.transparent,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isCompleted
                                    ? _primaryColor
                                    : Colors.grey[300],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  '$stepNumber',
                                  style: TextStyle(
                                    color: isCompleted
                                        ? Colors.white
                                        : _textColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                step['instruction'],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: _textColor,
                                  height: 1.4,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: _isSpeaking
                                    ? _primaryColor.withOpacity(0.1)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  _isSpeaking
                                      ? Icons.stop_rounded
                                      : Icons.volume_up_rounded,
                                  color: _primaryColor,
                                  size: 20,
                                ),
                                onPressed: () =>
                                    _speakStep(step['instruction']),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Video Section
                      if (step['mediaUrl'] != null && videoId != null)
                        Container(
                          height: 200,
                          margin: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: YoutubePlayer(
                              controller: _videoControllers[stepNumber]!,
                              showVideoProgressIndicator: true,
                              progressIndicatorColor: _primaryColor,
                              progressColors: ProgressBarColors(
                                playedColor: _primaryColor,
                                handleColor: _primaryColor,
                                bufferedColor: _primaryColor.withOpacity(0.3),
                              ),
                            ),
                          ),
                        )
                      else if (step['mediaUrl'] != null)
                        Container(
                          height: 120,
                          margin: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: _primaryColor.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _primaryColor.withOpacity(0.1),
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.videocam_off_rounded,
                                  color: _primaryColor.withOpacity(0.5),
                                  size: 40,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Video Not Available',
                                  style: TextStyle(
                                    color: _secondaryTextColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Action Button for Students
                      if (isStudent && _isStarted && !isCompleted)
                        Container(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => _markStepCompleted(stepNumber),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_rounded, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Mark as Completed',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else if (isStudent && isCompleted)
                        Container(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                color: _primaryColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Completed',
                                style: TextStyle(
                                  color: _primaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),

              const SizedBox(height: 20),
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

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: _primaryColor),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: _primaryColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
