import 'package:data_table_2/data_table_2.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_web.dart';
import 'eprofile_admin.dart';
import 'admin_dashboard.dart';
import 'manage_application.dart';
import 'manage_user.dart';
import 'upload_guideline.dart';
//import 'add_job.dart';
import 'edit_job.dart';
import 'color.dart';

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
  
  List<String> jobRegisterTitles = [];
  List<String> studentLists = [];
  List<String> comRegisterTitles = [];

  String selectedApproval = 'All';
  String selectedIDs = 'All';

  String selectedRJobTitle = 'All';
  String selectedRJobStatus = 'All';
  String selectedRegistered = 'All';

@override
void initState() {
  super.initState();
  fetchAdminDetails().then((_) {
    fetchJobTitles();
    fetchCompanyNames();
    fetchStudentIDs();
  });
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
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginWeb()),
        (Route<dynamic> route) => false, // removes all previous routes
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

  Future<void> fetchJobTitles() async {
    QuerySnapshot rejobSnapshot = await FirebaseFirestore.instance
        .collection('Job')
        .where('jobType', isEqualTo: 'Registered')
        .get();
    setState(() {
      jobRegisterTitles = rejobSnapshot.docs
          .map((doc) => doc['jobTitle'] as String)
          .toSet()
          .toList();
      jobRegisterTitles.insert(0, 'All');
    });
  }

  Future<void> fetchCompanyNames() async {
    QuerySnapshot recompanySnapshot = await FirebaseFirestore.instance
        .collection('Company')
        .where('companyType', isEqualTo: 'Registered')
        .get();
    setState(() {
      comRegisterTitles = recompanySnapshot.docs
          .map((doc) => doc['companyName'] as String)
          .toSet()
          .toList();
      comRegisterTitles.insert(0, 'All');
    });
  }
  
  Future<void> fetchStudentIDs() async {
    QuerySnapshot recompanySnapshot = await FirebaseFirestore.instance
        .collection('Student')
        .get();
    setState(() {
      studentLists = recompanySnapshot.docs
          .map((doc) => doc['studID'] as String)
          .toSet()
          .toList();
      studentLists.insert(0, 'All');
    });
  }

  Future<List<Map<String, dynamic>>> _getExternalData() async {
    try {
      QuerySnapshot externalSnapshot = await FirebaseFirestore.instance
      .collection('External')
      .get();

      List<Map<String, dynamic>> externals = externalSnapshot.docs.map((doc) {
        return {
          'externalID': doc.id,
          ...doc.data() as Map<String, dynamic>
        };
      }).toList();

      List<Map<String, dynamic>> retrieveExternalData = [];

      for (var external in externals) {
          Map<String, dynamic> externalData = {
            'studID': external['studID'] ?? '',
            'externalID': external['externalID'] ?? '',
            'exCompName': external['exCompName'] ?? '',
            'exCompEmail': external['exCompEmail'] ?? '',
            'exCompAddress': external['exCompAddress'] ?? '',
            'exCompRegNo': external['exCompRegNo'] ?? '',
            'exCompYear': external['exCompYear'] ?? '',
            'exJobTitle': external['exJobTitle'] ?? '',
            'exJobDuration': external['exJobDuration'] ?? '',
            'offerLetter': external['offerLetter'] ?? '',
            'exComIndustry': external['exComIndustry'],
            'externalStatus': external['externalStatus'] ?? '',
            'placementContactName': external['placementContactName'] ?? '',
            'placementContactEmail': external['placementContactEmail'] ?? '',
            'placementContactNo': external['placementContactNo'] ?? '',
            'placementContactJobTitle': external['placementContactJobTitle'] ?? '',
          };

          if ((selectedApproval == 'All' || externalData['externalStatus'] == selectedApproval) &&
              (selectedIDs == 'All' || externalData['studID'] == selectedIDs)) {
          retrieveExternalData.add(externalData);
        }
      }

      return retrieveExternalData;
    } catch (e) {
      print('Error retrieving external data: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getRegisteredData() async {
    try {
      QuerySnapshot jobSnapshot = await FirebaseFirestore.instance
          .collection('Job')
          .where('jobType', isEqualTo: 'Registered')
          .get();
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
        var companyID = register['companyID'];

        var userSnapshot = await FirebaseFirestore.instance
            .collection('Users')
            .doc(userID)
            .get();
        if (!userSnapshot.exists) {
          print('User not found: $userID');
          continue;
        }
        var user = userSnapshot.data() as Map<String, dynamic>;
        var name = user['name'];

        var recompanySnapshot = await FirebaseFirestore.instance
            .collection('Company')
            .doc(companyID)
            .get();
        if (!recompanySnapshot.exists) {
          print('Company not found: $companyID');
          continue;
        }
        var company = recompanySnapshot.data() as Map<String, dynamic>;
        var companyName = company['companyName'];

        Map<String, dynamic> registerData = {
          'jobID': jobID,
          'jobTitle': register['jobTitle'] ?? '',
          'jobDesc': register['jobDesc'] ?? '',
          'jobAllowance': register['jobAllowance'] ?? '',
          'jobDuration': register['jobDuration'] ?? '',
          'jobStatus': register['jobStatus'] ?? '',
          'location': register['location'] ?? '',
          'userID': userID,
          'name': name,
          'companyName': companyName,
          'tags': register['tags'] ?? [], 
        };

        if ((selectedRJobTitle == 'All' || registerData['jobTitle'] == selectedRJobTitle) && 
            (selectedRJobStatus == 'All' || registerData['jobStatus'] == selectedRJobStatus) &&
            (selectedRegistered == 'All' || registerData['companyName'] == selectedRegistered)) {
          retrieveRegisteredData.add(registerData);
        }
      }
      return retrieveRegisteredData;
    } catch (e) {
      print('Error retrieving registered job data: $e');
      return [];
    }
  }

  Widget _buildRegisteredTable(List<Map<String, dynamic>> data) {
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
      rowsPerPage: 5,
      showFirstLastButtons: true,
      renderEmptyRowsInTheEnd: true,

      columns:  const [
        DataColumn(label: Text('Job ID', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Job Title', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Job Description', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Job Allowance', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Job Duration', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Job Status', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Location', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Tags', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Company', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('User Created', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Action', style: TextStyle(color: Colors.white))),
      ],
      source: JobData(data, context, rowEvenColor, rowOddColor, _refreshData), 
    );
  }

  Widget _buildExternalTable(List<Map<String, dynamic>> data) {
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
      rowsPerPage: 5,
      showFirstLastButtons: true,
      renderEmptyRowsInTheEnd: true,

      columns:  const [
        DataColumn(label: Text('Student\nApply', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Company\nName', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Company\nEmail', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Company\nReg No', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Job Title', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Job\nDuration', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Placement\nContact Name', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Placement\nContact Email', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Placement Contact\nContact No.', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Offer Letter', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Status', style: TextStyle(color: Colors.white))),
      ],
      source: ExternalData(data, context, rowEvenColor, rowOddColor, _refreshData), 
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
    List<Widget>? dropdowns,
    bool showAddButton = true,
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
                                /*if (showAddButton) ...[
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
                              ],*/
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
                                /*if (showAddButton) ...[
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
                              ],*/
                            ],
                          ),
                        ],
                      );
                },
              ),
            ),
          ),
        ),
        if (dropdowns != null) 
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: dropdowns,
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

  /*Future<void> _navigateToAddJob(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddJob(userId: widget.userId, refreshCallback: _refreshData),
      ),
    );

    if (result == true) {
      _refreshData(); // Refresh data when returning from the update page
    }
  }*/

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.backgroundCream,
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
        backgroundColor: AppColors.backgroundCream,
        body: Row(
          children: [
            Expanded(
              child: TabBarView(
                children: [
                   _buildTab(
                    title: "Manage External Jobs",
                    onAdd: () {},
                    onRefresh: _refreshData,
                    future: _getExternalData(),
                    builder: _buildExternalTable,
                    dropdowns: [
                      const Text(
                        "Student ID:",
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
                            value: selectedIDs,
                            onChanged: (value) {
                              setState(() {
                                selectedIDs = value!;
                              });
                            },
                            icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                            dropdownColor: Colors.white,
                            style: const TextStyle(color: Colors.black, fontSize: 14),
                            items: studentLists.map((title) {
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
                        "Approval:",
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
                            value: selectedApproval,
                            onChanged: (value) {
                              setState(() {
                                selectedApproval = value!;
                              });
                            },
                            icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                            dropdownColor: Colors.white,
                            style: const TextStyle(color: Colors.black, fontSize: 14),
                            items: ['All', 'Approved', 'Pending', 'Rejected'].map((title) {
                              return DropdownMenuItem<String>(
                                value: title,
                                child: Text(title),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ]
                  ),
                  _buildTab(
                    title: "Manage Registered Companies Job",
                    onAdd: () {},
                    onRefresh: _refreshData,
                    future: _getRegisteredData(),
                    builder: _buildRegisteredTable,
                    dropdowns: [
                      const Text(
                        "Company Name:",
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
                            value: selectedRegistered,
                            onChanged: (value) {
                              setState(() {
                                selectedRegistered = value!;
                              });
                            },
                            icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                            dropdownColor: Colors.white,
                            style: const TextStyle(color: Colors.black, fontSize: 14),
                            items: comRegisterTitles.map((title) {
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
                            value: selectedRJobTitle,
                            onChanged: (value) {
                              setState(() {
                                selectedRJobTitle = value!;
                              });
                            },
                            icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                            dropdownColor: Colors.white,
                            style: const TextStyle(color: Colors.black, fontSize: 14),
                            items: jobRegisterTitles.map((title) {
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
                            value: selectedRJobStatus,
                            onChanged: (newValue) {
                              setState(() {
                                selectedRJobStatus = newValue!;
                              });
                            },
                            items: ["All", "Accepting", "Closed"].map((status) {
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
                    showAddButton: false,
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

class ExternalData extends DataTableSource {
  final List<Map<String, dynamic>> data;
  final BuildContext context;
  final Color rowEvenColor;
  final Color rowOddColor;
  final VoidCallback refreshCallback;

  ExternalData(this.data, this.context, this.rowEvenColor, this.rowOddColor, this.refreshCallback);

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
        DataCell(Text(item['studID'] ?? '')),
        DataCell(Text(item['exCompName'] ?? '')),
        DataCell(Text(item['exCompEmail'] ?? '')),
        DataCell(Text(item['exCompRegNo'] ?? '')),
        DataCell(Text(item['exJobTitle'] ?? '')),
        DataCell(Text(item['exJobDuration']?.toString() ?? '')),
        DataCell(Text(item['placementContactName'] ?? '')),
        DataCell(Text(item['placementContactEmail'] ?? '')),
        DataCell(Text(item['placementContactContactNo'] ?? '')),
        DataCell(
          InkWell(
            child: IconButton(
              icon: const Icon(Icons.download, color: Colors.blue),
              onPressed: () async {
                final url = Uri.parse(item['offerLetter']);
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
            ),
          ),
        ), 
        DataCell(Text(item['externalStatus'] ?? '')),
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
        DataCell(Text(item['jobStatus'] ?? '')),
        DataCell(Text(item['location'])),
        DataCell(Text((item['tags'] as List<dynamic>).join(', '))),
        DataCell(Text(item['companyName'] ?? '')),
        DataCell(Text(item['name'] ?? '')),
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