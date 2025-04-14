import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'download_guideline.dart';
import 'login_web.dart';
import 'eprofile_supervisor.dart';
import 'manage_assessment.dart';
import 'student_detail.dart';
import 'color.dart';

class SupervisorDashboard extends StatefulWidget {
  final String userId;
  const SupervisorDashboard({super.key, required this.userId});

  @override
  SupervisorDashboardState createState() => SupervisorDashboardState();
}

class SupervisorDashboardState extends State<SupervisorDashboard> {
  String supervisorEmail = "Loading...";
  String supervisorName = "Loading...";
  String supervisorID = "Loading...";
  String selectedMenu = "Dashboard";

  String selectedCompany = 'All';
  String? selectedCompanyID;
  Map<String, String> companyMap = {};
  List<String> companyNames = [];

  String selectedIntake = 'All';
  List<String> intakes = ['All', 'Jan-Apr 2021', 'May-Aug 2021', 'Sept-Dec 2021', 
                        'Jan-Apr 2022', 'May-Aug 2022', 'Sept-Dec 2022', 
                        'Jan-Apr 2023', 'May-Aug 2023', 'Sept-Dec 2023', 
                        'Jan-Apr 2024', 'May-Aug 2024', 'Sept-Dec 2024', 
                        'Jan-Apr 2025', 'May-Aug 2025', 'Sept-Dec 2025'];

  List<Map<String, dynamic>> studentList = [];

