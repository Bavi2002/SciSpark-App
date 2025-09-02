import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/openai_service.dart';


class ExperimentCreateScreen extends StatefulWidget {
  @override
  _ExperimentCreateScreenState createState() => _ExperimentCreateScreenState();
}

class _ExperimentCreateScreenState extends State<ExperimentCreateScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _subjectAreaController = TextEditingController();
  final _difficultyLevelController = TextEditingController();
  final _materialsController = TextEditingController();
  String? _error;
  bool _isLoadingAI = false;

  Future<void> _generateMetadata() async {
    if (_titleController.text.isEmpty) {
      setState(() {
        _error = 'Please enter a title to generate metadata';
      });
      return;
    }
    setState(() => _isLoadingAI = true);
    try {
      final metadata = await OpenAIService.generateExperimentMetadata(_titleController.text);
      setState(() {
        _descriptionController.text = metadata['description'] ?? '';
        _subjectAreaController.text = metadata['subject'] ?? '';
        _difficultyLevelController.text = metadata['difficulty'] ?? '';
        _materialsController.text = (metadata['materials'] as List<dynamic>?)?.join(', ') ?? '';
        _isLoadingAI = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoadingAI = false;
      });
    }
  }

  Future<void> _createExperiment() async {
    try {
      final materials = _materialsController.text.isEmpty
          ? []
          : _materialsController.text.split(',').map((m) => m.trim()).toList();
      final body = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'subjectArea': _subjectAreaController.text,
        'difficultyLevel': _difficultyLevelController.text,
        'materials': materials,
        'steps': [],
      };
      final response = await ApiService.request('/experiments/add', 'POST', body: body);
      if (response.statusCode == 201) {
        Navigator.pop(context);
      } else {
        setState(() {
          _error = jsonDecode(response.body)['error'] ?? 'Failed to create experiment';
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
      appBar: AppBar(title: Text('Create Experiment')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            TextField(
              controller: _subjectAreaController,
              decoration: InputDecoration(labelText: 'Subject Area (e.g., Chemistry)'),
            ),
            TextField(
              controller: _difficultyLevelController,
              decoration: InputDecoration(labelText: 'Difficulty Level (e.g., Beginner)'),
            ),
            TextField(
              controller: _materialsController,
              decoration: InputDecoration(labelText: 'Materials (comma-separated)'),
            ),
            if (_error != null) Text(_error!, style: TextStyle(color: Colors.red)),
            SizedBox(height: 16),
            _isLoadingAI
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _titleController.text.isNotEmpty ? _generateMetadata : null,
                    child: Text('Generate Metadata with AI'),
                  ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _createExperiment,
              child: Text('Create Experiment'),
            ),
          ],
        ),
      ),
    );
  }
}