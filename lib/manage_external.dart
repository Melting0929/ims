import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_web.dart';
import 'eprofile_student.dart';
import 'student_dashboard.dart';
import 'download_guideline.dart';
import 'apply_external.dart';
import 'color.dart';

class ManageExternal extends StatefulWidget {
  final String userId;
  const ManageExternal({super.key, required this.userId});

  @override
  ManageExternalTab createState() => ManageExternalTab();
}

class ManageExternalTab extends State<ManageExternal> {
  String selectedMenu = "Apply External Company Page";
  String studentEmail = "Loading...";
  String studentName = "Loading...";

  String studID = '';

  final Color headingRowColor = Colors.black;
  final Color rowEvenColor = Colors.grey.shade100;
  final Color rowOddColor = Colors.white;

  List<Map<String, dynamic>> externalData = [];

@override
void initState() {
  super.initState();
  fetchStudentDetails().then((_) {
    _refreshData();
  });
}

  Future<void> _refreshData() async {
    List<Map<String, dynamic>> fetchExternalData = await _getExternalData();

    setState(() {
      externalData = fetchExternalData;
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

  Future<void> fetchStudentDetails() async {
    try {
      var studentSnapshot = await FirebaseFirestore.instance
          .collection('Student')
          .where('userID', isEqualTo: widget.userId)
          .get();

      if (studentSnapshot.docs.isNotEmpty) {
        var studentData = studentSnapshot.docs.first.data();
        setState(() {
          studID = studentData['studID'] ?? 'No studID';

        });
      } else {
        debugPrint('No student details found for the userId: ${widget.userId}');
      }
    } catch (e) {
      debugPrint("Error fetching student details: $e");
    }
  }

  Future<List<Map<String, dynamic>>> _getExternalData() async {
    try {
      QuerySnapshot externalSnapshot = await FirebaseFirestore.instance
      .collection('External')
      .where('studID', isEqualTo: studID)
      .get();

      List<Map<String, dynamic>> externals = externalSnapshot.docs.map((doc) {
        return {
          'externalID': doc.id,
          ...doc.data() as Map<String, dynamic>
        };
      }).toList();

      List<Map<String, dynamic>> retrieveExternalData = [];

      for (var external in externals) {
          retrieveExternalData.add({
            'studID': studID,
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
          });
      }

      return retrieveExternalData;
    } catch (e) {
      print('Error retrieving external data: $e');
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
        DataColumn(label: Text('Company Name', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Company Email', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Company Address', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Company Reg No.', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Company Year', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Company Industry', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Job Title', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Job Duration', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Status', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Action', style: TextStyle(color: Colors.white))),
      ],
      source: ExternalData(data, context, rowEvenColor, rowOddColor), 
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
        title: const Text("Manage External Application Page"),
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
                          studentName,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          studentEmail,
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
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => EprofileStudent(userId: widget.userId)),
                    ),
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
                      MaterialPageRoute(builder: (context) => StudentDashboard(userId: widget.userId)),
                    ),
                  ),
                  buildDrawerItem(
                    icon: Icons.apartment,
                    title: "Apply External Company Page",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ManageExternal(userId: widget.userId)),
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
                "Student Panel v1.0",
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
                              builder: (context) => AddExternal(userId: widget.userId),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondaryYellow,
                          foregroundColor: Colors.white,
                          elevation: 2,
                        ),
                        icon: const Icon(Icons.assignment_add, color: Colors.black),
                        label: const Text("Apply New Application", style: TextStyle(color: Colors.black)),
                      ),
                    ], 
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _buildFutureTable(
                    future: _getExternalData(),
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

class ExternalData extends DataTableSource {
  final List<Map<String, dynamic>> data;
  final BuildContext context;
  final Color rowEvenColor;
  final Color rowOddColor;

  ExternalData(this.data, this.context, this.rowEvenColor, this.rowOddColor);

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
        DataCell(Text(item['exCompName'] ?? '')),
        DataCell(Text(item['exCompEmail'] ?? '')),
        DataCell(Text(item['exCompAddress'] ?? '')),
        DataCell(Text(item['exCompRegNo'] ?? '')),
        DataCell(Text(item['exCompYear']?.toString() ?? '')),
        DataCell(Text(item['exComIndustry'] ?? '')),
        DataCell(Text(item['exJobTitle'] ?? '')),
        DataCell(Text(item['exJobDuration']?.toString() ?? '')),
        DataCell(Text(item['externalStatus'] ?? '')),
        DataCell(
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.cancel, color: Colors.orange),
                onPressed: () async {
                  final externalID = item['externalID'] ?? '';

                  if (externalID.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invalid external ID.')),
                    );
                    return;
                  }

                  final confirm = await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Confirm Cancellation'),
                      content: const Text('Are you sure you want to cancel this external application?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('No'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.mutedBlue,
                          ),
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text("Yes, Cancel", style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                  
                  if (confirm == true) {
                    await deleteApplication(context, externalID);

                    data.removeWhere((element) => element['externalID'] == externalID);
                    notifyListeners();
                  }
                },
              ),
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

  Future<void> deleteApplication(BuildContext context, String externalID) async {
    try {
      // Reference to Firestore document
      DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
          .collection('External')
          .doc(externalID)
          .get();

      if (docSnapshot.exists) {
        String? fileUrl = docSnapshot['offerLetter'];

        if (fileUrl != null && fileUrl.isNotEmpty) {
          try {
            // Extract the file path from the Firebase Storage URL
            RegExp regex = RegExp(r'%2F(.*?)\?alt=media');
            Match? match = regex.firstMatch(fileUrl);
            if (match != null && match.group(1) != null) {
              String filePath = match.group(1)!;
              Reference fileRef = FirebaseStorage.instance.ref().child('offerletter/$filePath');

              // Delete file from Firebase Storage
              await fileRef.delete();
            }
          } catch (e) {
            debugPrint('Error deleting file from Firebase Storage: $e');
          }
        }

        // Delete document from Firestore
        await FirebaseFirestore.instance.collection('External').doc(externalID).delete();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('External $externalID deleted successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document not found')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting external: $e')),
      );
    }
  }