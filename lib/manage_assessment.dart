import 'package:data_table_2/data_table_2.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'download_guideline.dart';
import 'login_web.dart';
import 'eprofile_supervisor.dart';
import 'supervisor_dashboard.dart';
import 'add_assessment.dart';
import 'edit_assessment.dart';
import 'color.dart';


class ManageAssessment extends StatefulWidget {
  final String userId;
  const ManageAssessment({super.key, required this.userId});

  @override
  ManageAssessmentTab createState() => ManageAssessmentTab();
}


class ManageAssessmentTab extends State<ManageAssessment> {
  String supervisorEmail = "Loading...";
  String supervisorName = "Loading...";
  String supervisorID = "Loading...";
  String selectedMenu = "Manage Assessment Page";
  final Color headingRowColor = Colors.black;
  final Color rowEvenColor = Colors.grey.shade100;
  final Color rowOddColor = Colors.white;

  List<Map<String, dynamic>> assessmentData = [];

  @override
  void initState() {
    super.initState();
    fetchSupervisorDetails();
  }

  Future<void> _refreshData() async {
    List<Map<String, dynamic>> fetchAssessmentData = await _getAssessmentData();

    setState(() {
      assessmentData = fetchAssessmentData;
    });
  }

  Future<void> fetchSupervisorDetails() async {
    try {
      var userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists) {
        setState(() {
          supervisorEmail = userDoc.data()?['email'] ?? 'No Email';
          supervisorName = userDoc.data()?['name'] ?? 'No Name';
        });

        var supervisorDoc = await FirebaseFirestore.instance
            .collection('Supervisor')
            .where('userID', isEqualTo: widget.userId)
            .get();

        if (supervisorDoc.docs.isNotEmpty) {
          var supervisorData = supervisorDoc.docs.first.data();
          setState(() {
            supervisorID = supervisorData['supervisorID'] ?? 'No ID';

          });
        } else {
          debugPrint('No supervisor details found for the userId: ${widget.userId}');
        }
      }
    } catch (e) {
      debugPrint("Error fetching supervisor details: $e");
    }
  }

  Future<void> logout() async {
    bool confirmLogout = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text("Logout"),
          ],
        ),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Logout", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmLogout) {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginWeb()),
      );
    }
  }

  Widget buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    bool isSelected = selectedMenu == title;
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.black : AppColors.deepYellow),
      title: Text(title, style: TextStyle(color: isSelected ? Colors.black : AppColors.deepYellow)),
      tileColor: isSelected ? AppColors.secondaryYellow : Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: () {
        setState(() {
          selectedMenu = title;
        });
        onTap();
      },
    );
  }

  Future<List<Map<String, dynamic>>> _getAssessmentData() async {
    try {
      QuerySnapshot assessmentSnapshot = await FirebaseFirestore.instance.collection('Assessment').get();
      List<Map<String, dynamic>> assessments = [];

      DateTime now = DateTime.now();

      for (var assessment in assessmentSnapshot.docs) {
        Timestamp endDateTimestamp = assessment['assessmentEndDate'] ?? Timestamp(0, 0);
        DateTime endDate = endDateTimestamp.toDate(); 

        // Determine submission status
        String submissionStatus = endDate.isBefore(now) ? 'Due' : 'Active';

        Map<String, dynamic> assessmentData = {
          'assessmentID': assessment.id,
          'templateID': assessment['templateID'] ?? '',
          'supervisorID': assessment['supervisorID'] ?? '',
          'studID': assessment['studID'] ?? '',
          'intakePeriod': assessment['intakePeriod'] ?? '',
          'submissionURL': assessment['submissionURL'] ?? '',
          'submissionDate': assessment['submissionDate'] ?? '',
          'assessmentOpenDate': assessment['assessmentOpenDate'] ?? '',
          'assessmentEndDate': assessment['assessmentEndDate'] ?? '',
          'submissionStatus': submissionStatus, 
          'templateTitle': '',
          'supervisorName': '',
          'studentName': '',
        };

        // Fetch template name if templateID exists
        if (assessmentData['templateID'].isNotEmpty) {
          DocumentSnapshot templateSnapshot = await FirebaseFirestore.instance
              .collection('Template')
              .doc(assessmentData['templateID'])
              .get();
          
          if (templateSnapshot.exists) {
            assessmentData['templateTitle'] = templateSnapshot['templateTitle'] ?? '';
          }
        }

        // Retrieve Supervisor userID and fetch Supervisor Name
        if (assessmentData['supervisorID'].isNotEmpty) {
          DocumentSnapshot supervisorSnapshot = await FirebaseFirestore.instance
              .collection('Supervisor')
              .doc(assessmentData['supervisorID'])
              .get();
          
          if (supervisorSnapshot.exists) {
            String userID = supervisorSnapshot['userID'] ?? '';

            if (userID.isNotEmpty) {
              DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
                  .collection('Users')
                  .doc(userID)
                  .get();
              
              if (userSnapshot.exists) {
                assessmentData['supervisorName'] = userSnapshot['name'] ?? '';
              }
            }
          }
        }

        // Retrieve Student userID and fetch Student Name
        if (assessmentData['studID'].isNotEmpty) {
          DocumentSnapshot studentSnapshot = await FirebaseFirestore.instance
              .collection('Student')
              .doc(assessmentData['studID'])
              .get();

          if (studentSnapshot.exists) {
            String userID = studentSnapshot['userID'] ?? '';

            if (userID.isNotEmpty) {
              DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
                  .collection('Users')
                  .doc(userID)
                  .get();
              
              if (userSnapshot.exists) {
                assessmentData['studentName'] = userSnapshot['name'] ?? '';
              }
            }
          }
        }

        assessments.add(assessmentData);
      }

      return assessments;
    } catch (e) {
      print('Error retrieving assessment data: $e');
      return [];
    }
  }
    
  Widget _buildTable(List<Map<String, dynamic>> data) {
    return PaginatedDataTable2(
      columnSpacing: 16,
      dataRowHeight: 70,
      minWidth: 1200,
      dividerThickness: 1.5,
      horizontalMargin: 16,
      headingTextStyle: Theme.of(context).textTheme.titleSmall,
      headingRowDecoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        color: headingRowColor,
      ),
      rowsPerPage: 10,
      showFirstLastButtons: true,
      onRowsPerPageChanged: (noOfRows) {},
      renderEmptyRowsInTheEnd: true,

      columns: const [
        DataColumn(label: Text('Student Name', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Assessment Name', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Intake Period', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Assessment Open Date', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Assessment End Date', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Submission URL', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Submission Date', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Submission Status', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Actions', style: TextStyle(color: Colors.white))),
      ],
      source: AssessmentData(data, context, rowEvenColor, rowOddColor),
    );
  }

  Widget _buildFutureTable({
    required Future<List<Map<String, dynamic>>> future,
    required Widget Function(List<Map<String, dynamic>>) builder,
  }) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No data available'));
        } else {
          return builder(snapshot.data!);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text("Manage Assessment Page"),
        centerTitle: true,
      ),
      drawer: Drawer(
        child: Column(
          children: [
            // User Info Section
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.backgroundCream, AppColors.secondaryYellow],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.account_circle, size: 40, color: AppColors.deepYellow),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          supervisorName,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          supervisorEmail,
                          style: const TextStyle(
                            color: Color.fromARGB(255, 42, 42, 42),
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              EprofileSupervisor(userId: widget.userId),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),
            const Divider(height: 1, thickness: 1, color: AppColors.secondaryYellow),

            // Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(10),
                children: [
                  buildDrawerItem(
                    icon: Icons.dashboard,
                    title: "Dashboard",
                    onTap: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => SupervisorDashboard(userId: widget.userId)),
                    ),
                  ),
                  buildDrawerItem(
                    icon: Icons.task,
                    title: "Manage Assessment Page",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ManageAssessment(userId: widget.userId)),
                    ),
                  ),
                  buildDrawerItem(
                    icon: Icons.upload_file,
                    title: "Download Document Page",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => DownloadGuideline(userId: widget.userId)),
                    ),
                  ),
                ],
              ),
            ),

            // Logout Button
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: ElevatedButton.icon(
                onPressed: logout,
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text("Logout", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  minimumSize: const Size(double.infinity, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),

            // Footer Text
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Supervisor Panel v1.0",
                style: TextStyle(color: Colors.blueGrey[600], fontSize: 12),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.white,
      body: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _refreshData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          elevation: 2,
                        ),
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        label: const Text("Refresh"),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddAssessment(userId: widget.userId),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondaryYellow,
                          foregroundColor: Colors.white,
                          elevation: 2,
                        ),
                        icon: const Icon(Icons.assignment_add, color: Colors.black),
                        label: const Text("Add Assessment", style: TextStyle(color: Colors.black)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: _buildFutureTable(
                    future: _getAssessmentData(),
                    builder: _buildTable,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AssessmentData extends DataTableSource {
  final List<Map<String, dynamic>> data;
  final BuildContext context;
  final Color rowEvenColor;
  final Color rowOddColor;

  AssessmentData(this.data, this.context, this.rowEvenColor, this.rowOddColor);

  @override
  DataRow? getRow(int index) {
    if (index >= data.length) return null;
    final item = data[index];
    final isEven = index % 2 == 0;

    final DateFormat dateFormat = DateFormat('yyyy-MM-dd');

    return DataRow(
      color: WidgetStateProperty.resolveWith(
        (states) => isEven ? rowEvenColor : rowOddColor,
      ),
      cells: [
        DataCell(Text(item['studentName'] ?? '')),
        DataCell(Text(item['templateTitle'] ?? '')),
        DataCell(Text(item['intakePeriod'] ?? '')),
        DataCell(Text(item['assessmentOpenDate'] != null
            ? dateFormat.format((item['assessmentOpenDate'] as Timestamp).toDate())
            : 'N/A')),
        DataCell(Text(item['assessmentEndDate'] != null
            ? dateFormat.format((item['assessmentEndDate'] as Timestamp).toDate())
            : 'N/A')),
        DataCell(
          item['submissionURL'] == null || item['submissionURL'].isEmpty
              ? const Text('') // Display empty text if URL is null or empty
              : InkWell(
                  child: IconButton(
                    icon: const Icon(Icons.download, color: Colors.blue),
                    onPressed: () async {
                      final url = Uri.parse(item['submissionURL']);
                      try {
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Could not open the document')),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    },
                  ),
                ),
        ),
        DataCell(Text(item['submissionDate'] ?? '')), // need to change format later
        DataCell(Text(item['submissionStatus'] ?? '')),
        DataCell(
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditAssessment(assessmentID: item['assessmentID']),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ]);
    }

    @override
    bool get isRowCountApproximate => false;

    @override
    int get rowCount => data.length;

    @override
    int get selectedRowCount => 0;
  }