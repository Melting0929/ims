import 'package:url_launcher/url_launcher.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin_dashboard.dart';
import 'manage_user.dart';
import 'upload_guideline.dart';
import 'manage_job.dart';
import 'login_web.dart';
import 'eprofile_admin.dart';
import 'color.dart';

class ManageApplication extends StatefulWidget {
  final String userId;
  const ManageApplication({super.key, required this.userId});

  @override
  ManageApplicationTab createState() => ManageApplicationTab();
}

class ManageApplicationTab extends State<ManageApplication> {
  String adminEmail = "Loading...";
  String adminName = "Loading...";
  String selectedMenu = "Manage Application Page";
  final List<String> tabs = ['Student Application', 'Company Application'];
  final Color headingRowColor = Colors.black;
  final Color rowEvenColor = Colors.grey.shade100;
  final Color rowOddColor = Colors.white;

  List<Map<String, dynamic>> studentData = [];
  List<Map<String, dynamic>> companyData = [];

  String? selectedStatus;

@override
void initState() {
  super.initState();
  fetchAdminDetails().then((_) {
    _refreshData();
  });
}

  Future<void> _refreshData() async {

    List<Map<String, dynamic>> fetchCompanyData = await _getCompanyData();
    List<Map<String, dynamic>> fetchStudentData = await _getStudentData();
    setState(() {
        studentData = fetchStudentData;
        companyData = fetchCompanyData;
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

  Future<List<Map<String, dynamic>>> _getStudentData() async {
    try {
      QuerySnapshot studentSnapshot =
          await FirebaseFirestore.instance.collection('External').get();
      List<Map<String, dynamic>> externals = studentSnapshot.docs.map((doc) {
        return {
          'externalID': doc.id,
          ...doc.data() as Map<String, dynamic>
          };
      }).toList();

      List<Map<String, dynamic>> retrieveStudentData = [];

      for (var external in externals) {
        var externalID = external['externalID'];

        retrieveStudentData.add({
          'externalID': externalID,
          'exCompName': external['exCompName'] ?? '',
          'exCompEmail': external['exCompEmail'] ?? '',
          'exCompAddress': external['exCompAddress'] ?? '',
          'exCompRegNo': external['exCompRegNo'] ?? '',
          'exJobTitle': external['exJobTitle'] ?? '',
          'exJobDuration': external['exJobDuration'] ?? '',
          'offerLetter': external['offerLetter'] ?? '',
          'studID': external['studID'] ?? '',
          'exComIndustry': external['exComIndustry'] ?? '',
          'exJobType': external['exJobType'] ?? '',
          'externalStatus': external['externalStatus'] ?? '',
          'placementContactName': external['placementContactName'] ?? '',
          'placementContactEmail': external['placementContactEmail'] ?? '',
          'placementContactNo': external['placementContactNo'] ?? '',
          'placementContactJobTitle': external['placementContactJobTitle'] ?? '',
        });
      }

      return retrieveStudentData;
    } catch (e) {
      print('Error retrieving student data: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getCompanyData() async {
    try {
      QuerySnapshot companySnapshot = await FirebaseFirestore.instance
          .collection('Company')
          .where('approvalStatus', whereIn: ['Pending', 'Rejected'])
          .get();

      List<Map<String, dynamic>> companies = companySnapshot.docs.map((doc) {
        return doc.data() as Map<String, dynamic>;
      }).toList();

      // Fetch data for all companies concurrently
      List<Future<Map<String, dynamic>?>> futures = companies.map((company) async {
        var userID = company['userID'];
        if (userID != null && userID.isNotEmpty) {
          var userSnapshot = await FirebaseFirestore.instance.collection('Users').doc(userID).get();
          if (userSnapshot.exists) {
            var user = userSnapshot.data() as Map<String, dynamic>;
            return {
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
          }
        }
        return null; // Ignore invalid data
      }).toList();

      // Wait for all async operations to complete
      List<Map<String, dynamic>?> results = await Future.wait(futures);

      // Remove null entries and return the final list
      return results.whereType<Map<String, dynamic>>().toList();
    } catch (e) {
      print('Error retrieving company data: $e');
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

  // Build Student Application DataTable
  Widget _buildStudentTable(List<Map<String, dynamic>> data) {
    return PaginatedDataTable2(
      columnSpacing: 16,
      dataRowHeight: 135,
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
      rowsPerPage: 3,
      showFirstLastButtons: true,
      renderEmptyRowsInTheEnd: true,

      columns:  const [
        DataColumn(label: Text('Student\nApply', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Company\nName', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Company\nEmail', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Company\nAddress', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Company\nReg No', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Company\nIndustry', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Job Title', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Job\nDuration', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Placement\nContact Name', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Placement\nContact Email', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Placement Contact\nContact No.', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Offer Letter', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Status', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Actions', style: TextStyle(color: Colors.white))),
      ],
      source: ExternalData(data, context, rowEvenColor, rowOddColor, _refreshData), 
    );
  }

  // Build Company DataTable
  Widget _buildCompanyTable(List<Map<String, dynamic>> data) {
    return PaginatedDataTable2(
      columnSpacing: 16,
      dataRowHeight: 135,
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
      rowsPerPage: 3,
      showFirstLastButtons: true,
      renderEmptyRowsInTheEnd: true,

      columns: const [
        DataColumn(label: Text('Name', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Job Title', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Email', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Company\nName', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Address', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Company\nReg No', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Established\nYear', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Industry', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Employee\nCount', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Company\nEmail', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Logo', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Approval\nStatus', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Actions', style: TextStyle(color: Colors.white))),
      ],
      source: CompanyData(data, context, rowEvenColor, rowOddColor, _refreshData),
    );
  }

  Widget _buildTab({
    required String title,
    required VoidCallback onRefresh,
    required Future<List<Map<String, dynamic>>> future,
    required Widget Function(List<Map<String, dynamic>>) builder,
    required bool isStudentTab,
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
                            DropdownButton<String>(
                              hint: const Text("Filter by Status"),
                              value: selectedStatus,
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectedStatus = newValue;
                                });
                              },
                              items: ["All", "Pending", "Approved", "Rejected"]
                                  .map((status) => DropdownMenuItem(
                                        value: status,
                                        child: Text(status),
                                      ))
                                  .toList(),
                            ),
                            const SizedBox(height: 10),
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
                                const Text(
                                  "Approve Status:",
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
                                    hint: const Text("Filter by Status"),
                                    value: selectedStatus,
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        selectedStatus = newValue;
                                      });
                                    },
                                    icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                                    dropdownColor: Colors.white,
                                    style: const TextStyle(color: Colors.black, fontSize: 14),
                                    items: ["All", "Pending", "Approved", "Rejected"]
                                        .map((status) => DropdownMenuItem(
                                              value: status,
                                              child: Text(status),
                                            ))
                                        .toList(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
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
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              }

              List<Map<String, dynamic>> filteredData = snapshot.data ?? [];

              // Apply filtering only if selectedStatus is not "All"
              if (selectedStatus != null && selectedStatus!.isNotEmpty && selectedStatus != "All") {
                String statusKey = isStudentTab ? 'externalStatus' : 'approvalStatus';
                filteredData = filteredData
                    .where((entry) => entry[statusKey]?.toString().toLowerCase() == selectedStatus!.toLowerCase())
                    .toList();
              }

              return builder(filteredData);
            },
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
          backgroundColor: AppColors.backgroundCream,
          title: const Text("Manage Application Page"),
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
                    title: "External Company Application (by Students)",
                    onRefresh: _refreshData,
                    future: _getStudentData(),
                    builder: _buildStudentTable,
                    isStudentTab: true,
                  ),
                  _buildTab(
                    title: "Company Register Application (by Companies)",
                    onRefresh: _refreshData,
                    future: _getCompanyData(),
                    builder: _buildCompanyTable,
                    isStudentTab: false,
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
        DataCell(Text(item['exCompAddress'] ?? '')),
        DataCell(Text(item['exCompRegNo'] ?? '')),
        DataCell(Text(item['exComIndustry'] ?? '')),
        DataCell(Text(item['exJobTitle'] ?? '')),
        DataCell(Text(item['exJobDuration'].toString())),
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
        DataCell(
          (item['externalStatus'] == 'Rejected' || item['externalStatus'] == 'Approved' || item['externalStatus'] == 'Canceled')
            ? Container()
            : Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () async {
                      final externalID = item['externalID'] ?? '';
                      final studID = item['studID'] ?? '';

                      final confirm = await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Approve User'),
                          content: Text('Do you want to approve user $externalID?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Approve'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await updateExternalStatus(context, externalID, studID, 'Approved');
                        refreshCallback();
                      }
                    },
                  ),
                  // Reject Button
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () async {
                      final externalID = item['externalID'] ?? '';
                      final studID = item['studID'] ?? '';

                      final confirm = await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Reject Application'),
                          content: Text('Are you sure you want to reject application $externalID?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Reject'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await updateExternalStatus(context, externalID, studID, 'Rejected');
                        refreshCallback();
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
  final VoidCallback refreshCallback;

  CompanyData(this.data, this.context, this.rowEvenColor, this.rowOddColor, this.refreshCallback);

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
        DataCell(Text(item['email'] ?? '')),
        DataCell(Text(item['companyName'] ?? '')),
        DataCell(Text(item['companyAddress'] ?? '')),
        DataCell(Text(item['companyRegNo'] ?? '')),
        DataCell(Text(item['companyYear'].toString())),
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
        // Action buttons (Approve/Reject) only if not "Rejected"
        DataCell(
          item['approvalStatus'] == 'Rejected'
              ? Container() // Empty container if status is "Rejected"
              : Row(
                  children: [
                    // Approve Button
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () async {
                        final companyID = item['companyID'] ?? '';
                        final confirm = await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Approve Company'),
                            content: Text('Do you want to approve company $companyID?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Approve'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await updateCompStatus(context, companyID, 'Approved');
                          refreshCallback();
                        }
                      },
                    ),
                    // Reject Button
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () async {
                        final companyID = item['companyID'] ?? '';
                        final confirm = await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Reject Company'),
                            content: Text('Are you sure you want to reject company $companyID?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Reject'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await updateCompStatus(context, companyID, 'Rejected');
                          refreshCallback();
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

  // Function to update the approval status in Firestore
  Future<void> updateCompStatus(BuildContext context, String companyID, String status) async {
    try {
      await FirebaseFirestore.instance.collection('Company').doc(companyID).update({
        'approvalStatus': status,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Company $companyID updated to $status successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating company status: $e')),
      );
    }
  }

  Future<void> updateExternalStatus(BuildContext context, String externalID, String studID, String status) async {
    try {
      await FirebaseFirestore.instance.collection('External').doc(externalID).update({
        'externalStatus': status,
      });

      if (status == 'Approved') {
        await FirebaseFirestore.instance.collection('Student').doc(studID).update({
          'companyID': 'TnFa17Tuohib4Nf7rE0d',
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Application $externalID updated to $status successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating external application status: $e')),
      );
    }
  }

  Future<void> deleteUser(BuildContext context, String externalID) async {
    try {
      await FirebaseFirestore.instance
          .collection('External')
          .doc(externalID)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User $externalID deleted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting external: $e')),
      );
    }
  }