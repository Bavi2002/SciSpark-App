import 'package:flutter/material.dart';
import 'package:frontend/screens/achievements_screen.dart';
import 'package:frontend/screens/auth_wrapper.dart';
import 'package:frontend/screens/experiment_list_screen.dart';
import 'package:frontend/screens/progress_screen.dart';
import 'package:frontend/screens/teacher_home_screen.dart';
import 'package:frontend/services/auth_service.dart';


class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Quality Education'), actions: [
        IconButton(icon: Icon(Icons.logout), onPressed: () async {
          await AuthService.logout();
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AuthWrapper()));
        }),
      ]),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ExperimentListScreen())),
              child: Text('Browse Experiments'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProgressScreen())),
              child: Text('View Progress'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AchievementsScreen())),
              child: Text('View Achievements'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TeacherHomeScreen())),
              child: Text('View Teacher Home'),
            ),
          ],
        ),
      ),
    );
  }
}