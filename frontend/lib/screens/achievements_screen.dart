import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';

class AchievementsScreen extends StatelessWidget {
  Future<List<dynamic>> _fetchAchievements() async {
    final response = await ApiService.request('/achievements', 'GET');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load achievements');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Achievements')),
      body: FutureBuilder<List<dynamic>>(
        future: _fetchAchievements(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final ach = snapshot.data![index];
                return ListTile(
                  title: Text(ach['badge']),
                  subtitle: Text('For: ${ach['experimentId']['title']}'),
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