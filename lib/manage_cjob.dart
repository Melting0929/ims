import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_web.dart';
import 'eprofile_company.dart';
import 'company_dashboard.dart';
import 'manage_applicant.dart';
import 'download_guideline.dart';
import 'add_job.dart';
import 'edit_job.dart';
import 'color.dart';

class ManageCJob extends StatefulWidget {
  final String userId;
  const ManageCJob({super.key, required this.userId});

  @override
  ManageCJobTab createState() => ManageCJobTab();
}

class ManageCJobTab extends State<ManageCJob> {
  String selectedMenu = "Manage Job Posting Page";

  String placementEmail = "Loading...";
  String placementName = "Loading...";
  String companyName = "Loading...";
  String companyIndustry = "Loading...";
  String companyDesc = "Loading...";
  String companyRegNo = "Loading...";
  String placementContactNo = "Loading...";
  String placementJobTitle = "Loading...";
  int companyEmpNo = 0;
  int companyYear = 0;

  String year = '';
  String emp = '';

  final Color headingRowColor = Colors.black;
  final Color rowEvenColor = Colors.grey.shade100;
  final Color rowOddColor = Colors.white;

  List<Map<String, dynamic>> jobData = [];

  String? selectedJobTitle = 'All';
  String? selectedJobStatus = 'All';
  List<String> jobTitles = [];
  List<String> jobStatuses = ["All", "Accepting", "Closed"];

@override
void initState() {
  super.initState();
  fetchCompanyDetails().then((_) {
    fetchJobTitles();
    _refreshData();
  });
}

  Future<void> _refreshData() async {

    List<Map<String, dynamic>> fetchJobData = await _getJobData();

    setState(() {
      jobData = fetchJobData;
    });
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

  Future<void> fetchCompanyDetails() async {
    try {
      var userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists) {
        setState(() {
          placementEmail = userDoc.data()?['email'] ?? 'No Email';
          placementName = userDoc.data()?['name'] ?? 'No Name';
          placementContactNo = userDoc.data()?['contactNo'] ?? 'No Contact No';
        });

        var companyDoc = await FirebaseFirestore.instance
            .collection('Company')
            .where('userID', isEqualTo: widget.userId)
            .get();

        if (companyDoc.docs.isNotEmpty) {
          var companyData = companyDoc.docs.first.data();
          setState(() {
            companyName = companyData['companyName'] ?? 'No Company Name';
            companyIndustry = companyData['companyIndustry'] ?? 'No Company Industry';
            companyDesc = companyData['companyDesc'] ?? 'No Company Desc';
            placementJobTitle = companyData['pContactJobTitle'] ?? 'No Job Title';
            companyRegNo = companyData['companyRegNo'] ?? 'No Company Reg No';
            companyYear = companyData['companyYear'] ?? 'No Company Year';
            companyEmpNo = companyData['companyEmpNo'] ?? 'No Company Emp No';

            emp = companyEmpNo.toString();
            year = companyYear.toString();

          });
        } else {
          debugPrint('No company details found for the userId: ${widget.userId}');
        }
      }
    } catch (e) {
      debugPrint("Error fetching company details: $e");
    }
  }

  Future<void> fetchJobTitles() async {
    QuerySnapshot jobSnapshot = await FirebaseFirestore.instance
        .collection('Job')
        .where('userID', isEqualTo: widget.userId)
        .get();
    setState(() {
      jobTitles = jobSnapshot.docs
          .map((doc) => doc['jobTitle'] as String)
          .toSet()
          .toList();
      jobTitles.insert(0, 'All');
    });
  }

