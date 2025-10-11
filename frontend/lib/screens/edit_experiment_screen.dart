import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/openai_service.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class EditExperimentScreen extends StatefulWidget {
  final Map<String, dynamic> experiment;

  const EditExperimentScreen({required this.experiment, super.key});

  @override
  _EditExperimentScreenState createState() => _EditExperimentScreenState();
}

class _EditExperimentScreenState extends State<EditExperimentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _materialsController = TextEditingController();
  final _stepInstructionController = TextEditingController();
  final _stepMediaUrlController = TextEditingController();
  String? _selectedSubject;
  String? _selectedDifficulty;
  final List<Map<String, dynamic>> _steps = [];
  bool _isSubmitting = false;
  String? _error;
  bool _isLoadingAI = false;
  YoutubePlayerController? _youtubeController;

  // Theme colors
  final Color _primaryColor = const Color.fromRGBO(124, 58, 237, 1);
  final Color _backgroundColor = const Color(0xFFF8F9FA);
  final Color _cardColor = Colors.white;
  final Color _textColor = Colors.black87;
  final Color _secondaryTextColor = Colors.black54;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.experiment['title'] ?? '';
    _descriptionController.text = widget.experiment['description'] ?? '';
    _selectedSubject = widget.experiment['subject'] ?? 'Biology';
    _selectedDifficulty = widget.experiment['difficulty'] ?? 'Beginner';
    _materialsController.text = (widget.experiment['materials'] as List<dynamic>?)?.join(', ') ?? '';
    if (widget.experiment['steps'] != null) {
      _steps.addAll(List<Map<String, dynamic>>.from(widget.experiment['steps']));
    }
  }

  void _addStep() {
    if (_stepInstructionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text('Please enter a step instruction'),
            ],
          ),
          backgroundColor: _primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final mediaUrl = _stepMediaUrlController.text.trim();
    if (mediaUrl.isNotEmpty) {
      final videoId = YoutubePlayer.convertUrlToId(mediaUrl);
      if (videoId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.warning_rounded, color: Colors.white),
                SizedBox(width: 8),
                Text('Media URL must be a valid YouTube URL'),
              ],
            ),
            backgroundColor: _primaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        return;
      }
    }

    setState(() {
      _steps.add({
        'stepNumber': _steps.length + 1,
        'instruction': _stepInstructionController.text.trim(),
        'mediaUrl': mediaUrl.isNotEmpty ? mediaUrl : null,
      });
      _stepInstructionController.clear();
      _stepMediaUrlController.clear();
      _youtubeController?.dispose();
      _youtubeController = null;
    });
  }

  void _removeStep(int index) {
    setState(() {
      _steps.removeAt(index);
      for (int i = 0; i < _steps.length; i++) {
        _steps[i]['stepNumber'] = i + 1;
      }
    });
  }

  Future<void> _editStep(int index) async {
    final step = _steps[index];
    final editInstructionController = TextEditingController(text: step['instruction']);
    final editMediaUrlController = TextEditingController(text: step['mediaUrl'] ?? '');
    YoutubePlayerController? editYoutubeController;

    if (editMediaUrlController.text.isNotEmpty) {
      final videoId = YoutubePlayer.convertUrlToId(editMediaUrlController.text);
      if (videoId != null) {
        editYoutubeController = YoutubePlayerController(
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

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Edit Step ${step['stepNumber']}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: editInstructionController,
                  decoration: InputDecoration(
                    labelText: 'Step Instruction',
                    hintText: 'Describe what to do in this step',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _primaryColor, width: 2),
                    ),
                  ),
                  maxLines: 3,
                  validator: (value) => value!.isEmpty ? 'Instruction is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: editMediaUrlController,
                  decoration: InputDecoration(
                    labelText: 'YouTube Video URL (Optional)',
                    hintText: 'Add a YouTube video URL (e.g., https://youtu.be/VIDEO_ID)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _primaryColor, width: 2),
                    ),
                  ),
                  onChanged: (value) {
                    final videoId = YoutubePlayer.convertUrlToId(value);
                    if (videoId != null) {
                      setDialogState(() {
                        editYoutubeController?.dispose();
                        editYoutubeController = YoutubePlayerController(
                          initialVideoId: videoId,
                          flags: const YoutubePlayerFlags(
                            autoPlay: false,
                            mute: false,
                            disableDragSeek: false,
                            loop: false,
                            enableCaption: false,
                          ),
                        );
                      });
                    } else {
                      setDialogState(() {
                        editYoutubeController?.dispose();
                        editYoutubeController = null;
                      });
                    }
                  },
                ),
                if (editYoutubeController != null)
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    child: YoutubePlayer(
                      controller: editYoutubeController!,
                      showVideoProgressIndicator: true,
                      progressIndicatorColor: _primaryColor,
                      progressColors: ProgressBarColors(
                        playedColor: _primaryColor,
                        handleColor: _primaryColor,
                        bufferedColor: _primaryColor.withOpacity(0.3),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: _primaryColor)),
            ),
            ElevatedButton(
              onPressed: () {
                if (editInstructionController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Step instruction cannot be empty'),
                      backgroundColor: _primaryColor,
                    ),
                  );
                  return;
                }
                final mediaUrl = editMediaUrlController.text.trim();
                if (mediaUrl.isNotEmpty && YoutubePlayer.convertUrlToId(mediaUrl) == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Media URL must be a valid YouTube URL'),
                      backgroundColor: _primaryColor,
                    ),
                  );
                  return;
                }
                Navigator.pop(context, {
                  'instruction': editInstructionController.text.trim(),
                  'mediaUrl': mediaUrl.isNotEmpty ? mediaUrl : null,
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    editYoutubeController?.dispose();

    if (result != null) {
      setState(() => _isSubmitting = true);
      try {
        await ApiService.updateStep(widget.experiment['_id'], index, {
          'stepNumber': _steps[index]['stepNumber'],
          'instruction': result['instruction'],
          'mediaUrl': result['mediaUrl'],
        });
        setState(() {
          _steps[index] = {
            'stepNumber': _steps[index]['stepNumber'],
            'instruction': result['instruction'],
            'mediaUrl': result['mediaUrl'],
          };
          _error = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 8),
                Text('Step updated successfully.'),
              ],
            ),
            backgroundColor: _primaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } catch (e) {
        setState(() => _error = e.toString());
      } finally {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _generateMetadata() async {
    if (_titleController.text.isEmpty) {
      setState(() => _error = 'Please enter a title to generate metadata');
      return;
    }
    setState(() => _isLoadingAI = true);
    try {
      final metadata = await OpenAIService.generateExperimentMetadata(_titleController.text);
      setState(() {
        _descriptionController.text = metadata['description'] ?? _descriptionController.text;
        _selectedSubject = metadata['subject'] ?? _selectedSubject;
        _selectedDifficulty = metadata['difficulty'] ?? _selectedDifficulty;
        _materialsController.text = (metadata['materials'] as List<dynamic>?)?.join(', ') ?? _materialsController.text;
        _isLoadingAI = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoadingAI = false;
      });
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate() && _steps.isNotEmpty) {
      setState(() {
        _isSubmitting = true;
        _error = null;
      });

      try {
        final experimentData = {
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'subject': _selectedSubject,
          'difficulty': _selectedDifficulty,
          'materials': _materialsController.text
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList(),
          'steps': _steps,
        };

        await ApiService.updateExperiment(widget.experiment['_id'], experimentData);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 8),
                Text('Experiment updated successfully!'),
              ],
            ),
            backgroundColor: _primaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context);
      } catch (e) {
        setState(() => _error = e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_rounded, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('Failed to update experiment: $e')),
              ],
            ),
            backgroundColor: _primaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } finally {
        setState(() => _isSubmitting = false);
      }
    } else if (_steps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text('Please add at least one step'),
            ],
          ),
          backgroundColor: _primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _initializeYouTubePlayer(String url) {
    final videoId = YoutubePlayer.convertUrlToId(url);
    if (videoId != null) {
      setState(() {
        _youtubeController?.dispose();
        _youtubeController = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(
            autoPlay: false,
            mute: false,
            disableDragSeek: false,
            loop: false,
            enableCaption: false,
          ),
        );
      });
    } else {
      setState(() {
        _youtubeController?.dispose();
        _youtubeController = null;
      });
    }
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
    String? hint,
    Function(String)? onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _textColor,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            validator: validator,
            maxLines: maxLines,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: _secondaryTextColor),
              prefixIcon: Icon(icon, color: _primaryColor, size: 20),
              filled: true,
              fillColor: _backgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _primaryColor.withOpacity(0.2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _primaryColor.withOpacity(0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _primaryColor, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required IconData icon,
    required Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _textColor,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: value,
            onChanged: onChanged,
            validator: validator,
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              );
            }).toList(),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: _primaryColor, size: 20),
              filled: true,
              fillColor: _backgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _primaryColor.withOpacity(0.2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _primaryColor.withOpacity(0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _primaryColor, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _primaryColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _textColor,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _materialsController.dispose();
    _stepInstructionController.dispose();
    _stepMediaUrlController.dispose();
    _youtubeController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        leading: Container(
          margin: const EdgeInsets.only(left: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        title: const Text(
          'Edit Experiment',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            // Basic Information Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _primaryColor.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Basic Information', Icons.info_outline_rounded),
                  const SizedBox(height: 24),
                  _buildInputField(
                    controller: _titleController,
                    label: 'Experiment Title',
                    icon: Icons.title_rounded,
                    hint: 'Enter a descriptive title',
                    validator: (value) => value!.isEmpty ? 'Title is required' : null,
                  ),
                  _buildInputField(
                    controller: _descriptionController,
                    label: 'Description',
                    icon: Icons.description_rounded,
                    hint: 'Describe what this experiment is about',
                    maxLines: 3,
                    validator: (value) => value!.isEmpty ? 'Description is required' : null,
                  ),
                  _buildDropdownField(
                    label: 'Subject',
                    value: _selectedSubject,
                    items: ['Biology', 'Chemistry', 'Physics'],
                    icon: Icons.school_rounded,
                    onChanged: (value) {
                      setState(() {
                        _selectedSubject = value;
                      });
                    },
                    validator: (value) => value == null ? 'Subject is required' : null,
                  ),
                  _buildDropdownField(
                    label: 'Difficulty Level',
                    value: _selectedDifficulty,
                    items: ['Beginner', 'Intermediate', 'Advanced'],
                    icon: Icons.bar_chart_rounded,
                    onChanged: (value) {
                      setState(() {
                        _selectedDifficulty = value;
                      });
                    },
                    validator: (value) => value == null ? 'Difficulty is required' : null,
                  ),
                  _buildInputField(
                    controller: _materialsController,
                    label: 'Materials',
                    icon: Icons.inventory_2_rounded,
                    hint: 'Enter materials separated by commas',
                    maxLines: 2,
                    validator: (value) => value!.isEmpty ? 'Materials are required' : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // AI Assistant Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _primaryColor.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, color: _primaryColor, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Assistant',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _textColor,
                          ),
                        ),
                        Text(
                          'Generate metadata using AI',
                          style: TextStyle(
                            fontSize: 14,
                            color: _secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _titleController.text.isNotEmpty && !_isLoadingAI
                        ? _generateMetadata
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoadingAI
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text('Generate'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Experiment Steps Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _primaryColor.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Experiment Steps', Icons.format_list_numbered_rounded),
                  const SizedBox(height: 24),
                  _buildInputField(
                    controller: _stepInstructionController,
                    label: 'Step Instruction',
                    icon: Icons.edit_note_rounded,
                    hint: 'Describe what to do in this step',
                    maxLines: 3,
                  ),
                  _buildInputField(
                    controller: _stepMediaUrlController,
                    label: 'YouTube Video URL (Optional)',
                    icon: Icons.video_library_rounded,
                    hint: 'Add a YouTube video URL',
                    onChanged: (value) {
                      final videoId = YoutubePlayer.convertUrlToId(value);
                      if (videoId != null) {
                        setState(() {
                          _youtubeController?.dispose();
                          _youtubeController = YoutubePlayerController(
                            initialVideoId: videoId,
                            flags: const YoutubePlayerFlags(
                              autoPlay: false,
                              mute: false,
                              disableDragSeek: false,
                              loop: false,
                              enableCaption: false,
                            ),
                          );
                        });
                      } else {
                        setState(() {
                          _youtubeController?.dispose();
                          _youtubeController = null;
                        });
                      }
                    },
                  ),
                  if (_youtubeController != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 20, top: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: YoutubePlayer(
                          controller: _youtubeController!,
                          showVideoProgressIndicator: true,
                          progressIndicatorColor: _primaryColor,
                          progressColors: ProgressBarColors(
                            playedColor: _primaryColor,
                            handleColor: _primaryColor,
                            bufferedColor: _primaryColor.withOpacity(0.3),
                          ),
                        ),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _addStep,
                      icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                      label: const Text(
                        'Add Step',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Added Steps Section
            if (_steps.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _primaryColor.withOpacity(0.1)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${_steps.length}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Steps Added',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: _textColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ..._steps.asMap().entries.map(
                          (entry) => Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _backgroundColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _primaryColor.withOpacity(0.1)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: _primaryColor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${entry.value['stepNumber']}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entry.value['instruction'],
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: _textColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (entry.value['mediaUrl'] != null) ...[
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Icon(Icons.video_library_rounded, size: 14, color: _primaryColor),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                'Video attached',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: _primaryColor,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: _primaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: IconButton(
                                        onPressed: () => _editStep(entry.key),
                                        icon: Icon(
                                          Icons.edit_rounded,
                                          color: _primaryColor,
                                          size: 18,
                                        ),
                                        padding: const EdgeInsets.all(6),
                                        constraints: const BoxConstraints(),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: IconButton(
                                        onPressed: () => _removeStep(entry.key),
                                        icon: Icon(
                                          Icons.delete_outline_rounded,
                                          color: Colors.red,
                                          size: 18,
                                        ),
                                        padding: const EdgeInsets.all(6),
                                        constraints: const BoxConstraints(),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ],

            // Submit Button
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                child: _isSubmitting
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Updating Experiment...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        'Update Experiment',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline_rounded, color: Colors.red, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}