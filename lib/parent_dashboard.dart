import 'package:flutter/material.dart';
import 'package:my_app/services/api_service.dart'; // Add the correct path
import 'package:http/http.dart' as http;

class ParentDashboardScreen extends StatefulWidget {
  @override
  _ParentDashboardScreenState createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  late ApiService apiService;
  late Future<List<dynamic>> parentData;

  @override
  void initState() {
    super.initState();
    apiService = ApiService(baseUrl: 'http://your-backend-url.com'); // Set your backend URL here
    parentData = apiService.fetchParentDashboardData('your_jwt_token'); // Replace with JWT
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Parent Dashboard'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: parentData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No data available.'));
          }

          // Display data in a list
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              var progressItem = snapshot.data![index];
              return Card(
                child: ListTile(
                  title: Text(progressItem['experimentName']),
                  subtitle: Text(progressItem['status']),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
