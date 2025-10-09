import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/auth_service.dart';

class StudentProgressScreen extends StatefulWidget {
  const StudentProgressScreen({super.key});

  @override
  _StudentProgressScreenState createState() => _StudentProgressScreenState();
}

class _StudentProgressScreenState extends State<StudentProgressScreen> {
  List<dynamic> _progress = [];
  List<dynamic> _achievements = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final role = await AuthService.getRole();
      if (role != 'student') {
        setState(() {
          _error = 'This page is only accessible to students';
          _isLoading = false;
        });
        return;
      }
      final progress = await ApiService.getStudentProgress();
      final achievements = await ApiService.getStudentAchievements();
      setState(() {
        _progress = progress;
        _achievements = achievements;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Parent Dashboard'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text(
                      'Progress',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (_progress.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No progress yet. Start an experiment!'),
                      )
                    else
                      ..._progress.map((p) => Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              title: Text(p['experimentId']['title']),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Status: ${p['status']}'),
                                  Text('Steps Completed: ${p['completedSteps'].length}/${p['experimentId']['steps']?.length ?? 'N/A'}'),
                                  if (p['completedAt'] != null)
                                    Text('Completed At: ${DateTime.parse(p['completedAt']).toLocal().toString().substring(0, 16)}'),
                                ],
                              ),
                            ),
                          )),
                    const SizedBox(height: 16),
                    const Text(
                      'Achievements',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (_achievements.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No achievements yet. Complete experiments to earn badges!'),
                      )
                    else
                      ..._achievements.map((a) => Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: const Icon(Icons.star, color: Colors.amber),
                              title: Text(a['badge']),
                              subtitle: Text('Experiment: ${a['experimentId']['title']}'),
                            ),
                          )),
                  ],
                ),
    );
  }
}