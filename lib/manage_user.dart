import 'package:ims/color.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'admin_dashboard.dart';
import 'manage_application.dart';
import 'manage_job.dart';
import 'upload_guideline.dart';
import 'login_web.dart';

import 'edit_student.dart';
import 'edit_supervisor.dart';
import 'edit_company.dart';
import 'eprofile_admin.dart';

import 'add_admin.dart';
import 'add_company.dart';
import 'add_student.dart';
import 'add_supervisor.dart';

class ManageUser extends StatefulWidget {
  final String userId;
  const ManageUser({super.key, required this.userId});

  @override
  ManageUserTab createState() => ManageUserTab();
}

class ManageUserTab extends State<ManageUser> {
  String selectedMenu = "Manage User Page";
  String adminEmail = "Loading...";
  String adminName = "Loading...";
  final List<String> tabs = ['Student', 'Company', 'Supervisor', 'Admin'];
  final Color headingRowColor = Colors.black;
  final Color rowEvenColor = Colors.grey.shade100;
  final Color rowOddColor = Colors.white;

  List<Map<String, dynamic>> adminData = [];
  List<Map<String, dynamic>> supervisorData = [];
  List<Map<String, dynamic>> studentData = [];
  List<Map<String, dynamic>> companyData = [];

  String selectedDept = 'All';
  String selectedIntakePeriod= 'All';
  String selectedSupervisorName = 'All';
  String selectedCompanyName = 'All';

  String selectedCompany = 'All';
  String selectedApprovalStatus = 'All';

  String selectedSupervisor = 'All';
  String selectedSDept = 'All';

  String selectedAdmin = 'All';

  List<String> supervisorNames = [];
  List<String> companyNames = [];
  List<String> adminNames = [];

@override
void initState() {
  super.initState();
  fetchAdminDetails().then((_) {
    fetchSupervisorList().then((supervisor) {
      setState(() {
        supervisorNames = supervisor;
      });
    });
    fetchAdminList().then((admin) {
      setState(() {
        adminNames = admin;
      });
    });
    fetchCompanyNames().then((company) {
      setState(() {
        companyNames = company;
      });
    });
  });
}

