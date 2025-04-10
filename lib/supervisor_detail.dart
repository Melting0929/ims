import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SupervisorDetailPage extends StatefulWidget {
  final String supervisorId;

  const SupervisorDetailPage({super.key, required this.supervisorId});

  @override
  SupervisorDetailPageState createState() => SupervisorDetailPageState();
}

class SupervisorDetailPageState extends State<SupervisorDetailPage> {
  late Future<Map<String, dynamic>> _supervisorData;

  @override
  void initState() {
    super.initState();
    _supervisorData = _getSupervisorData(widget.supervisorId);
  }

  Future<Map<String, dynamic>> _getSupervisorData(String supervisorId) async {
    try {
      DocumentSnapshot supervisorSnapshot = await FirebaseFirestore.instance
          .collection('Supervisor')
          .doc(supervisorId)
          .get();

      if (!supervisorSnapshot.exists) throw 'Supervisor not found';

      Map<String, dynamic> supervisor = supervisorSnapshot.data() as Map<String, dynamic>;

      // Fetch the corresponding user data using userID from the Supervisor document
      String userID = supervisor['userID'];
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userID)
          .get();

      if (!userSnapshot.exists) throw 'User not found';

      Map<String, dynamic> user = userSnapshot.data() as Map<String, dynamic>;

      return {
        'name': user['name'] ?? 'No Name',
        'email': user['email'] ?? 'No Email',
        'contactNo': user['contactNo'] ?? 'No Contact', // Handle null contactNo
        'dept': supervisor['dept'] ?? 'No Department', // dept from Supervisor collection
      };
    } catch (e) {
      print('Error retrieving supervisor data: $e');
      rethrow;
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Supervisor Detail')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _supervisorData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('No data available.'));
          }

          var supervisor = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Supervisor Info',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                    const Divider(),
                    _buildDetailRow('Name', supervisor['name']),
                    _buildDetailRow('Email', supervisor['email']),
                    _buildDetailRow('Contact No', supervisor['contactNo']), // Handle nullable contactNo here
                    _buildDetailRow('Department', supervisor['dept']), // Handle nullable dept here
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
