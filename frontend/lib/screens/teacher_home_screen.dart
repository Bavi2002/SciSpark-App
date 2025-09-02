import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/screens/add_experiment_screen.dart';
import 'package:frontend/screens/auth_wrapper.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/auth_service.dart';
import 'experiment_edit_screen.dart';

class TeacherHomeScreen extends StatelessWidget {
  Future<List<dynamic>> _fetchExperiments() async {
    final response = await ApiService.request('/api/experiments', 'GET', authRequired: false);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load experiments');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Teacher Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await AuthService.logout();
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AuthWrapper()));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddExperimentScreen()),
              ),
              child: Text('Create New Experiment'),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _fetchExperiments(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final exp = snapshot.data![index];
                      return ListTile(
                        title: Text(exp['title']),
                        subtitle: Text('${exp['description']} - ${exp['subjectArea']}'),
                        trailing: IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ExperimentEditScreen(
                                experimentId: exp['_id'],
                                title: exp['title'],
                              ),
                            ),
                          ),
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
          ),
        ],
      ),
    );
  }
}