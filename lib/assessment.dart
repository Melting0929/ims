import 'package:flutter/material.dart';

class AssessmentPage extends StatelessWidget {
  final int? userId;
  const AssessmentPage({super.key, this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assessment'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                // Handle guideline download
              },
              child: const Text('Download Guideline'),
            ),
            const SizedBox(height: 20.0),
            const Text(
              'Offer Letter',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text('Due Date: 1/11/2024'),
            const Text('Status: Due'),
            const Text('Date: October 30, 2024'),
            ElevatedButton(
              onPressed: () {
                // Handle view detail
              },
              child: const Text('View Detail'),
            ),
            const Divider(),
            const Text(
              'Log Sheet Week 1',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text('Due Date: 15/11/2024'),
            const Text('Status: Due'),
            const Text('Date: November 4, 2024'),
            ElevatedButton(
              onPressed: () {
                // Handle view detail
              },
              child: const Text('View Detail'),
            ),
            const Divider(),
            const Text(
              'Log Sheet Week 3',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text('Due Date: 29/11/2024'),
            const Text('Status: Active'),
            const Text('Date: November 18, 2024'),
            ElevatedButton(
              onPressed: () {
                // Handle view detail
              },
              child: const Text('View Detail'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assessment),
            label: 'Assessment',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.apps),
            label: 'Application',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
