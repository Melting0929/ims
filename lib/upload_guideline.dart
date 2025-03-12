import 'package:url_launcher/url_launcher.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'edit_guideline.dart';
import 'admin_dashboard.dart';
import 'manage_user.dart';
import 'add_guideline.dart';
import 'manage_job.dart';
import 'manage_application.dart';
import 'login_web.dart';
import 'eprofile_admin.dart';
import 'color.dart';


class UploadGuideline extends StatefulWidget {
  final String userId;
  const UploadGuideline ({super.key, required this.userId});

  @override
  UploadGuidelineTab createState() => UploadGuidelineTab();
}

class UploadGuidelineTab extends State<UploadGuideline> {
  String selectedMenu = "Upload Document Page";
  String adminEmail = "Loading...";
  String adminName = "Loading...";
  final Color headingRowColor = Colors.black;
  final Color rowEvenColor = Colors.grey.shade100;
  final Color rowOddColor = Colors.white;

  List<Map<String, dynamic>> docData = [];

  String selectedAccessType = 'All';
  List<String> accessTypes = ['All', 'Student', 'Supervisor', 'Company'];

@override
void initState() {
  super.initState();
  fetchAdminDetails();
}

  Future<void> _refreshData() async {
    List<Map<String, dynamic>> fetchdocData = await _getDocData();

    setState(() {
      docData = fetchdocData;
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

  Future<List<Map<String, dynamic>>> _getDocData() async {
    try {
      QuerySnapshot docSnapshot = await FirebaseFirestore.instance.collection('Guideline').get();
      
      // Combine document data with the document ID
      List<Map<String, dynamic>> guidelines = docSnapshot.docs.map((doc) {
        return {
          'docID': doc.id,
          'title': doc['title'] ?? '',
          'guidelineURL': doc['guidelineURL'] ?? '',
          'desc': doc['desc'] ?? '',
          'accessType': doc['accessType'] ?? '',
        };
      }).toList();

      return guidelines;
    } catch (e) {
      print('Error retrieving guideline data: $e');
      return [];
    }
  }

  Widget _buildTable(List<Map<String, dynamic>> data) {
    List<Map<String, dynamic>> filteredData = selectedAccessType == 'All'
        ? data
        : data.where((doc) => doc['accessType'] == selectedAccessType).toList();
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
        DataColumn(label: Text('Access Type', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Actions', style: TextStyle(color: Colors.white))),
      ],
      source: GuidelineData(filteredData, context, rowEvenColor, rowOddColor),
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
        title: const Text("Upload Guideline Page"),
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
                              builder: (context) => const AddGuideline(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondaryYellow,
                          foregroundColor: Colors.white,
                          elevation: 2,
                        ),
                        icon: const Icon(Icons.assignment_add, color: Colors.black),
                        label: const Text("Add Guideline", style: TextStyle(color: Colors.black)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text(
                        "Access Type:",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(width: 20),
                      DropdownButton<String>(
                        value: selectedAccessType,
                        items: accessTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedAccessType = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
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
        DataCell(Text(item['accessType'] ?? '')),
        DataCell(
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditGuideline(docId: item['docID']),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () async {
                  final docID = item['docID'] ?? '';

                  final confirm = await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Confirm Delete'),
                      content: Text('Are you sure you want to delete user $docID?'),
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
                    await deleteDoc(context, docID);

                    data.removeWhere((element) => element['docID'] == docID);
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

  Future<void> deleteDoc(BuildContext context, String docID) async {
    try {
      // Reference to Firestore document
      DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
          .collection('Guideline')
          .doc(docID)
          .get();

      if (docSnapshot.exists) {
        String? fileUrl = docSnapshot['guidelineURL'];

        if (fileUrl != null && fileUrl.isNotEmpty) {
          try {
            // Extract the file path from the Firebase Storage URL
            RegExp regex = RegExp(r'%2F(.*?)\?alt=media');
            Match? match = regex.firstMatch(fileUrl);
            if (match != null && match.group(1) != null) {
              String filePath = match.group(1)!;
              Reference fileRef = FirebaseStorage.instance.ref().child('guidelines/$filePath');

              // Delete file from Firebase Storage
              await fileRef.delete();
            }
          } catch (e) {
            debugPrint('Error deleting file from Firebase Storage: $e');
          }
        }

        // Delete document from Firestore
        await FirebaseFirestore.instance.collection('Guideline').doc(docID).delete();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Guideline $docID deleted successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document not found')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting guideline: $e')),
      );
    }
  }