  Future<void> _refreshData() async {

    List<Map<String, dynamic>> fetchAdminData = await _getAdminData();
    List<Map<String, dynamic>> fetchStudentData = await _getStudentData();
    List<Map<String, dynamic>> fetchSupervisorData = await _getSupervisorData();
    List<Map<String, dynamic>> fetchCompanyData = await _getCompanyData();

    setState(() {
      adminData = fetchAdminData;
      studentData = fetchStudentData;
      supervisorData = fetchSupervisorData;
      companyData = fetchCompanyData;
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

  Future<List<String>> fetchAdminList() async {
    try {
      QuerySnapshot adminSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .where('userType', isEqualTo: 'Admin')
          .get();

      List<String> adminrNames = [];

      for (var adminDoc in adminSnapshot.docs) {
        if (adminDoc.exists) {
          String name = adminDoc['name'].toString();
          adminrNames.add(name);
        }
      }

      adminrNames.insert(0, 'All');
      
      return adminrNames;
    } catch (e) {
      debugPrint("Error fetching admin details: $e");
      return ['No Admin'];
    }
  }

  Future<List<String>> fetchSupervisorList() async {
    try {
      QuerySnapshot supervisorSnapshot = await FirebaseFirestore.instance
          .collection('Supervisor')
          .get();

      List<String> supervisorNames = [];

      for (var supervisorDoc in supervisorSnapshot.docs) {
        String userID = supervisorDoc['userID'];

        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(userID)
            .get();
        
        if (userDoc.exists) {
          String name = userDoc['name'].toString();
          supervisorNames.add(name);
        }
      }

      supervisorNames.insert(0, 'All');
      
      return supervisorNames;
    } catch (e) {
      print('Error fetching supervisors: $e');
      return ['No Supervisor'];
    }
  }

  Future<List<String>> fetchCompanyNames() async {
    try {
      QuerySnapshot companySnapshot = await FirebaseFirestore.instance
          .collection('Company')
          .get();
      List<String> companyNames = companySnapshot.docs
          .map((doc) => doc['companyName'].toString())
          .toList();
      
      companyNames.insert(0, 'All');
      
      return companyNames;
    } catch (e) {
      print('Error fetching companies: $e');
      return ['No Working Company'];
    }
  }

  Future<List<Map<String, dynamic>>> _getStudentData() async {
  try {
    QuerySnapshot studentSnapshot = await FirebaseFirestore.instance
        .collection('Student')
        .get();

    List<Map<String, dynamic>> students = studentSnapshot.docs.map((doc) {
      return doc.data() as Map<String, dynamic>;
    }).toList();

    List<Map<String, dynamic>> userStudent = [];

    for (var student in students) {
      var userID = student['userID'];
      var userSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userID)
          .get();
      var user = userSnapshot.data() as Map<String, dynamic>;

      var supervisorID = student['supervisorID'];
      var companyID = student['companyID'];

      String companyName = 'No Working Company';
      String supervisorName = 'No Supervisor';

      // Retrieve company name if companyID is not null or empty
      if (companyID != null && companyID.isNotEmpty) {
        DocumentSnapshot companySnapshot = await FirebaseFirestore.instance
            .collection('Company')
            .doc(companyID)
            .get();
        Map<String, dynamic> company = companySnapshot.exists
            ? companySnapshot.data() as Map<String, dynamic>
            : {};
        companyName = company['companyName'] ?? 'No Working Company';
      }

      // Retrieve supervisor name if supervisorID is not null or empty
      if (supervisorID != null && supervisorID.isNotEmpty) {
        DocumentSnapshot supervisorSnapshot = await FirebaseFirestore.instance
            .collection('Supervisor')
            .doc(supervisorID)
            .get();
        Map<String, dynamic> supervisor = supervisorSnapshot.exists
            ? supervisorSnapshot.data() as Map<String, dynamic>
            : {};

        var supervisorNID = supervisor['userID'];
        if (supervisorNID != null && supervisorNID.isNotEmpty) {
          DocumentSnapshot supervisorNameSnapshot =
              await FirebaseFirestore.instance
                  .collection('Users')
                  .doc(supervisorNID)
                  .get();
          Map<String, dynamic> supervisorN = supervisorNameSnapshot.exists
              ? supervisorNameSnapshot.data() as Map<String, dynamic>
              : {};
          supervisorName = supervisorN['name'] ?? 'No Supervisor';
        }
      }

      Map<String, dynamic> studentData = {
        'userID': student['userID'] ?? '',
        'userType': user['userType'] ?? '',
        'studID': student['studID'] ?? '',
        'name': user['name'] ?? '',
        'email': user['email'] ?? '',
        'contactNo': user['contactNo'] ?? '',
        'password': user['password'] ?? '',
        'dept': student['dept'] ?? '',
        'resumeURL': student['resumeURL'] ?? '',
        'specialization': student['specialization'] ?? '',
        'studProgram': student['studProgram'] ?? '',
        'companyName': companyName,
        'supervisorName': supervisorName,
        'intakePeriod': student['intakePeriod'] ?? '',
      };

      if ((selectedDept == 'All' || studentData['dept'] == selectedDept) &&
          (selectedCompanyName == 'All' || studentData['companyName'] == selectedCompanyName || (studentData['companyName'] == null && selectedCompanyName == 'No Working Company')) &&
          (selectedIntakePeriod == 'All' || studentData['intakePeriod'] == selectedIntakePeriod) &&
          (selectedSupervisorName == 'All' || studentData['supervisorName'] == selectedSupervisorName || (studentData['supervisorName'] == null && selectedSupervisorName == 'No Supervisor'))) {
        userStudent.add(studentData);
      }
    }

    return userStudent;
  } catch (e) {
    print('Error retrieving student data: $e');
    return [];
  }
}

  // Fetch Company Data and combine with Users
  Future<List<Map<String, dynamic>>> _getCompanyData() async {
    try {
      QuerySnapshot companySnapshot = await FirebaseFirestore.instance.collection('Company').get();
      List<Map<String, dynamic>> companies = companySnapshot.docs.map((doc) {
        return doc.data() as Map<String, dynamic>;
      }).toList();

      List<Map<String, dynamic>> retrieveCompanyData = [];

      for (var company in companies) {
        var userID = company['userID'];
        var userSnapshot = await FirebaseFirestore.instance.collection('Users').doc(userID).get();
        var user = userSnapshot.data() as Map<String, dynamic>;

        Map<String, dynamic> companyData = {
          'userID': company['userID'] ?? '',
          'userType': user['userType'] ?? '',
          'name': user['name'] ?? '',
          'email': user['email'] ?? '',
          'contactNo': user['contactNo'] ?? '',
          'password': user['password'] ?? '',
          'companyID': company['companyID'] ?? '',
          'companyName': company['companyName'] ?? '',
          'companyAddress': company['companyAddress'] ?? '',
          'companyRegNo': company['companyRegNo'] ?? '',
          'companyYear': company['companyYear'] ?? '',
          'companyDesc': company['companyDesc'] ?? '',
          'companyIndustry': company['companyIndustry'] ?? '',
          'companyEmpNo': company['companyEmpNo'] ?? '',
          'companyEmail': company['companyEmail'] ?? '',
          'logoURL': company['logoURL'] ?? '',
          'pContactJobTitle': company['pContactJobTitle'] ?? '',
          'approvalStatus': company['approvalStatus'] ?? '',
        };

        if ((selectedApprovalStatus == 'All' || companyData['approvalStatus'] == selectedApprovalStatus) &&
            (selectedCompany == 'All' || companyData['companyName'] == selectedCompany)) {
          retrieveCompanyData.add(companyData);
        }
      }

      return retrieveCompanyData;
    } catch (e) {
      print('Error retrieving company data: $e');
      return [];
    }
  }

  // Fetch Supervisor Data and combine with Users
  Future<List<Map<String, dynamic>>> _getSupervisorData() async {
    try {
      QuerySnapshot supervisorSnapshot = await FirebaseFirestore.instance.collection('Supervisor').get();
      List<Map<String, dynamic>> supervisors = supervisorSnapshot.docs.map((doc) {
        return doc.data() as Map<String, dynamic>;
      }).toList();

      List<Map<String, dynamic>> retrieveSupervisorData = [];

      for (var supervisor in supervisors) {
        var userID = supervisor['userID'];
        var userSnapshot = await FirebaseFirestore.instance.collection('Users').doc(userID).get();
        var user = userSnapshot.data() as Map<String, dynamic>;

        Map<String, dynamic> supervisorData = {
          'userID': supervisor['userID'] ?? '',
          'userType': user['userType'] ?? '',
          'supervisorID': supervisor['supervisorID'] ?? '',
          'name': user['name'] ?? '',
          'email': user['email'] ?? '',  
          'password': user['password'] ?? '',  
          'contactNo': user['contactNo'] ?? '',    
          'dept': supervisor['dept'] ?? '',     
        };

        if ((selectedSDept == 'All' || supervisorData['dept'] == selectedSDept) && 
            (selectedSupervisor == 'All' || supervisorData['name'] == selectedSupervisor)) {
          retrieveSupervisorData.add(supervisorData);
        }
      }

      return retrieveSupervisorData;
    } catch (e) {
      print('Error retrieving supervisor data: $e');
      return [];
    }
  }

  // Fetch Admin Data and combine with Users
  Future<List<Map<String, dynamic>>> _getAdminData() async {
    try {
      QuerySnapshot adminSnapshot = await FirebaseFirestore.instance.collection('Admin').get();
      List<Map<String, dynamic>> admins = adminSnapshot.docs.map((doc) {
        return doc.data() as Map<String, dynamic>;
      }).toList();

      List<Map<String, dynamic>> retrieveAdminData = [];

      for (var admin in admins) {
        var userID = admin['userID'];
        var userSnapshot = await FirebaseFirestore.instance.collection('Users').doc(userID).get();
        var user = userSnapshot.data() as Map<String, dynamic>;

        Map<String, dynamic> adminData = {
          'userID': admin['userID'] ?? '',
          'name': user['name'] ?? '',
          'email': user['email'] ?? '',
          'contactNo': user['contactNo'] ?? '',
          'password': user['password'] ?? '',
          'userType': user['userType'] ?? '',
        };

        if ((selectedAdmin == 'All' || adminData['name'] == selectedAdmin)) {
          retrieveAdminData.add(adminData);
        }
      }

      return retrieveAdminData;
    } catch (e) {
      print('Error retrieving admin data: $e');
      return [];
    }
  }

  // Build Student DataTable
  Widget _buildStudentTable(List<Map<String, dynamic>> data) {
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
        DataColumn(label: Text('ID', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Name', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Email', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Contact No', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Password', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Department', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Specialization', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Program', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Working\nCompany', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Supervisor', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Intake\nPeriod', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Resume', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Actions', style: TextStyle(color: Colors.white))),
      ],
      source: StudentData(data, context, rowEvenColor, rowOddColor),
    );
  }

