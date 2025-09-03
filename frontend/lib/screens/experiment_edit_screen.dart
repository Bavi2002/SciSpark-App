import 'package:flutter/material.dart' hide Step;
import 'package:frontend/models/experiment.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/openai_service.dart';

class StepEditScreen extends StatefulWidget {
  final String experimentId;
  final int? stepIndex;
  final Step? step;

  const StepEditScreen({
    required this.experimentId,
    this.stepIndex,
    this.step,
    super.key,
  });

  @override
  _StepEditScreenState createState() => _StepEditScreenState();
}

class _StepEditScreenState extends State<StepEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _instructionController = TextEditingController();
  final _mediaUrlController = TextEditingController();
  final _stepNumberController = TextEditingController();
  String? _error;
  bool _isLoadingAI = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.step != null) {
      _instructionController.text = widget.step!.instruction;
      _mediaUrlController.text = widget.step!.mediaUrl ?? '';
      _stepNumberController.text = widget.step!.stepNumber.toString();
    } else {
      _stepNumberController.text = ''; // Will be set by backend or form
    }
  }

  Future<void> _generateStepSuggestions() async {
    setState(() => _isLoadingAI = true);
    try {
      final suggestions = await OpenAIService.generateStepSuggestions('Experiment Step Suggestions');
      if (suggestions.isNotEmpty) {
        setState(() {
          _instructionController.text = suggestions[0]['instruction'] ?? '';
          _mediaUrlController.text = suggestions[0]['mediaUrl'] ?? '';
          _isLoadingAI = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoadingAI = false;
      });
    }
  }

  Future<void> _saveStep() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
        _error = null;
      });
      try {
        final stepData = {
          'stepNumber': int.tryParse(_stepNumberController.text) ?? (widget.stepIndex != null ? widget.step!.stepNumber : 0),
          'instruction': _instructionController.text.trim(),
          'mediaUrl': _mediaUrlController.text.trim().isNotEmpty ? _mediaUrlController.text.trim() : null,
        };

        if (widget.stepIndex == null) {
          await ApiService.addStep(widget.experimentId, stepData);
        } else {
          await ApiService.updateStep(widget.experimentId, widget.stepIndex!, stepData);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(widget.stepIndex == null ? 'Step added successfully!' : 'Step updated successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        Navigator.pop(context);
      } catch (e) {
        setState(() {
          _error = e.toString();
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Text('Failed to save step: $e'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
    String? hint,
    TextInputType? keyboardType,
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
            keyboardType: keyboardType,
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
    _instructionController.dispose();
    _mediaUrlController.dispose();
    _stepNumberController.dispose();
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.stepIndex == null ? 'Add Step' : 'Edit Step',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Colors.grey),
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
                          Icons.format_list_numbered,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        widget.stepIndex == null ? 'New Step' : 'Edit Step #${widget.step?.stepNumber}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildInputField(
                    controller: _stepNumberController,
                    label: 'Step Number',
                    icon: Icons.numbers,
                    hint: 'Enter step number (e.g., 1, 2, 3)',
                    validator: (value) {
                      if (value!.isEmpty) return 'Step number is required';
                      if (int.tryParse(value) == null || int.parse(value) <= 0) {
                        return 'Step number must be a positive integer';
                      }
                      return null;
                    },
                    keyboardType: TextInputType.number,
                  ),
                  _buildInputField(
                    controller: _instructionController,
                    label: 'Step Instruction',
                    icon: Icons.edit_note,
                    hint: 'Describe what to do in this step',
                    maxLines: 3,
                    validator: (value) => value!.isEmpty ? 'Instruction is required' : null,
                  ),
                  _buildInputField(
                    controller: _mediaUrlController,
                    label: 'Media URL (Optional)',
                    icon: Icons.image,
                    hint: 'Add an image or video URL',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _isLoadingAI
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _generateStepSuggestions,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Generate Step with AI',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _saveStep,
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
                            'Saving Step...',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        widget.stepIndex == null ? 'Add Step' : 'Update Step',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}