  @override
  void initState() {
    super.initState();
    fetchSupervisorDetails().then((_) {
      fetchCompanies();
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
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginWeb()),
        (Route<dynamic> route) => false,
      );
    }
  }

  Future<void> fetchCompanies() async {
    try {
      var userQuerySnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .where('userType', isEqualTo: 'Student')
          .get();

      Map<String, String> tempCompanyMap = {};

      for (var userDoc in userQuerySnapshot.docs) {
        var userId = userDoc.id;

        var studentQuerySnapshot = await FirebaseFirestore.instance
            .collection('Student')
            .where('userID', isEqualTo: userId)
            .where('supervisorID', isEqualTo: supervisorID)
            .get();

        for (var studentDoc in studentQuerySnapshot.docs) {
          var studentData = studentDoc.data();
          var companyID = studentData['companyID'];

          if (companyID == null || companyID.isEmpty) {
            print("Student with userID: $userId has no company assigned.");
            continue;
          }

          var companyQuerySnapshot = await FirebaseFirestore.instance
              .collection('Company')
              .where('companyID', isEqualTo: companyID)
              .get();

          if (companyQuerySnapshot.docs.isNotEmpty) {
            var companyData = companyQuerySnapshot.docs.first.data();
            var companyName = companyData['companyName'] ?? 'Unknown Company';

            tempCompanyMap[companyName] = companyID;
          }
        }
      }

      setState(() {
        companyMap = tempCompanyMap;
        companyNames = ['All'];
        companyNames.addAll(tempCompanyMap.keys.toList());
        companyNames.add('None');
      });

      print("Company Map: $companyMap");

    } catch (e) {
      print("Error fetching companies: $e");
    }
  }

  Future<void> fetchStudents() async {
    try {
      Query query = FirebaseFirestore.instance.collection('Student')
          .where('supervisorID', isEqualTo: supervisorID);

      // Only filter by intake period if a specific one is selected
      if (selectedIntake != "All") {
        query = query.where('intakePeriod', isEqualTo: selectedIntake);
      }

      if (selectedCompany != "All") {
        if (selectedCompany == "None") {
          query = query.where('companyID', isNull: true);
        } else {
          query = query.where('companyID', isEqualTo: selectedCompanyID);
        }
      }

      QuerySnapshot studentSnapshot = await query.get();

      List<Map<String, dynamic>> tempList = [];
      for (var doc in studentSnapshot.docs) {
        tempList.add(doc.data() as Map<String, dynamic>);
      }

      setState(() {
        studentList = tempList;
      });

    } catch (e) {
      print("Error fetching students: $e");
    }
  }

  Stream<QuerySnapshot> studentStream() {
    Query query = FirebaseFirestore.instance.collection('Student')
        .where('supervisorID', isEqualTo: supervisorID);

    // Only apply intakePeriod filter if a specific period is selected
    if (selectedIntake != "All") {
      query = query.where('intakePeriod', isEqualTo: selectedIntake);
    }

    if (selectedCompany != "All") {
      if (selectedCompany == "None") {
        query = query.where('companyID', isNull: true);
      } else {
        query = query.where('companyID', isEqualTo: selectedCompanyID);
      }
    }

    return query.snapshots();
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.backgroundCream, AppColors.secondaryYellow],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.6, 1.0],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent, // Makes gradient visible
        appBar: AppBar(
          title: const Text("Dashboard"),
          backgroundColor: Colors.transparent, // Makes the AppBar background transparent
          elevation: 0, // Removes the shadow
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
        body:  Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 30.0, top: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        children: [
                          const Icon(Icons.account_circle, size: 50),
                          const SizedBox(width: 5),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                supervisorName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                supervisorEmail,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Column (
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Intake:",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.black, width: 1.5),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedIntake,
                                  icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                                  dropdownColor: Colors.white,
                                  style: const TextStyle(color: Colors.black, fontSize: 14),
                                  items: intakes.map((String period) {
                                    return DropdownMenuItem<String>(
                                      value: period,
                                      child: Text(period),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedIntake = value!;
                                    });
                                    fetchStudents();
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Column (
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Company:",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
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
                                  icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                                  dropdownColor: Colors.white,
                                  style: const TextStyle(color: Colors.black, fontSize: 14),
                                  items: companyNames.map((String name) {
                                    return DropdownMenuItem<String>(
                                      value: name,
                                      child: SizedBox(
                                        width: 80,
                                        child: Text(
                                          name,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(color: Colors.black, fontSize: 14),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedCompany = value!;
                                      selectedCompanyID = companyMap[value];
                                    });
                                    fetchStudents();
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 35),
                    StreamBuilder<QuerySnapshot>(
                      stream: studentStream(),
                      builder: (context, studentSnapshot) {
                        if (studentSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (!studentSnapshot.hasData || studentSnapshot.data!.docs.isEmpty) {
                          return Center( 
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(height: 90),
                                Icon(Icons.person_off, size: 80, color: Colors.grey.shade400),
                                const SizedBox(height: 10),
                                const Text(
                                  'No students found for this intake.\nTry another intake period',
                                  textAlign: TextAlign.center, 
                                  style: TextStyle(fontSize: 18, color: Colors.grey),
                                ),
                              ],
                            ),
                          );
                        }
                        final students = studentSnapshot.data!.docs;

                        return SizedBox(
                            width: 1500,
                            child:  PaginatedDataTable(
                            header: const Text('List of Students'),
                            columnSpacing: 20,
                            dividerThickness: 1.5,
                            horizontalMargin: 16,
                            columns: const [
                              DataColumn(label: Text('Student ID', style: TextStyle(color: Colors.white))),
                              DataColumn(label: Text('Name', style: TextStyle(color: Colors.white))),
                              DataColumn(label: Text('Email', style: TextStyle(color: Colors.white))),
                              DataColumn(label: Text('Program', style: TextStyle(color: Colors.white))),
                              DataColumn(label: Text('Company', style: TextStyle(color: Colors.white))),
                            ],
                            source: StudentDataSource(students, context),
                            rowsPerPage: 3,
                            showFirstLastButtons: true,
                            dataRowMinHeight: 10,
                            headingRowHeight: 60,
                            headingRowColor: WidgetStateProperty.resolveWith(
                              (states) => Colors.black,
                            ),
                          ),
                        );
                      },
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

class StudentDataSource extends DataTableSource {
  final List<QueryDocumentSnapshot> students;
  final BuildContext context;

  StudentDataSource(this.students, this.context);

  Future<Map<String, dynamic>> _fetchUserData(String userId) async {
    final userSnapshot = await FirebaseFirestore.instance
        .collection('Users')
        .doc(userId)
        .get();
    return userSnapshot.data() ?? {};
  }

  Future<String> _fetchCompanyName(String companyId) async {
    if (companyId.isEmpty || companyId == 'No working company') {
      return 'None';
    }

    final companySnapshot = await FirebaseFirestore.instance
        .collection('Company')
        .doc(companyId)
        .get();

    if (companySnapshot.exists && companySnapshot.data() != null) {
      return companySnapshot.data()!['companyName'] ?? 'Unknown Company';
    } else {
      return 'Unknown Company';
    }
  }

  Future<List<DropdownMenuItem<String>>> _getCompanyList() async {
    QuerySnapshot companyQuerySnapshot = await FirebaseFirestore.instance
        .collection('Company')
        .get();

    List<DropdownMenuItem<String>> companyItems = [];

    for (var companyDoc in companyQuerySnapshot.docs) {
      var companyData = companyDoc.data() as Map<String, dynamic>?;
      String companyName = companyData?['companyName'] ?? 'Unknown Company';
      String companyId = companyDoc.id;

      companyItems.add(
        DropdownMenuItem<String>(
          value: companyId,
          child: Text(companyName),
        ),
      );
    }

    return companyItems;
  }

  Future<void> _showCompanyEditDialog(BuildContext context, String studentId) async {
    // Fetch list of companies
    List<DropdownMenuItem<String>> companyList = await _getCompanyList();

    String selectedCompanyId = '';

    // Show the dialog to select a company
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Assign Company'),
          content: DropdownButton<String>(
            value: selectedCompanyId.isEmpty ? null : selectedCompanyId,
            items: companyList,
            onChanged: (newCompanyId) {
              selectedCompanyId = newCompanyId!;
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                // Update the student's company in Firestore
                if (selectedCompanyId.isNotEmpty) {
                  await FirebaseFirestore.instance
                      .collection('Student')
                      .doc(studentId)
                      .update({'companyID': selectedCompanyId});
                }
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  DataRow getRow(int index) {
    if (index >= students.length) return const DataRow(cells: []);

    final student = students[index].data() as Map<String, dynamic>;
    final userId = student['userID'];
    final companyId = student['companyID'] ?? '';

    return DataRow(cells: [
      DataCell(
        Text(
          student['studID'] ?? '',
          style: const TextStyle(
            color: Colors.blue,
            decoration: TextDecoration.underline,
            decorationColor: Colors.blue
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StudentDetailPage(studentId: student['studID']),
            ),
          );
        },
      ),
      DataCell(FutureBuilder<Map<String, dynamic>>(
        future: _fetchUserData(userId),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Text('Loading...');
          }
          final user = userSnapshot.data ?? {};
          return Text(user['name'] ?? 'N/A');
        },
      )),
      DataCell(FutureBuilder<Map<String, dynamic>>(
        future: _fetchUserData(userId),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Text('Loading...');
          }
          final user = userSnapshot.data ?? {};
          return Text(user['email'] ?? 'N/A');
        },
      )),
      DataCell(Text(student['studProgram'] ?? 'N/A')),
      DataCell(
        FutureBuilder<String>(
          future: _fetchCompanyName(companyId),
          builder: (context, companySnapshot) {
            if (companySnapshot.connectionState == ConnectionState.waiting) {
              return const Text('Loading...');
            }

            if (companyId.isEmpty || companySnapshot.data == 'None') {
              // Show just the "Edit" button if no company assigned
              return IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showCompanyEditDialog(context, student['studID']),
              );
            } else {
              // Show the company name and "Edit" button
              return Row(
                children: [
                  Text(companySnapshot.data ?? 'None'),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showCompanyEditDialog(context, student['studID']),
                  ),
                ],
              );
            }
          },
        ),
      ),
    ]);
  }

  @override
  bool get isRowCountApproximate => false;
  @override
  int get rowCount => students.length;
  @override
  int get selectedRowCount => 0;
}
