import 'package:data_table_2/data_table_2.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_web.dart';
import 'eprofile_company.dart';
import 'company_dashboard.dart';
import 'download_guideline.dart';
import 'manage_cjob.dart';
import 'student_detail.dart';
import 'color.dart';

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
  String companyID = '';

  final Color headingRowColor = Colors.black;
  final Color rowEvenColor = Colors.grey.shade100;
  final Color rowOddColor = Colors.white;

  final List<String> tabs = ['Job Applicants', 'Active Interns'];

  List<Map<String, dynamic>> applicantData = [];
  List<Map<String, dynamic>> internData = [];

  String? selectedJobTitle = 'All';
  String? selectedIJobTitle = 'All';
  String selectedStudID = 'All';
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

  PlatformFile? _selectedDocument;
  String? _uploadedFileName;

  Future<void> _pickAndUploadDocument(String applicationID) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
      withData: true, 
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedDocument = result.files.single;
        _uploadedFileName = result.files.single.name;
      });

      try {
        if (_selectedDocument == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No document selected.')),
          );
          return;
        }

        // Prepare upload
        final fileName = _uploadedFileName ?? DateTime.now().millisecondsSinceEpoch.toString();
        final storageRef = FirebaseStorage.instance.ref().child('evaluation/$fileName');

        // Determine content type
        String fileExtension = fileName.split('.').last.toLowerCase();
        String contentType = 'application/octet-stream';

        if (fileExtension == 'pdf') {
          contentType = 'application/pdf';
        } else if (fileExtension == 'doc') {
          contentType = 'application/msword';
        } else if (fileExtension == 'docx') {
          contentType = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
        }

        final metadata = SettableMetadata(contentType: contentType);

        // Upload file data
        final uploadTask = storageRef.putData(_selectedDocument!.bytes!, metadata);
        final snapshot = await uploadTask;

        // Get the download URL
        final downloadUrl = await snapshot.ref.getDownloadURL();

        // Update Firestore with URL
        await FirebaseFirestore.instance
            .collection('Application')
            .doc(applicationID) 
            .update({'evaluation': downloadUrl, 'evaluateDate': DateTime.now().toString()});

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload successful')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload document: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No document selected.')),
      );
    }
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
            companyID = companyDoc.docs.first.id;

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

        Map<String, dynamic> applicantData = {
          'applicationID': application['applicationID'] ?? '',
          'studID': application['studID'] ?? '',
          'studName': user['name'] ?? '',
          'jobTitle': job['jobTitle'] ?? '',
          'jobDesc': job['jobDesc'] ?? '',
          'jobAllowance': job['jobAllowance'] ?? '',
          'applicationStatus': application['applicationStatus'] ?? '',
          'interviewStatus': application['interviewStatus'] ?? '',
        };

        if ((selectedJobTitle == 'All' || applicantData['jobTitle'] == selectedJobTitle) &&
            (selectedApplicationStatus == 'All' || applicantData['applicationStatus'] == selectedApplicationStatus) &&
            (selectedInterviewStatus == 'All' || applicantData['interviewStatus'] == selectedInterviewStatus)) {
          applicant.add(applicantData);
        }
      }

      return applicant;
    } catch (e) {
      print('Error retrieving application data: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getInternData() async {
    try {
      // Fetch students based on companyID
      QuerySnapshot internSnapshot = await FirebaseFirestore.instance
          .collection('Student')
          .where('companyID', isEqualTo: companyID)
          .get();

      List<Map<String, dynamic>> interns = internSnapshot.docs.map((doc) {
        return {
          'studID': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }).toList();

      List<Map<String, dynamic>> applicant = [];

      for (var intern in interns) {
        var studID = intern['studID'];

        // Fetch application data for each student
        QuerySnapshot applicationSnapshot = await FirebaseFirestore.instance
            .collection('Application')
            .where('studID', isEqualTo: studID)
            .where('applicationStatus', isEqualTo: 'Accepted')
            .where('interviewStatus', isEqualTo: 'Accepted')
            .get();

        if (applicationSnapshot.docs.isEmpty) continue;

        for (var appDoc in applicationSnapshot.docs) {
          var application = appDoc.data() as Map<String, dynamic>;
          var applicationID = appDoc.id;
          var jobID = application['jobID'];

          // Fetch the job details using jobID
          DocumentSnapshot jobDoc = await FirebaseFirestore.instance
              .collection('Job')
              .doc(jobID)
              .get();

          if (!jobDoc.exists) continue;

          var jobData = jobDoc.data() as Map<String, dynamic>;

          if (jobData['companyID'] != companyID) continue;

          var userID = intern['userID'];
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('Users')
              .doc(userID)
              .get();

          String studName = '';
          if (userDoc.exists) {
            var userData = userDoc.data() as Map<String, dynamic>;
            studName = userData['name'] ?? 'Unknown Name';
          }

          // Fetch offer letter from Assessment collection
          String offerLetter = '';
          QuerySnapshot assessmentSnapshot = await FirebaseFirestore.instance
              .collection('Assessment')
              .where('studID', isEqualTo: studID)
              .where('templateID', isEqualTo: '1')
              .limit(1)
              .get();

          if (assessmentSnapshot.docs.isNotEmpty) {
            var assessmentData = assessmentSnapshot.docs.first.data() as Map<String, dynamic>;
            offerLetter = assessmentData['submissionURL'] ?? '';
          }

          Map<String, dynamic> applicantData = {
            'studID': intern['studID'] ?? '',
            'offerletter': offerLetter,
            'jobDesc': jobData['jobDesc'] ?? '',
            'jobTitle': jobData['jobTitle'] ?? '',
            'evaluation': application['evaluation'] ?? '',
            'name': studName,
            'applicationID': applicationID,
          };

          bool matchesJobTitle = selectedIJobTitle == 'All' || applicantData['jobTitle'] == selectedIJobTitle;
          bool matchesStudID = selectedStudID == 'All' || applicantData['studID'] == selectedStudID;

          if (matchesJobTitle && matchesStudID) {
            applicant.add(applicantData);
          }
        }
      }

      return applicant;
    } catch (e) {
      print('Error retrieving interns data: $e');
      return [];
    }
  }

  Widget _buildApplicantTable(List<Map<String, dynamic>> data) {
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
      rowsPerPage: 5,
      showFirstLastButtons: true,
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

  Widget _buildInternTable(List<Map<String, dynamic>> data) {
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
      rowsPerPage: 5,
      showFirstLastButtons: true,
      renderEmptyRowsInTheEnd: true,

      columns:  const [
        DataColumn(label: Text('Intern Name', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Job Title', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Job Description', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Offer Letter', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Evaluation Form', style: TextStyle(color: Colors.white))),
        DataColumn(label: Text('Action', style: TextStyle(color: Colors.white))),
      ],
      source: InternData(
        data,
        context,
        rowEvenColor,
        rowOddColor,
        _refreshData,
        _pickAndUploadDocument,
      )
    );
  }

  Widget _buildTab({
    required String title,
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
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.backgroundCream,
          title: const Text("Manage Applicant Page"),
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
        backgroundColor: AppColors.backgroundCream,
        body: Row(
          children: [
            Expanded(
              child: TabBarView(
                children: [
                  _buildTab(
                    title: "Job Applicants",
                    onRefresh: _refreshData,
                    future: _getApplicantData(),
                    builder: _buildApplicantTable,
                    dropdowns: [ 
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
                                child: SizedBox(
                                  width: 80,
                                  child: Text(
                                    title,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.black, fontSize: 14),
                                  ),
                                ),
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
                            items: ['All', 'Accepted', 'None'].map((status) {
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
                  _buildTab(
                    title: "Active Interns",
                    onRefresh: _refreshData,
                    future: _getInternData(),
                    builder: _buildInternTable,
                    dropdowns: [
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
                            value: selectedIJobTitle,
                            onChanged: (value) {
                              setState(() {
                                selectedIJobTitle = value;
                              });
                              _refreshData();
                            },
                            icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                            dropdownColor: Colors.white,
                            style: const TextStyle(color: Colors.black, fontSize: 14),
                            items: jobTitles.map((title) {
                              return DropdownMenuItem<String>(
                                value: title,
                                child: SizedBox(
                                  width: 80,
                                  child: Text(
                                    title,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.black, fontSize: 14),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 30),
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
        DataCell(
          Text(
            item['studName'] ?? '',
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
                builder: (context) => StudentDetailPage(studentId: item['studID']),
              ),
            );
          },
        ),
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

class InternData extends DataTableSource {
  final List<Map<String, dynamic>> data;
  final BuildContext context;
  final Color rowEvenColor;
  final Color rowOddColor;
  final VoidCallback refreshCallback;
  final Future<void> Function(String applicationID) onUploadEvaluation;


  InternData(
    this.data,
    this.context,
    this.rowEvenColor,
    this.rowOddColor,
    this.refreshCallback,
    this.onUploadEvaluation,
  );

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
        DataCell(
          Text(
            item['name'] ?? '',
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
                builder: (context) => StudentDetailPage(studentId: item['studID']),
              ),
            );
          },
        ),
        DataCell(Text(item['jobTitle'] ?? '')),
        DataCell(Text(item['jobDesc'] ?? '')),
        DataCell(
          item['offerletter'] == null || item['offerletter'].isEmpty
              ? const Text('')
              : InkWell(
                child: IconButton(
                  icon: const Icon(Icons.download, color: Colors.blue),
                  onPressed: () async {
                    final url = Uri.parse(item['offerletter']);
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
        DataCell(
          item['evaluation'] == null || item['evaluation'].isEmpty
              ? const Text('')
              : InkWell(
                  child: IconButton(
                    icon: const Icon(Icons.download, color: Colors.blue),
                    onPressed: () async {
                      final url = Uri.parse(item['evaluation']);
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
        DataCell(
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: () async {
              final applicationID = item['applicationID'];
              if (applicationID != null) {
                await onUploadEvaluation(applicationID);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Application ID is missing')),
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
  int get rowCount => data.length;

  @override
  int get selectedRowCount => 0;
    
  }