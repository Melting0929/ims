import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class StudentDetailPage extends StatefulWidget {
  final String studentId;

  const StudentDetailPage({super.key, required this.studentId});

  @override
  StudentDetailPageState createState() => StudentDetailPageState();
}

class StudentDetailPageState extends State<StudentDetailPage> {
  late Future<Map<String, dynamic>> _studentData;

  @override
  void initState() {
    super.initState();
    _studentData = _getStudentData(widget.studentId);
  }

  Future<Map<String, dynamic>> _getStudentData(String studentId) async {
    try {
      DocumentSnapshot studentSnapshot = await FirebaseFirestore.instance
          .collection('Student')
          .doc(studentId)
          .get();

      if (!studentSnapshot.exists) throw 'Student not found';

      Map<String, dynamic> student = studentSnapshot.data() as Map<String, dynamic>;

      String userID = student['userID'];
      DocumentSnapshot userSnapshot =
          await FirebaseFirestore.instance.collection('Users').doc(userID).get();
      Map<String, dynamic> user = userSnapshot.data() as Map<String, dynamic>;

      String companyName = 'No Working Company';
      String supervisorName = 'No Supervisor';

      if (student['companyID'] != null && student['companyID'] != '') {
        DocumentSnapshot companySnapshot = await FirebaseFirestore.instance
            .collection('Company')
            .doc(student['companyID'])
            .get();
        Map<String, dynamic> company =
            companySnapshot.exists ? companySnapshot.data() as Map<String, dynamic> : {};
        companyName = company['companyName'] ?? companyName;
      }

      if (student['supervisorID'] != null && student['supervisorID'] != '') {
      DocumentSnapshot supervisorSnapshot = await FirebaseFirestore.instance
          .collection('Supervisor')
          .doc(student['supervisorID'])
          .get();

      if (supervisorSnapshot.exists) {
        Map<String, dynamic> supervisorData =
            supervisorSnapshot.data() as Map<String, dynamic>;

        String? userID = supervisorData['userID'];

        if (userID != null && userID.isNotEmpty) {
          DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
              .collection('Users')
              .doc(userID)
              .get();

          if (userSnapshot.exists) {
            Map<String, dynamic> userData =
                userSnapshot.data() as Map<String, dynamic>;
            supervisorName = userData['name'] ?? supervisorName;
          }
        }
      }
    }

      return {
        'name': user['name'] ?? 'No Name',
        'email': user['email'] ?? 'No Email',
        'contactNo': student['contactNo'] ?? 'No Contact',
        'dept': student['dept'] ?? 'No Department',
        'skill': student['skill'] ?? 'No Skill',
        'specialization': student['specialization'] ?? 'No Specialization',
        'studProgram': student['studProgram'] ?? 'No Program',
        'companyName': companyName,
        'supervisorName': supervisorName,
        'resumeURL': student['resumeURL'] ?? '',
      };
    } catch (e) {
      print('Error retrieving student data: $e');
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
      appBar: AppBar(title: const Text('Student Detail')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _studentData,
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

          var student = snapshot.data!;

          String resumeURL = student['resumeURL'];

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
                      'Personal Info',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                    const Divider(),
                    _buildDetailRow('Name', student['name']),
                    _buildDetailRow('Email', student['email']),
                    _buildDetailRow('Contact No', student['contactNo'] ?? 'No Contact'), // Handle null value here

                    const SizedBox(height: 20),
                    const Text(
                      'Academic Info',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                    const Divider(),
                    _buildDetailRow('Department', student['dept']),
                    // Handle nullable skill (checking if it's a list or a single value)
                    _buildDetailRow('Skill', student['skill'] is List ? (student['skill'] as List).join(', ') : student['skill'] ?? 'No Skill'),
                    _buildDetailRow('Specialization', student['specialization']),
                    _buildDetailRow('Program', student['studProgram']),

                    const SizedBox(height: 20),
                    const Text(
                      'Internship Info',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                    const Divider(),
                    _buildDetailRow('Company', student['companyName']),
                    _buildDetailRow('Supervisor', student['supervisorName']),
                    const SizedBox(height: 20),
                    const Text(
                      'Resume',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                    const Divider(),
                    if (resumeURL.isNotEmpty)
                      ElevatedButton.icon(
                        onPressed: () async {
                          final url = Uri.parse(resumeURL);
                          try {
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url, mode: LaunchMode.externalApplication);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Could not open the document or No Document')),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        },
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('View Resume'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      )
                    else
                      const Text('No resume uploaded.'),
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
