import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_web.dart';
import 'eprofile_admin.dart';
import 'admin_dashboard.dart';
import 'manage_application.dart';
import 'manage_user.dart';
import 'upload_guideline.dart';
import 'add_job.dart';
import 'edit_job.dart';
import 'color.dart';

// Dropdown Menu
class ManageJob extends StatefulWidget {
  final String userId;
  const ManageJob({super.key, required this.userId});

  @override
  ManageJobTab createState() => ManageJobTab();
}

class ManageJobTab extends State<ManageJob> {
  String selectedMenu = "Manage Job Posting Page";
  String adminEmail = "Loading...";
  String adminName = "Loading...";
  final List<String> tabs = ['External Company', 'Registered Company'];
  final Color headingRowColor = Colors.black;
  final Color rowEvenColor = Colors.grey.shade100;
  final Color rowOddColor = Colors.white;

  List<Map<String, dynamic>> externalData = [];
  List<Map<String, dynamic>> registeredData = [];

  String? selectedJobTitle;
  String? selectedJobStatus;

@override
void initState() {
  super.initState();
  fetchAdminDetails();
}

  Future<void> _refreshData() async {

    List<Map<String, dynamic>> fetchAdminData = await _getExternalData();
    List<Map<String, dynamic>> fetchCompanyData = await _getRegisteredData();

    setState(() {
      externalData = fetchAdminData;
      registeredData = fetchCompanyData;
    });
  }

