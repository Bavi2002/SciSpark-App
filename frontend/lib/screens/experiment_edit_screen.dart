import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'step_edit_screen.dart';

class ExperimentEditScreen extends StatefulWidget {
  final String experimentId;
  final String title;

  ExperimentEditScreen({required this.experimentId, required this.title});

  @override
  _ExperimentEditScreenState createState() => _ExperimentEditScreenState();
}

class _ExperimentEditScreenState extends State<ExperimentEditScreen> {
  Map<String, dynamic>? _experiment;
  String? _error;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _subjectAreaController = TextEditingController();
  final _difficultyLevelController = TextEditingController();
  final _materialsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchExperiment();
  }

  Future<void> _fetchExperiment() async {
    try {
      final response = await ApiService.request('/api/experiments/${widget.experimentId}', 'GET');
      if (response.statusCode == 200) {
        setState(() {
          _experiment = jsonDecode(response.body);
          _titleController.text = _experiment!['title'] ?? '';
          _descriptionController.text = _experiment!['description'] ?? '';
          _subjectAreaController.text = _experiment!['subject'] ?? '';
          _difficultyLevelController.text = _experiment!['difficulty']?.toString() ?? '';
          _materialsController.text = (_experiment!['materials'] as List<dynamic>?)
              ?.join(', ') ?? '';
        });
      } else {
        setState(() {
          _error = jsonDecode(response.body)['error'] ?? 'Failed to fetch experiment';
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  Future<void> _updateExperiment() async {
    try {
      final materials = _materialsController.text.isEmpty
          ? []
          : _materialsController.text.split(',').map((m) => m.trim()).toList();
      final body = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'subject': _subjectAreaController.text,
        'difficulty': _difficultyLevelController.text,
        'materials': materials,
      };
      final response = await ApiService.request('/api/experiments/${widget.experimentId}', 'PUT', body: body);
      if (response.statusCode == 200) {
        Navigator.pop(context);
      } else {
        setState(() {
          _error = jsonDecode(response.body)['error'] ?? 'Failed to update experiment';
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  Future<void> _deleteExperiment() async {
    try {
      final response = await ApiService.request('/api/experiments/${widget.experimentId}', 'DELETE');
      if (response.statusCode == 200) {
        Navigator.pop(context);
      } else {
        setState(() {
          _error = jsonDecode(response.body)['error'] ?? 'Failed to delete experiment';
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
    if (_experiment == null && _error == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Center(child: Text(_error!)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Delete Experiment'),
                  content: Text('Are you sure you want to delete this experiment?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        _deleteExperiment();
                        Navigator.pop(context);
                      },
                      child: Text('Delete'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
              decoration: InputDecoration(labelText: 'Subject Area'),
            ),
            TextField(
              controller: _difficultyLevelController,
              decoration: InputDecoration(labelText: 'Difficulty Level'),
            ),
            TextField(
              controller: _materialsController,
              decoration: InputDecoration(labelText: 'Materials (comma-separated)'),
            ),
            if (_error != null) Text(_error!, style: TextStyle(color: Colors.red)),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _updateExperiment,
              child: Text('Update Experiment'),
            ),
            SizedBox(height: 16),
            Text('Steps:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...List.generate(_experiment!['steps']?.length ?? 0, (index) {
              final step = _experiment!['steps'][index];
              return ListTile(
                title: Text(step['text'] ?? ''),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StepEditScreen(
                            experimentId: widget.experimentId,
                            stepIndex: index,
                            step: step,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Delete Step'),
                            content: Text('Are you sure you want to delete this step?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  try {
                                    final response = await ApiService.request(
                                      '/experiments/${widget.experimentId}/steps/$index',
                                      'DELETE',
                                    );
                                    if (response.statusCode == 200) {
                                      setState(() {
                                        _experiment!['steps'].removeAt(index);
                                      });
                                    }
                                  } catch (e) {
                                    setState(() {
                                      _error = e.toString();
                                    });
                                  }
                                  Navigator.pop(context);
                                },
                                child: Text('Delete'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            }),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StepEditScreen(
                    experimentId: widget.experimentId,
                    stepIndex: null, // New step
                    step: null,
                  ),
                ),
              ),
              child: Text('Add New Step'),
            ),
          ],
        ),
      ),
    );
  }
}