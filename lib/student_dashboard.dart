import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'download_guideline.dart';
import 'login_web.dart';
import 'eprofile_student.dart';
import 'color.dart';

// Date Applied
// Upload Resume & Delete Resume File Name
class StudentDashboard extends StatefulWidget {
  final String userId;
  const StudentDashboard({super.key, required this.userId});

  @override
  StudentDashboardState createState() => StudentDashboardState();
}

class StudentDashboardState extends State<StudentDashboard> {
  String studentEmail = "Loading...";
  String studentName = "Loading...";
  String studID = "Loading...";
  String? resumeURL;
  String selectedMenu = "Dashboard";

  List<Map<String, dynamic>> applications = [];

  PlatformFile? _selectedDocument;
  String? _uploadedFileName;

  @override
  void initState() {
    super.initState();
    fetchStudentDetails().then((_) {
      fetchApplications();
    });
  }

  Future<void> fetchStudentDetails() async {
    try {
      var userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists) {
        setState(() {
          studentEmail = userDoc.data()?['email'] ?? 'No Email';
          studentName = userDoc.data()?['name'] ?? 'No Name';
        });

        var studentDoc = await FirebaseFirestore.instance
            .collection('Student')
            .where('userID', isEqualTo: widget.userId)
            .get();

        if (studentDoc.docs.isNotEmpty) {
          var studentData = studentDoc.docs.first.data();
          setState(() {
            studID = studentData['studID'] ?? 'No ID';
            resumeURL = studentData['resumeURL'] ?? '';
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching student details: $e");
    }
  }

  Future<void> fetchApplications() async {
    try {
      var querySnapshot = await FirebaseFirestore.instance
          .collection('Application')
          .where('studID', isEqualTo: studID)
          .get();
  
      List<Map<String, dynamic>> fetchedApplications = [];
  
      // Fetch job and company details for each application
      await Future.wait(querySnapshot.docs.map((doc) async {
        var data = doc.data();
        String jobID = data['jobID'] ?? '';
  
        Map<String, dynamic> jobData = {};
        Map<String, dynamic> companyData = {};
        String companyID = '';
  
        // Fetch job details
        if (jobID.isNotEmpty) {
          try {
            var jobDoc = await FirebaseFirestore.instance
                .collection('Job')
                .doc(jobID)
                .get();
  
            if (jobDoc.exists) {
              jobData = jobDoc.data() as Map<String, dynamic>;
              companyID = jobData['companyID'] ?? '';
            }
          } catch (jobError) {
            debugPrint("Error fetching job details: $jobError");
          }
        }
  
        // Fetch company details using companyID
        if (companyID.isNotEmpty) {
          try {
            var companyDoc = await FirebaseFirestore.instance
                .collection('Company')
                .doc(companyID)
                .get();
  
            if (companyDoc.exists) {
              companyData = companyDoc.data() as Map<String, dynamic>;
            }
          } catch (companyError) {
            debugPrint("Error fetching company details: $companyError");
          }
        }
  
        fetchedApplications.add({
          'applicationID': doc.id,
          'jobID': jobID,
          'applicationStatus': data['applicationStatus'] ?? 'Pending',
          'interviewStatus': data['interviewStatus'] ?? 'Pending',
          'jobTitle': jobData['jobTitle'] ?? 'Unknown',
          'companyID': companyID,
          'companyName': companyData['companyName'] ?? 'Unknown',
        });
      }));
  
      setState(() {
        applications = fetchedApplications;
      });
    } catch (e) {
      debugPrint("Error fetching applications: $e");
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

  Future<void> _uploadResume() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No document selected.')),
      );
      return;
    }

    setState(() {
      _selectedDocument = result.files.single;
      _uploadedFileName = result.files.single.name;
    });

    // Show confirmation dialog
    bool confirmUpload = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Upload"),
        content: Text("Do you want to upload $_uploadedFileName?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Upload"),
          ),
        ],
      ),
    );

    if (confirmUpload) {
      await _uploadDocument();
    }
  }

  Future<void> _uploadDocument() async {
    if (_selectedDocument == null) {
      return;
    }

    final fileName = _uploadedFileName ?? DateTime.now().millisecondsSinceEpoch.toString();
    if (!fileName.toLowerCase().endsWith('.pdf')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only PDF files are allowed.')),
      );
      return;
    }

    try {
      // Show progress indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Find the student's document in the Student collection
      QuerySnapshot studentQuery = await FirebaseFirestore.instance
          .collection('Student')
          .where('userID', isEqualTo: widget.userId)
          .get();

      if (studentQuery.docs.isNotEmpty) {
        // Get the document ID
        String studentDocId = studentQuery.docs.first.id;
        var studentDoc = studentQuery.docs.first;

        // Check if the student already has an existing resumeURL
        String? existingResumeUrl = studentDoc['resumeURL'];

        if (existingResumeUrl != null && existingResumeUrl.isNotEmpty) {
          // Extract the file name from the existing URL
          Uri uri = Uri.parse(existingResumeUrl);
          String? oldFileName = uri.pathSegments.last;

          // Delete the old file from Firebase Storage
          final oldFileRef = FirebaseStorage.instance.ref().child('resume/$oldFileName');
          print('Deleting old file: $oldFileName');
          await oldFileRef.delete();
        }

        // Upload new file to Firebase Storage
        final storageRef = FirebaseStorage.instance.ref().child('resume/$fileName');
        final metadata = SettableMetadata(contentType: 'application/pdf');
        final uploadTask = storageRef.putData(_selectedDocument!.bytes!, metadata);
        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();

        // Update Firestore document with new resume URL
        await FirebaseFirestore.instance.collection('Student').doc(studentDocId).update({
          'resumeURL': downloadUrl,
          'uploadedAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Resume uploaded successfully!')),
        );

        await fetchStudentDetails();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student record not found.')),
        );
      }

      // Close progress indicator
      Navigator.pop(context);

      // Clear selection
      setState(() {
        _selectedDocument = null;
        _uploadedFileName = null;
      });
    } catch (e) {
      Navigator.pop(context);
      debugPrint('Error uploading resume: $e');
    }
  }
  
  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch $url');
    }
  }

  Widget buildResumeDisplay() {
    return resumeURL != null
        ? GestureDetector(
            onTap: () => _launchURL(resumeURL!),
            child: const Text(
              "View Uploaded Resume",
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
          )
        : const Text(
            "No file uploaded",
            style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
          );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const  Text("Student Dashboard"),
        backgroundColor: Colors.white,
        centerTitle: true,
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
                    icon: Icons.upload_file,
                    title: "Apply External Company Page",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => DownloadGuideline(userId: widget.userId)),
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 30.0, top: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.account_circle, size: 40),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          studentName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          studID,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          "Welcome to Student Dashboard",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1, thickness: 1, color: Color.fromARGB(255, 204, 201, 201)),

                // Upload Resume Row
                Padding(
                  padding: const EdgeInsets.only(top: 30.0, right: 70, left: 50),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, 
                    children: [
                      const Text(
                        "Upload Resume:",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10), 
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                        children: [
                          ElevatedButton.icon(
                            onPressed: _uploadResume,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              elevation: 2,
                            ),
                            icon: const Icon(Icons.upload_file, color: Colors.white),
                            label: Text(
                              _uploadedFileName ?? 'Upload Document',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: buildResumeDisplay(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 30.0, right: 50, left: 50),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Application History:",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      applications.isEmpty
                          ? const Center(child: CircularProgressIndicator())
                          : SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SizedBox(
                                width: 1200, 
                                child: PaginatedDataTable(
                                  columnSpacing: 20,
                                  horizontalMargin: 16,
                                  dividerThickness: 1.5,
                                  columns: const [
                                    DataColumn(label: Text("Job Title", style: TextStyle(color: Colors.white))),
                                    DataColumn(label: Text("Company Name", style: TextStyle(color: Colors.white))),
                                    DataColumn(label: Text("Application Status", style: TextStyle(color: Colors.white))),
                                    DataColumn(label: Text("Interview Status", style: TextStyle(color: Colors.white))),
                                  ],
                                  source: ApplicationDataSource(applications),
                                  rowsPerPage: 4,
                                  showFirstLastButtons: true,
                                  dataRowMinHeight: 10,
                                  headingRowHeight: 60,
                                  headingRowColor: WidgetStateProperty.resolveWith(
                                    (states) => Colors.black,
                                  ),
                                ),
                              ),
                            ),
                    ],
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

// DataTable Source for pagination
class ApplicationDataSource extends DataTableSource {
  final List<Map<String, dynamic>> applications;

  ApplicationDataSource(this.applications);

  @override
  DataRow? getRow(int index) {
    if (index >= applications.length) return null;

    var application = applications[index];
    return DataRow(cells: [
      DataCell(Text(application['jobTitle'] ?? 'N/A')),
      DataCell(Text(application['companyName'] ?? 'N/A')),
      DataCell(Text(application['applicationStatus'] ?? 'Pending')),
      DataCell(Text(application['interviewStatus'] ?? 'N/A')),
    ]);
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => applications.length;

  @override
  int get selectedRowCount => 0;
}
