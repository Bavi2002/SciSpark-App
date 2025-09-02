import 'dart:convert';
import 'package:flutter/material.dart';

import '../services/api_service.dart';

class ProgressScreen extends StatelessWidget {
  Future<List<dynamic>> _fetchProgress() async {
    final response = await ApiService.request('/api/student/progress', 'GET');
    print('Fetching progress data... ${response.body}');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load progress');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Progress')),
      body: FutureBuilder<List<dynamic>>(
        future: _fetchProgress(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final prog = snapshot.data![index];
                return ListTile(
                  title: Text(
                    prog['experimentId'] != null
                        ? prog['experimentId']['title'] ?? 'Unknown Experiment'
                        : 'Unknown Experiment',
                  ),
                  subtitle: Text(
                    'Status: ${prog['status']} | Completed Steps: ${prog['completedSteps']?.length ?? 0}',
                  ),
                );
              },
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('${snapshot.error}'));
          }
          return Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
