import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/openai_service.dart';


class StepEditScreen extends StatefulWidget {
  final String experimentId;
  final int? stepIndex;
  final Map<String, dynamic>? step;

  StepEditScreen({required this.experimentId, this.stepIndex, this.step});

  @override
  _StepEditScreenState createState() => _StepEditScreenState();
}

class _StepEditScreenState extends State<StepEditScreen> {
  final _textController = TextEditingController();
  final _mediaUrlController = TextEditingController();
  String? _error;
  bool _isLoadingAI = false;

  @override
  void initState() {
    super.initState();
    if (widget.step != null) {
      _textController.text = widget.step!['instruction'] ?? '';
      _mediaUrlController.text = widget.step!['mediaUrl'] ?? '';
     
    }
  }

  Future<void> _generateStepSuggestions() async {
    setState(() => _isLoadingAI = true);
    try {
      final suggestions = await OpenAIService.generateStepSuggestions('Experiment Step Suggestions');
      if (suggestions.isNotEmpty) {
        setState(() {
          _textController.text = suggestions[0]['instruction'] ?? '';
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
    try {
      final body = {
        'instruction': _textController.text,
        'mediaUrl': _mediaUrlController.text.isEmpty ? null : _mediaUrlController.text,
      };
      final endpoint = widget.stepIndex == null
          ? '/api/experiments/${widget.experimentId}/steps'
          : '/api/experiments/${widget.experimentId}/steps/${widget.stepIndex}';
      final method = widget.stepIndex == null ? 'POST' : 'PUT';
      final response = await ApiService.request(endpoint, method, body: body);
      if (response.statusCode == 200) {
        Navigator.pop(context);
      } else {
        setState(() {
          _error = jsonDecode(response.body)['error'] ?? 'Failed to save step';
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.stepIndex == null ? 'Add Step' : 'Edit Step')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _textController,
              decoration: InputDecoration(labelText: 'Step Description'),
              maxLines: 3,
            ),
            TextField(
              controller: _mediaUrlController,
              decoration: InputDecoration(labelText: 'Image URL (optional)'),
            ),
            
            if (_error != null) Text(_error!, style: TextStyle(color: Colors.red)),
            SizedBox(height: 16),
            _isLoadingAI
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _generateStepSuggestions,
                    child: Text('Generate Step with AI'),
                  ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveStep,
              child: Text(widget.stepIndex == null ? 'Add Step' : 'Update Step'),
            ),
          ],
        ),
      ),
    );
  }
}