import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/openai_service.dart';

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
  final _subjectController = TextEditingController();
  final _difficultyController = TextEditingController();
  final _materialsController = TextEditingController();
  final List<Map<String, dynamic>> _steps = [];
  final _stepInstructionController = TextEditingController();
  final _stepMediaUrlController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;
  bool _isLoadingAI = false;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.experiment['title'] ?? '';
    _descriptionController.text = widget.experiment['description'] ?? '';
    _subjectController.text = widget.experiment['subject'] ?? '';
    _difficultyController.text = widget.experiment['difficulty'] ?? '';
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
            children: const [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 8),
              Text('Please enter a step instruction'),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    setState(() {
      _steps.add({
        'stepNumber': _steps.length + 1,
        'instruction': _stepInstructionController.text.trim(),
        'mediaUrl': _stepMediaUrlController.text.trim().isNotEmpty
            ? _stepMediaUrlController.text.trim()
            : null,
      });
      _stepInstructionController.clear();
      _stepMediaUrlController.clear();
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

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Step ${step['stepNumber']}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: editInstructionController,
                decoration: const InputDecoration(
                  labelText: 'Step Instruction',
                  hintText: 'Describe what to do in this step',
                ),
                maxLines: 3,
                validator: (value) => value!.isEmpty ? 'Instruction is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: editMediaUrlController,
                decoration: const InputDecoration(
                  labelText: 'Media URL (Optional)',
                  hintText: 'Add an image or video URL',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (editInstructionController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Step instruction cannot be empty'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.pop(context, {
                'instruction': editInstructionController.text.trim(),
                'mediaUrl': editMediaUrlController.text.trim().isNotEmpty
                    ? editMediaUrlController.text.trim()
                    : null,
              });
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() => _isSubmitting = true);
      try {
        await ApiService.updateStep(widget.experiment['_id'], index, {
          'stepNumber': result['stepNumber'],
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
          const SnackBar(
            content: Text('Step updated successfully.'),
            backgroundColor: Colors.green,
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
        _subjectController.text = metadata['subject'] ?? _subjectController.text;
        _difficultyController.text = metadata['difficulty'] ?? _difficultyController.text;
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
          'subject': _subjectController.text.trim(),
          'difficulty': _difficultyController.text.trim(),
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
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Experiment updated successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        Navigator.pop(context);
      } catch (e) {
        setState(() => _error = e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Failed to update experiment: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      } finally {
        setState(() => _isSubmitting = false);
      }
    } else if (_steps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 8),
              Text('Please add at least one step'),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
    String? hint,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            validator: validator,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[500]),
              prefixIcon: Icon(icon, color: Colors.grey[600], size: 20),
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.black, width: 2),
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

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _subjectController.dispose();
    _difficultyController.dispose();
    _materialsController.dispose();
    _stepInstructionController.dispose();
    _stepMediaUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back, size: 20),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Edit Experiment',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey[200]),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.info_outline,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Basic Information',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildInputField(
                    controller: _titleController,
                    label: 'Experiment Title',
                    icon: Icons.title,
                    hint: 'Enter a descriptive title',
                    validator: (value) => value!.isEmpty ? 'Title is required' : null,
                  ),
                  _buildInputField(
                    controller: _descriptionController,
                    label: 'Description',
                    icon: Icons.description,
                    hint: 'Describe what this experiment is about',
                    maxLines: 3,
                    validator: (value) => value!.isEmpty ? 'Description is required' : null,
                  ),
                  _buildInputField(
                    controller: _subjectController,
                    label: 'Subject',
                    icon: Icons.school,
                    hint: 'e.g., Chemistry, Physics, Biology',
                    validator: (value) => value!.isEmpty ? 'Subject is required' : null,
                  ),
                  _buildInputField(
                    controller: _difficultyController,
                    label: 'Difficulty Level',
                    icon: Icons.bar_chart,
                    hint: 'e.g., Beginner, Intermediate, Advanced',
                    validator: (value) => value!.isEmpty ? 'Difficulty is required' : null,
                  ),
                  _buildInputField(
                    controller: _materialsController,
                    label: 'Materials',
                    icon: Icons.inventory_2,
                    hint: 'Enter materials separated by commas',
                    maxLines: 2,
                    validator: (value) => value!.isEmpty ? 'Materials are required' : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.format_list_numbered,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Experiment Steps',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildInputField(
                    controller: _stepInstructionController,
                    label: 'Step Instruction',
                    icon: Icons.edit_note,
                    hint: 'Describe what to do in this step',
                    maxLines: 3,
                  ),
                  _buildInputField(
                    controller: _stepMediaUrlController,
                    label: 'Media URL (Optional)',
                    icon: Icons.image,
                    hint: 'Add an image or video URL',
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _addStep,
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text(
                        'Add Step',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_steps.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Added Steps (${_steps.length})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._steps.asMap().entries.map(
                          (entry) => Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${entry.value['stepNumber']}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
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
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.black,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (entry.value['mediaUrl'] != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Media: ${entry.value['mediaUrl']}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: () => _editStep(entry.key),
                                      icon: Icon(
                                        Icons.edit,
                                        color: Colors.blue[400],
                                      ),
                                      padding: const EdgeInsets.all(8),
                                      constraints: const BoxConstraints(),
                                    ),
                                    IconButton(
                                      onPressed: () => _removeStep(entry.key),
                                      icon: Icon(
                                        Icons.delete_outline,
                                        color: Colors.red[400],
                                      ),
                                      padding: const EdgeInsets.all(8),
                                      constraints: const BoxConstraints(),
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
            const SizedBox(height: 32),
            _isLoadingAI
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _titleController.text.isNotEmpty
                        ? _generateMetadata
                        : null,
                    child: const Text('Generate Metadata with AI'),
                  ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Updating Experiment...',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : const Text(
                        'Update Experiment',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 32),
            if (_error != null)
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}