  // Build Company DataTable
  Widget _buildCompanyTable(List<Map<String, dynamic>> data) {
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
        DataColumn(label: Text('Name', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Job Title', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Contact No', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Email', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Password', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Company ID', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Company Name', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Address', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Company\nRegistration\nNo', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Established\nYear', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Description', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Industry', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Employee\nCount', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Company\nEmail', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Logo', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Approval\nStatus', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Actions', style: TextStyle(color: Colors.white))),
      ],
      source: CompanyData(data, context, rowEvenColor, rowOddColor),
    );
  }

  // Build Student DataTable
  Widget _buildSupervisorTable(List<Map<String, dynamic>> data) {
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
        DataColumn(label: Text('ID', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Name', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Email', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Contact No', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Password', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Department', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Actions', style: TextStyle(color: Colors.white))),
      ],
      source: SupervisorData(data, context, rowEvenColor, rowOddColor), 
    );
  }

  // Build Admin DataTable
  Widget _buildAdminTable(List<Map<String, dynamic>> data) {
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
        DataColumn(label: Text('ID', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Name', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Email', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Contact No', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Password', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Actions', style: TextStyle(color: Colors.white))),
      ],
      source: AdminData(data, context, rowEvenColor, rowOddColor),
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
                                  icon: const Icon(Icons.person_add, color: Colors.black),
                                  label: const Text("Add User", style: TextStyle(color: Colors.black)),
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
                            const SizedBox(height: 12),
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
                                  icon: const Icon(Icons.person_add, color: Colors.black),
                                  label: const Text("Add User", style: TextStyle(color: Colors.black)),
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
        if (dropdowns != null) 
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: dropdowns,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _buildFutureTable(
            future: future,
            builder: builder,
          ),
        ),
      ],
    );
  }


  void _navigateToAddUser(BuildContext context, String userType) {
    if (userType == 'Student'){
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddStudentPage(userType: userType),
        ),
      );
    } else if (userType == 'Supervisor') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddSupervisorPage(userType: userType),
        ),
      );
    } else if (userType == 'Company') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddCompanyPage(userType: userType),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddAdminPage(userType: userType),
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: const Text("Manage User Page"),
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
                    title: "Student Management",
                    onAdd: () => _navigateToAddUser(context, "Student"),
                    onRefresh: _refreshData,
                    future: _getStudentData(),
                    builder: _buildStudentTable,
                    dropdowns: [
                      const Text(
                        "Department:",
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
                            value: selectedDept,
                            onChanged: (value) {
                              setState(() {
                                selectedDept = value!;
                              });
                            },
                            icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                            dropdownColor: Colors.white,
                            style: const TextStyle(color: Colors.black, fontSize: 14),
                            items: ['All','Engineering','IT','Business','Marketing'].map((dept) {
                              return DropdownMenuItem<String>(
                                value: dept,
                                child: Text(dept),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 30),
                      const Text(
                        "Supervisor Name:",
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
                            value: selectedSupervisorName,
                            onChanged: (value) {
                              setState(() {
                                selectedSupervisorName = value!;
                              });
                            },
                            icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                            dropdownColor: Colors.white,
                            style: const TextStyle(color: Colors.black, fontSize: 14),
                            items: ['No Supervisor', ...supervisorNames].map((name) {
                              return DropdownMenuItem<String>(
                                value: name,
                                child: Text(name),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 30),
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
                            value: selectedCompanyName,
                            onChanged: (value) {
                              setState(() {
                                selectedCompanyName = value!;
                              });
                            },
                            icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                            dropdownColor: Colors.white,
                            style: const TextStyle(color: Colors.black, fontSize: 14),
                            items: ['No Working Company', ...companyNames].map((name) {
                              return DropdownMenuItem<String>(
                                value: name,
                                child: Text(name),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 30),
                      const Text(
                        "Intake Period:",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black, width: 1.5),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedIntakePeriod,
                            icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                            dropdownColor: Colors.white,
                            style: const TextStyle(color: Colors.black, fontSize: 14),
                            items: ['All', 'Jan-Apr 2025', 'May-Aug 2025', 'Sept-Dec 2025', 'Jan-Apr 2026'].map((intake) {
                              return DropdownMenuItem(
                                value: intake,
                                child: Text(intake),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              setState(() {
                                selectedIntakePeriod = newValue!;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  _buildTab(
                    title: "Registered & External Company Management",
                    onAdd: () => _navigateToAddUser(context, "Company"),
                    onRefresh: _refreshData,
                    future: _getCompanyData(),
                    builder: _buildCompanyTable,
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
                            value: selectedCompany,
                            onChanged: (value) {
                              setState(() {
                                selectedCompany = value!;
                              });
                            },
                            icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                            dropdownColor: Colors.white,
                            style: const TextStyle(color: Colors.black, fontSize: 14),
                            items: companyNames.map((name) {
                              return DropdownMenuItem<String>(
                                value: name,
                                child: Text(name),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 30),
                      const Text(
                        "Approval Status:",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black, width: 1.5),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedApprovalStatus,
                            icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                            dropdownColor: Colors.white,
                            style: const TextStyle(color: Colors.black, fontSize: 14),
                            items: ["All", "Approve", "Pending"].map((title) {
                              return DropdownMenuItem(
                                value: title,
                                child: Text(title),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              setState(() {
                                selectedApprovalStatus = newValue!;
                              });
                            },
                          ),
                        ),
                      ),
                    ]
                  ),
                  _buildTab(
                    title: "Staff Management",
                    onAdd: () => _navigateToAddUser(context, "Supervisor"),
                    onRefresh: _refreshData,
                    future: _getSupervisorData(), 
                    builder: _buildSupervisorTable,
                    dropdowns: [
                      const Text(
                        "Supervisor Name:",
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
                            value: selectedSupervisor,
                            onChanged: (value) {
                              setState(() {
                                selectedSupervisor = value!;
                              });
                            },
                            icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                            dropdownColor: Colors.white,
                            style: const TextStyle(color: Colors.black, fontSize: 14),
                            items: supervisorNames.map((name) {
                              return DropdownMenuItem<String>(
                                value: name,
                                child: Text(name),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 30),
                      const Text(
                        "Department:",
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
                            value: selectedSDept,
                            onChanged: (value) {
                              setState(() {
                                selectedSDept = value!;
                              });
                            },
                            icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                            dropdownColor: Colors.white,
                            style: const TextStyle(color: Colors.black, fontSize: 14),
                            items: ['All','Engineering','IT','Business','Marketing'].map((dept) {
                              return DropdownMenuItem<String>(
                                value: dept,
                                child: Text(dept),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ]
                  ),
                  _buildTab(
                    title: "Admin Management",
                    onAdd: () => _navigateToAddUser(context, "Admin"),
                    onRefresh: _refreshData,
                    future: _getAdminData(),
                    builder: _buildAdminTable,
                    dropdowns: [
                      const Text(
                        "Admin Name:",
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
                            value: selectedAdmin,
                            onChanged: (value) {
                              setState(() {
                                selectedAdmin = value!;
                              });
                            },
                            icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                            dropdownColor: Colors.white,
                            style: const TextStyle(color: Colors.black, fontSize: 14),
                            items: adminNames.map((name) {
                              return DropdownMenuItem<String>(
                                value: name,
                                child: Text(name),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ]
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

class StudentData extends DataTableSource {
  final List<Map<String, dynamic>> data;
  final BuildContext context;
  final Color rowEvenColor;
  final Color rowOddColor;

  StudentData(this.data, this.context, this.rowEvenColor, this.rowOddColor);

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
        DataCell(Text(item['name'] ?? '')),
        DataCell(Text(item['email'] ?? '')),
        DataCell(Text(item['contactNo'] ?? '')),
        DataCell(Text(item['password'] ?? '')),
        DataCell(Text(item['dept'] ?? '')),
        DataCell(Text(item['specialization'] ?? '')),
        DataCell(Text(item['studProgram'] ?? '')),
        DataCell(Text(item['companyName'] ?? '')),
        DataCell(Text(item['supervisorName'] ?? '')),
        DataCell(Text(item['intakePeriod'] ?? '')),
        DataCell(Text(item['resumeURL'] ?? '')),
        DataCell(
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditStudent(userId: item['userID']),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                final role = item['userType'];
                final userID = item['userID'] ?? '';

                final confirm = await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Confirm Delete'),
                    content: Text('Are you sure you want to delete user $userID?'),
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
                  await deleteUser(context, userID, role);

                  data.removeWhere((element) => element['userID'] == userID);
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

class CompanyData extends DataTableSource {
  final List<Map<String, dynamic>> data;
  final BuildContext context;
  final Color rowEvenColor;
  final Color rowOddColor;

  CompanyData(this.data, this.context, this.rowEvenColor, this.rowOddColor);

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
        DataCell(Text(item['name'] ?? '')),
        DataCell(Text(item['pContactJobTitle'] ?? '')),
        DataCell(Text(item['contactNo'] ?? '')),
        DataCell(Text(item['email'] ?? '')),
        DataCell(Text(item['password'] ?? '')),
        DataCell(Text(item['companyID'] ?? '')),
        DataCell(Text(item['companyName'] ?? '')),
        DataCell(Text(item['companyAddress'] ?? '')),
        DataCell(Text(item['companyRegNo'] ?? '')),
        DataCell(Text(item['companyYear'].toString())),
        DataCell(Text(item['companyDesc'] ?? '')),
        DataCell(Text(item['companyIndustry'] ?? '')),
        DataCell(Text(item['companyEmpNo'].toString())),
        DataCell(Text(item['companyEmail'] ?? '')),
        DataCell(
          InkWell(
            child: IconButton(
              icon: const Icon(Icons.download, color: Colors.blue),
              onPressed: () async {
                final url = Uri.parse(item['logoURL']);
                try {
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not open the image')),
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
        DataCell(Text(item['approvalStatus'] ?? '')),
        DataCell(
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditCompany(userId: item['userID']),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () async {
                  final role = item['userType'];
                  final userID = item['userID'] ?? '';

                  final confirm = await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Confirm Delete'),
                      content: Text('Are you sure you want to delete user $userID?'),
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
                    await deleteUser(context, userID, role);

                    data.removeWhere((element) => element['userID'] == userID);
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

class SupervisorData extends DataTableSource {
  final List<Map<String, dynamic>> data;
  final BuildContext context;
  final Color rowEvenColor;
  final Color rowOddColor;

  SupervisorData(this.data, this.context, this.rowEvenColor, this.rowOddColor);

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
        DataCell(Text(item['supervisorID'] ?? '')),
        DataCell(Text(item['name'] ?? '')),
        DataCell(Text(item['email'] ?? '')),
        DataCell(Text(item['contactNo'] ?? '')),
        DataCell(Text(item['password'] ?? '')),
        DataCell(Text(item['dept'].toString())),
        DataCell(
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditSupervisor(userId: item['userID']),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () async {
                  final role = item['userType'];
                  final userID = item['userID'] ?? '';

                  final confirm = await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Confirm Delete'),
                      content: Text('Are you sure you want to delete user $userID?'),
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
                    await deleteUser(context, userID, role);

                    data.removeWhere((element) => element['userID'] == userID);
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

class AdminData extends DataTableSource {
  final List<Map<String, dynamic>> data;
  final BuildContext context;
  final Color rowEvenColor;
  final Color rowOddColor;

  AdminData(this.data, this.context, this.rowEvenColor, this.rowOddColor);

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
        DataCell(Text(item['userID'] ?? '')),
        DataCell(Text(item['name'] ?? '')),
        DataCell(Text(item['email'] ?? '')),
        DataCell(Text(item['contactNo'] ?? '')),
        DataCell(Text(item['password'] ?? '')),
        DataCell(
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EprofileAdmin(userId: item['userID']),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () async {
                  final role = item['userType'];
                  final userID = item['userID'] ?? '';

                  final confirm = await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Confirm Delete'),
                      content: Text('Are you sure you want to delete user $userID?'),
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
                    await deleteUser(context, userID, role);

                    data.removeWhere((element) => element['userID'] == userID);
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

  Future<void> deleteUser(BuildContext context, String userID, String role) async {
    try {
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(userID)
          .delete();

      QuerySnapshot roleSnapshot = await FirebaseFirestore.instance
          .collection(role)
          .where('userID', isEqualTo: userID)
          .get();

      if (roleSnapshot.docs.isNotEmpty) {
        await roleSnapshot.docs.first.reference.delete();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User $userID deleted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting user: $e')),
      );
    }
  }