  Future<void> fetchAdminDetails() async {
    try {
      var adminDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.userId)
          .get();

      if (adminDoc.exists) {
        setState(() {
          adminEmail = adminDoc.data()?['email'] ?? 'No Email';
          adminName = adminDoc.data()?['name'] ?? 'No Name';
        });
      }
    } catch (e) {
      debugPrint("Error fetching admin details: $e");
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

  Future<List<Map<String, dynamic>>> _getExternalData() async {
    try {
      QuerySnapshot jobSnapshot = await FirebaseFirestore.instance.collection('Job').get();
      List<Map<String, dynamic>> externals = jobSnapshot.docs.map((doc) {
        return {
          'jobID': doc.id,
          ...doc.data() as Map<String, dynamic>
        };
      }).toList();

      List<Map<String, dynamic>> retrieveExternalData = [];

      for (var external in externals) {
        var jobID = external['jobID'];
        var userID = external['userID'];

        var userSnapshot = await FirebaseFirestore.instance.collection('Users').doc(userID).get();
        if (!userSnapshot.exists) {
          print('User not found: $userID');
          continue;
        }
        var user = userSnapshot.data() as Map<String, dynamic>;
        var userType = user['userType'];
        var name = user['name'];

        if (userType == 'Admin') {
          retrieveExternalData.add({
            'jobID': jobID,
            'jobTitle': external['jobTitle'] ?? '',
            'jobDesc': external['jobDesc'] ?? '',
            'jobAllowance': external['jobAllowance'] ?? '',
            'jobDuration': external['jobDuration'] ?? '',
            'jobType': external['jobType'] ?? '',
            'jobStatus': external['jobStatus'] ?? '',
            'numApplicant': external['numApplicant'] ?? '',
            'userID': userID,
            'name': name,
            'tags': external['tags'] ?? [], 
          });
        }
      }

      return retrieveExternalData;
    } catch (e) {
      print('Error retrieving external job data: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getRegisteredData() async {
    try {
      QuerySnapshot jobSnapshot = await FirebaseFirestore.instance.collection('Job').get();
      List<Map<String, dynamic>> registered = jobSnapshot.docs.map((doc) {
        return {
          'jobID': doc.id,
          ...doc.data() as Map<String, dynamic>
        };
      }).toList();

      List<Map<String, dynamic>> retrieveRegisteredData = [];

      for (var register in registered) {
        var jobID = register['jobID'];
        var userID = register['userID'];

        var userSnapshot = await FirebaseFirestore.instance.collection('Users').doc(userID).get();
        
        var user = userSnapshot.data() as Map<String, dynamic>;
        var userType = user['userType'];

        var companySnapshot = await FirebaseFirestore.instance
            .collection('Company')
            .where('userID', isEqualTo: userID)
            .get();

        var company = companySnapshot.docs.isNotEmpty
            ? companySnapshot.docs.first.data()
            : null;
        var name = company != null ? company['companyName'] : 'Unknown';

        if (userType == 'Company'){
          retrieveRegisteredData.add({
            'jobID': jobID,
            'jobTitle': register['jobTitle'] ?? '',
            'jobDesc': register['jobDesc'] ?? '',
            'jobAllowance': register['jobAllowance'] ?? '',
            'jobDuration': register['jobDuration'] ?? '',
            'jobType': register['jobType'] ?? '',
            'jobStatus': register['jobStatus'] ?? '',
            'numApplicant': register['numApplicant'] ?? '',
            'userID': userID,
            'name': name,
            'tags': register['tags'] ?? [], 
          });
        }
      }

      return retrieveRegisteredData;
    } catch (e) {
      print('Error retrieving external job data: $e');
      return [];
    }
  }

  // Build Student DataTable
  Widget _buildTable(List<Map<String, dynamic>> data) {
    return PaginatedDataTable2(
      columnSpacing: 16,
      dataRowHeight: 70,
      minWidth: 1300,
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

      columns:  const [
        DataColumn(label: Text('Job ID', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Job Title', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Job Description', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Job Allowance', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Job Duration', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Job Type', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Job Status', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Number of\nApplicant Needed', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Tags', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('User Created', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Action', style: TextStyle(color: Colors.white))),
      ],
      source: JobData(data, context, rowEvenColor, rowOddColor), 
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

  Widget _buildTab({
    required String title,
    required VoidCallback onAdd,
    required VoidCallback onRefresh,
    required Future<List<Map<String, dynamic>>> future,
    required Widget Function(List<Map<String, dynamic>>) builder,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  bool isSmallScreen = constraints.maxWidth < 600;
                  return isSmallScreen
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              title,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: onRefresh,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    foregroundColor: Colors.white,
                                    elevation: 2,
                                  ),
                                  icon: const Icon(Icons.refresh, color: Colors.white),
                                  label: const Text("Refresh"),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton.icon(
                                  onPressed: onAdd,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.secondaryYellow,
                                    foregroundColor: Colors.white,
                                    elevation: 2,
                                  ),
                                  icon: const Icon(Icons.assignment_add, color: Colors.black),
                                  label: const Text("Add Job", style: TextStyle(color: Colors.black)),
                                ),
                              ],
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              title,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: onRefresh,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    foregroundColor: Colors.white,
                                    elevation: 2,
                                  ),
                                  icon: const Icon(Icons.refresh, color: Colors.white),
                                  label: const Text("Refresh"),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton.icon(
                                  onPressed: onAdd,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.secondaryYellow,
                                    foregroundColor: Colors.white,
                                    elevation: 2,
                                  ),
                                  icon: const Icon(Icons.assignment_add, color: Colors.black),
                                  label: const Text("Add Job", style: TextStyle(color: Colors.black)),
                                ),
                              ],
                            ),
                          ],
                        );
                },
              ),
            ),
          ),
        ),
        Expanded(
          child: _buildFutureTable(
            future: future,
            builder: builder,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: const Text("Manage Job Posting Page"),
          bottom:TabBar(
            tabs: tabs.map((tab) => Tab(text: tab)).toList(),
          ),
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
                            adminName,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            adminEmail,
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
                                EprofileAdmin(userId: widget.userId),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),
              const Divider(height: 1, thickness: 1, color: AppColors.secondaryYellow),

              // Drawer Items
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(10),
                  children: [
                    buildDrawerItem(
                      icon: Icons.dashboard,
                      title: "Dashboard",
                      onTap: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => AdminDashboard(userId: widget.userId)),
                      ),
                    ),
                    buildDrawerItem(
                      icon: Icons.people,
                      title: "Manage User Page",
                      onTap: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => ManageUser(userId: widget.userId)),
                      ),
                    ),
                    buildDrawerItem(
                      icon: Icons.work,
                      title: "Manage Job Posting Page",
                      onTap: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => ManageJob(userId: widget.userId)),
                      ),
                    ),
                    buildDrawerItem(
                      icon: Icons.upload_file,
                      title: "Upload Document Page",
                      onTap: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => UploadGuideline(userId: widget.userId)),
                      ),
                    ),buildDrawerItem(
                      icon: Icons.manage_accounts,
                      title: "Manage Application Page",
                      onTap: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => ManageApplication(userId: widget.userId)),
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

              // Footer Section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Admin Panel v1.0",
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
              child: TabBarView(
                children: [
                   _buildTab(
                    title: "Manage External Jobs",
                    onAdd: () => 
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddJob(userId: widget.userId),
                      ),
                    ),
                    onRefresh: _refreshData,
                    future: _getExternalData(),
                    builder: _buildTable,
                  ),
                  _buildTab(
                    title: "Manage Registered Companies Job",
                    onAdd: () => 
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddJob(userId: widget.userId),
                      ),
                    ),
                    onRefresh: _refreshData,
                    future: _getRegisteredData(),
                    builder: _buildTable,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class JobData extends DataTableSource {
  final List<Map<String, dynamic>> data;
  final BuildContext context;
  final Color rowEvenColor;
  final Color rowOddColor;

  JobData(this.data, this.context, this.rowEvenColor, this.rowOddColor);

  @override
  DataRow? getRow(int index) {
    if (index >= data.length) return null;
    final item = data[index];
    final isEven = index % 2 == 0;
    String jobID = item['jobID'];

    return DataRow(
      color: WidgetStateProperty.resolveWith(
        (states) => isEven ? rowEvenColor : rowOddColor,
      ),
      cells: [
        DataCell(Text(item['jobID'] ?? '')),
        DataCell(Text(item['jobTitle'] ?? '')),
        DataCell(Text(item['jobDesc'] ?? '')),
        DataCell(Text(item['jobAllowance'].toString())),
        DataCell(Text(item['jobDuration'].toString())),
        DataCell(Text(item['jobType'] ?? '')),
        DataCell(Text(item['jobStatus'] ?? '')),
        DataCell(Text(item['numApplicant'].toString())),
        DataCell(Text((item['tags'] as List<dynamic>).join(', '))),
        DataCell(Text(item['name'] ?? '')),
        DataCell(
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditJob(jobId: jobID),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                final jobID = item['jobID'] ?? '';

                final confirm = await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Confirm Delete'),
                    content: Text('Are you sure you want to delete job $jobID?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await deleteJob(context, jobID);

                  data.removeWhere((element) => element['jobID'] == jobID);
                  notifyListeners();
                }
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

Future<void> deleteJob(BuildContext context, String jobID) async {
  try {
    await FirebaseFirestore.instance
        .collection('Job')
        .doc(jobID)
        .delete();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Job $jobID deleted successfully!')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error deleting job: $e')),
    );
  }
}