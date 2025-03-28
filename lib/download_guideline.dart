import 'package:url_launcher/url_launcher.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_web.dart';
import 'company_dashboard.dart';
import 'student_dashboard.dart';
import 'supervisor_dashboard.dart';
import 'manage_cjob.dart';
import 'manage_applicant.dart';
import 'manage_assessment.dart';
import 'apply_external.dart';
import 'eprofile_student.dart';
import 'eprofile_supervisor.dart';
import 'eprofile_company.dart';
import 'color.dart';

// Check Drawer
class DownloadGuideline extends StatefulWidget {
  final String userId;
  const DownloadGuideline ({super.key, required this.userId});

  @override
  DownloadGuidelineTab createState() => DownloadGuidelineTab();
}

class DownloadGuidelineTab extends State<DownloadGuideline> {
  String email = "Loading...";
  String name = "Loading...";
  String userType = "Loading...";
  String selectedMenu = "Download Document Page";

  final Color headingRowColor = Colors.black;
  final Color rowEvenColor = Colors.grey.shade100;
  final Color rowOddColor = Colors.white;

  List<Map<String, dynamic>> docData = [];


  @override
  void initState() {
    super.initState();
    fetchUserDetails();
  }

  Future<void> fetchUserDetails() async {
    try {
      var userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists) {
        setState(() {
          email = userDoc.data()?['email'] ?? 'No Email';
          name = userDoc.data()?['name'] ?? 'No Name';
          userType = userDoc.data()?['userType'] ?? 'No User Type';
        });
      }
    } catch (e) {
      debugPrint("Error fetching user details: $e");
    }
  }

  Future<List<Map<String, dynamic>>> _getDocData() async {
    try {
      QuerySnapshot docSnapshot = await FirebaseFirestore.instance
      .collection('Guideline')
      .where('accessType', isEqualTo: userType)
      .get();
      
      // Combine document data with the document ID
      List<Map<String, dynamic>> guidelines = docSnapshot.docs.map((doc) {
        return {
          'docID': doc.id,
          'title': doc['title'] ?? '',
          'guidelineURL': doc['guidelineURL'] ?? '',
          'desc': doc['desc'] ?? '',
        };
      }).toList();

      return guidelines;
    } catch (e) {
      print('Error retrieving guideline data: $e');
      return [];
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
  
  // Function to get Drawer Items based on userType
  List<Widget> getDrawerItems(BuildContext context, String userType) {
    switch (userType) {
      case 'Student':
        return [
          buildDrawerItem(
            icon: Icons.dashboard,
            title: "Dashboard",
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => StudentDashboard(userId: widget.userId)),
            ),
          ),
          buildDrawerItem(
            icon: Icons.upload_file,
            title: "Apply External Company Page",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddExternal(userId: widget.userId)),
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
        ];

      case 'Company':
        return [
          buildDrawerItem(
            icon: Icons.dashboard,
            title: "Dashboard",
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => CompanyDashboard(userId: widget.userId)),
            ),
          ),
          buildDrawerItem(
            icon: Icons.people,
            title: "Manage Applicant Page",
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ManageApplicant(userId: widget.userId)),
            ),
          ),
          buildDrawerItem(
            icon: Icons.work,
            title: "Manage Job Posting Page",
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ManageCJob(userId: widget.userId)),
            ),
          ),
          buildDrawerItem(
            icon: Icons.upload_file,
            title: "Download Document Page",
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => DownloadGuideline(userId: widget.userId)),
            ),
          ),
        ];

      case 'Supervisor':
        return [
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
        ];

      default:
        return [
          const ListTile(
            title: Text("No specific menu available"),
          ),
        ];
    }
  }

  void _navigateToEditProfile(BuildContext context, String userType) {
    if (userType == 'Student'){
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EprofileStudent(userId: widget.userId),
        ),
      );
    } else if (userType == 'Supervisor') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EprofileSupervisor(userId: widget.userId),
        ),
      );
    } else if (userType == 'Company') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EprofileCompany(userId: widget.userId),
        ),
      );
    }
  }

  Widget footerText(String userType) {
    String footerMessage;

    switch (userType) {
      case "Student":
        footerMessage = "Student Dashboard v1.0";
        break;
      case "Company":
        footerMessage = "Company Portal v1.0";
        break;
      case "Supervisor":
        footerMessage = "Supervisor Panel v1.0";
        break;
      default:
        footerMessage = "Error User Type";
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        footerMessage,
        style: TextStyle(color: Colors.blueGrey[600], fontSize: 12),
      ),
    );
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
        DataColumn(label: Text('Guideline ID', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Guideline Title', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Guideline Description', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Guideline URL', style: TextStyle(color: Colors.white))),
      ],
      source: GuidelineData(data, context, rowEvenColor, rowOddColor),
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
        title: const Text("Download Guideline Page"),
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
                          name,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          email,
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
                    onPressed: () => _navigateToEditProfile(context, userType),
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
                children: getDrawerItems(context, userType),
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

            footerText(userType),
          ],
        ),
      ),
      body: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: _buildFutureTable(
                    future: _getDocData(),
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

class GuidelineData extends DataTableSource {
  final List<Map<String, dynamic>> data;
  final BuildContext context;
  final Color rowEvenColor;
  final Color rowOddColor;

  GuidelineData(this.data, this.context, this.rowEvenColor, this.rowOddColor);

  @override
  DataRow? getRow(int index) {
    if (index >= data.length) return null;
    final item = data[index];
    final isEven = index % 2 == 0;

    return DataRow(
      color: WidgetStateProperty.resolveWith(
        (states) => isEven ? rowEvenColor : rowOddColor,
      ),
      cells: [
        DataCell(Text(item['docID'] ?? '')),
        DataCell(Text(item['title'] ?? '')),
        DataCell(Text(item['desc'] ?? '')),
        DataCell(
          InkWell(
            child: IconButton(
              icon: const Icon(Icons.download, color: Colors.blue),
              onPressed: () async {
                final url = Uri.parse(item['guidelineURL']);
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
      ]);
    }

    @override
    bool get isRowCountApproximate => false;

    @override
    int get rowCount => data.length;

    @override
    int get selectedRowCount => 0;
  }