  Future<List<Map<String, dynamic>>> _getJobData() async {
    try {
      QuerySnapshot jobSnapshot = await FirebaseFirestore.instance
      .collection('Job')
      .where('userID', isEqualTo: widget.userId)
      .get();
      List<Map<String, dynamic>> jobs = jobSnapshot.docs.map((doc) {
        return {
          'jobID': doc.id,
          ...doc.data() as Map<String, dynamic>
        };
      }).toList();

      List<Map<String, dynamic>> retrieveJobData = [];

      for (var job in jobs) {
          retrieveJobData.add({
            'jobID': job['jobID'] ?? '',
            'jobTitle': job['jobTitle'] ?? '',
            'jobDesc': job['jobDesc'] ?? '',
            'jobAllowance': job['jobAllowance'] ?? '',
            'jobDuration': job['jobDuration'] ?? '',
            'jobType': job['jobType'] ?? '',
            'program': job['program'] ?? '',
            'jobStatus': job['jobStatus'] ?? '',
            'numApplicant': job['numApplicant'] ?? '',
            'userID': job['userID'],
            'tags': job['tags'] ?? [], 
          });
      }

      return retrieveJobData;
    } catch (e) {
      print('Error retrieving job data: $e');
      return [];
    }
  }

  Widget _buildTable(List<Map<String, dynamic>> data) {
    List<Map<String, dynamic>> filteredJobs = jobData.where((job) {
      final titleMatch = selectedJobTitle == null || selectedJobTitle == "All" || job['jobTitle'] == selectedJobTitle;
      final statusMatch = selectedJobStatus == null || selectedJobStatus == "All" || job['jobStatus'] == selectedJobStatus;
      return titleMatch && statusMatch;
    }).toList();

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

      columns:  const [
        DataColumn(label: Text('Job ID', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Job Title', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Job Description', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Job Allowance', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Job Duration', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Desired Program', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Job Status', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Number of\nApplicant Needed', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Tags', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Action', style: TextStyle(color: Colors.white))),
      ],
      source: JobData(filteredJobs, context, rowEvenColor, rowOddColor, _refreshData), 
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
    return  Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text("Manage Job Posting Page"),
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
                          placementName,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          placementEmail,
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
                              EprofileCompany(userId: widget.userId),
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
                "Company Panel v1.0",
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
                        onPressed: () async{
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddJob(userId: widget.userId, refreshCallback: _refreshData),
                            ),
                          );
                          if (result == true) {
                            _refreshData(); // Refresh data when returning from the update page
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondaryYellow,
                          foregroundColor: Colors.white,
                          elevation: 2,
                        ),
                        icon: const Icon(Icons.assignment_add, color: Colors.black),
                        label: const Text("Add Job Posting", style: TextStyle(color: Colors.black)),
                      ),
                    ], 
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text(
                      "Job Titles:",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black, width: 1.5),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedJobTitle,
                          onChanged: (value) {
                            setState(() {
                              selectedJobTitle = value;
                            });
                          },
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                          dropdownColor: Colors.white,
                          style: const TextStyle(color: Colors.black, fontSize: 14),
                          items: jobTitles.map((title) {
                            return DropdownMenuItem<String>(
                              value: title,
                              child: Text(title),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      "Job Status:",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black, width: 1.5),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedJobStatus,
                          onChanged: (newValue) {
                            setState(() {
                              selectedJobStatus = newValue;
                            });
                          },
                          items: jobStatuses.map((status) {
                            return DropdownMenuItem(
                              value: status,
                              child: Text(status),
                            );
                          }).toList(),
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                          dropdownColor: Colors.white,
                          style: const TextStyle(color: Colors.black, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _buildFutureTable(
                    future: _getJobData(),
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

class JobData extends DataTableSource {
  final List<Map<String, dynamic>> data;
  final BuildContext context;
  final Color rowEvenColor;
  final Color rowOddColor;
  final VoidCallback refreshCallback;

  JobData(this.data, this.context, this.rowEvenColor, this.rowOddColor, this.refreshCallback);

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
        DataCell(Text(item['program'] ?? '')),
        DataCell(Text(item['jobStatus'] ?? '')),
        DataCell(Text(item['numApplicant'].toString())),
        DataCell(Text((item['tags'] as List<dynamic>).join(', '))),
        DataCell(
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditJob(jobId: jobID, refreshCallback: refreshCallback,),
                  ),
                );
                if (result == true) {
                  refreshCallback(); // Refresh data when returning from the update page
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