import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_web.dart';
import 'eprofile_company.dart';
import 'company_dashboard.dart';
import 'download_guideline.dart';
import 'manage_cjob.dart';
import 'color.dart';

// Dropdown Button 'None' for Interview Status Used or Not Used
class ManageApplicant extends StatefulWidget {
  final String userId;
  const ManageApplicant({super.key, required this.userId});

  @override
  ManageApplicantTab createState() => ManageApplicantTab();
}

class ManageApplicantTab extends State<ManageApplicant> {
  String selectedMenu = "Manage Applicant Page";
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

  List<Map<String, dynamic>> applicantData = [];

  String? selectedJobTitle = 'All';
  String selectedApplicationStatus = 'All';
  String selectedInterviewStatus = 'All';

  List<String> jobTitles = [];


@override
void initState() {
  super.initState();
  fetchCompanyDetails().then((_) {
    fetchJobTitles();
    _refreshData();
  });
}

  Future<void> _refreshData() async {
    List<Map<String, dynamic>> fetchApplicantData = await _getApplicantData();

    setState(() {
      applicantData = fetchApplicantData;
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
    try {
      QuerySnapshot jobSnapshot = await FirebaseFirestore.instance
          .collection('Job')
          .where('userID', isEqualTo: widget.userId)
          .get();

      List<String> titles = jobSnapshot.docs
          .map((doc) => doc['jobTitle'] as String)
          .toSet()
          .toList();

      setState(() {
        jobTitles = titles;
        jobTitles.insert(0, 'All');
      });
    } catch (e) {
      debugPrint("Error fetching job titles: $e");
    }
  }

  Future<List<Map<String, dynamic>>> _getApplicantData() async {
    try {
      QuerySnapshot applicantSnapshot = await FirebaseFirestore.instance
          .collection('Application')
          .get();

      List<Map<String, dynamic>> applications = applicantSnapshot.docs.map((doc) {
        return {
          'applicationID': doc.id,
          ...doc.data() as Map<String, dynamic>
        };
      }).toList();

      List<Map<String, dynamic>> applicant = [];

      for (var application in applications) {
        var jobID = application['jobID'];

        var jobSnapshot =
            await FirebaseFirestore.instance.collection('Job').doc(jobID).get();
        if (!jobSnapshot.exists) continue;
        var job = jobSnapshot.data() as Map<String, dynamic>;

        if (job['userID'] != widget.userId) continue;

        var studID = application['studID'];
        var studentSnapshot = await FirebaseFirestore.instance.collection('Student').doc(studID).get();
        if (!studentSnapshot.exists) continue;
        var student = studentSnapshot.data() as Map<String, dynamic>;

        var userID = student['userID'];
        var userSnapshot = await FirebaseFirestore.instance.collection('Users').doc(userID).get();
        if (!userSnapshot.exists) continue;
        var user = userSnapshot.data() as Map<String, dynamic>;

        Map<String, dynamic> applicanttData = {
          'applicationID': application['applicationID'] ?? '',
          'studName': user['name'] ?? '',
          'jobTitle': job['jobTitle'] ?? '',
          'jobDesc': job['jobDesc'] ?? '',
          'jobAllowance': job['jobAllowance'] ?? '',
          'applicationStatus': application['applicationStatus'] ?? '',
          'interviewStatus': application['interviewStatus'] ?? '',
        };

        if ((selectedJobTitle == 'All' || applicanttData['jobTitle'] == selectedJobTitle) &&
            (selectedApplicationStatus == 'All' || applicanttData['applicationStatus'] == selectedApplicationStatus) &&
            (selectedInterviewStatus == 'All' || applicanttData['interviewStatus'] == selectedInterviewStatus)) {
          applicant.add(applicanttData);
        }
      }

      return applicant;
    } catch (e) {
      print('Error retrieving application data: $e');
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

      columns:  const [
        DataColumn(label: Text('Applicant Name', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Job Title', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Job Description', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Job Allowance', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Application Status', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Interview Status', style: TextStyle(color: Colors.white))),
      ],
      source: ApplicantData(data, context, rowEvenColor, rowOddColor), 
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
        title: const Text("Manage Applicant Page"),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
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
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Job Title Dropdown
                const Text(
                  "Job Title:",
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
                        _refreshData();
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
                const SizedBox(width: 30),

                // Application Status Dropdown
                const Text(
                  "Application Status:",
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
                      value: selectedApplicationStatus,
                      onChanged: (value) {
                        setState(() {
                          selectedApplicationStatus = value!;
                        });
                        _refreshData();
                      },
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                      dropdownColor: Colors.white,
                      style: const TextStyle(color: Colors.black, fontSize: 14),
                      items: ['All', 'Pending', 'Rejected', 'Accepted'].map((status) {
                        return DropdownMenuItem<String>(
                          value: status,
                          child: Text(status),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 30),

                // Interview Status Dropdown
                const Text(
                  "Interview Status:",
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
                      value: selectedInterviewStatus,
                      onChanged: (value) {
                        setState(() {
                          selectedInterviewStatus = value!;
                        });
                        _refreshData();
                      },
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                      dropdownColor: Colors.white,
                      style: const TextStyle(color: Colors.black, fontSize: 14),
                      items: ['All', 'Pending', 'Rejected', 'Accepted', 'None'].map((status) {
                        return DropdownMenuItem<String>(
                          value: status,
                          child: Text(status),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ), 
            const SizedBox(height: 30),
            // Table section
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black,
                      blurRadius: 3,
                      spreadRadius: 2,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(8.0),
                child: _buildFutureTable(
                  future: _getApplicantData(),
                  builder: _buildTable,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ApplicantData extends DataTableSource {
  final List<Map<String, dynamic>> data;
  final BuildContext context;
  final Color rowEvenColor;
  final Color rowOddColor;

  ApplicantData(this.data, this.context, this.rowEvenColor, this.rowOddColor);

  Future<void> updateApplicationStatus(String docId, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('Application')
          .doc(docId)
          .update({
        'applicationStatus': status,
        if (status == 'Accepted') 'interviewStatus': 'Pending',
        if (status == 'Rejected') 'interviewStatus': 'None',
      });

      final index = data.indexWhere((item) => item['applicationID'] == docId);
      if (index != -1) {
        data[index]['applicationStatus'] = status;
        if (status == 'Accepted') {
          data[index]['interviewStatus'] = 'Pending';
        }
      }

      notifyListeners();
    } catch (e) {
      print('Error updating status: $e');
    }
  }

  Future<void> updateInterviewStatus(String docId, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('Application')
          .doc(docId)
          .update({'interviewStatus': status});

      final index = data.indexWhere((item) => item['applicationID'] == docId);
      if (index != -1) {
        data[index]['interviewStatus'] = status;
      }

      notifyListeners();
    } catch (e) {
      print('Error updating interview status: $e');
    }
  }

  // Function to show confirmation dialog
  void _showEditDialog(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update Interview Status'),
          content: const Text('Would you like to set the interview status to Accepted or Rejected?'),
          actions: [
            TextButton(
              onPressed: () {
                updateInterviewStatus(docId, 'Accepted');
                Navigator.of(context).pop();
              },
              child: const Text('Accepted'),
            ),
            TextButton(
              onPressed: () {
                updateInterviewStatus(docId, 'Rejected');
                Navigator.of(context).pop();
              },
              child: const Text('Rejected'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

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
        DataCell(Text(item['studName'] ?? '')),
        DataCell(Text(item['jobTitle'] ?? '')),
        DataCell(Text(item['jobDesc'] ?? '')),
        DataCell(Text(item['jobAllowance'].toString())),
        DataCell(
          item['applicationStatus'] == 'Pending'
              ? Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        updateApplicationStatus(item['applicationID'], 'Accepted');
                      },
                      child: const Text('Accept'),
                    ),
                    const Text(' | '),
                    TextButton(
                      onPressed: () {
                        updateApplicationStatus(item['applicationID'], 'Rejected');
                      },
                      child: const Text('Reject'),
                    ),
                  ],
                )
              : Text(item['applicationStatus'] ?? ''),
        ),
        DataCell(
          Row(
            children: [
              Text(item['interviewStatus'] ?? ''),
              if (item['interviewStatus'] == 'Pending') ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                  onPressed: () {
                    _showEditDialog(context, item['applicationID']);
                  },
                ),
              ]
            ],
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => data.length;

  @override
  int get selectedRowCount => 0;
}
