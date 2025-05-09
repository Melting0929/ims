import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'download_guideline.dart';
import 'manage_external.dart';
import 'internship_recommend.dart';
import 'assessment.dart';
import 'login_web.dart';
import 'login_mobile.dart';
import 'eprofile_student.dart';
import 'color.dart';
import 'package:intl/intl.dart';

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

  final Color headingRowColor = Colors.black;
  final Color rowEvenColor = Colors.grey.shade100;
  final Color rowOddColor = Colors.white;

  @override
  void initState() {
    super.initState();
    fetchStudentDetails().then((_) {
      fetchApplications();
    });
  }

  // Used to check if the device is mobile or web
  bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  // Fetch the user detail (Student)
  Future<void> fetchStudentDetails() async {
    try {
      // Data from Users Collection
      var userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists) {
        setState(() {
          studentEmail = userDoc.data()?['email'] ?? 'No Email';
          studentName = userDoc.data()?['name'] ?? 'No Name';
        });

        // Data from Student Collection
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

  // Fetch Application for display on the datatable
  Future<void> fetchApplications() async {
    try {
      // Data from Application Collection that are under this user
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
          'dateApplied': data['dateApplied'] != null
            ? DateFormat('dd MMM yyyy').format((data['dateApplied'] as Timestamp).toDate())
            : 'No Date',
        });
      }));
  
      setState(() {
        applications = fetchedApplications;
      });
    } catch (e) {
      debugPrint("Error fetching applications: $e");
    }
  }

  // Logout Funtion
  Future<void> logout() async {
    // Show the dialog for user to choose
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
      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();

      // Redirect based on platform
      if (isMobile(context)) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginTab()),
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginWeb()),
          (Route<dynamic> route) => false, // removes all previous routes
        );
      }
    }
  }

  // Build the drawer item for the menu
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

  // Upload Resume PDF Function
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
      await _uploadDocument(); // Call the upload function
    }
  }

  Future<void> _uploadDocument() async {
    if (_selectedDocument?.bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: File data is empty.')),
      );
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
        debugPrint('Existing Resume URL: $existingResumeUrl');
  
        if (existingResumeUrl != null && existingResumeUrl.isNotEmpty) {
          try {
            String storagePath = Uri.decodeFull(existingResumeUrl)
                .split('?').first
                .replaceFirst(RegExp(r'^https://firebasestorage\.googleapis\.com/v0/b/[^/]+/o/'), '');
            storagePath = storagePath.replaceAll('%2F', '/');
            
            final oldFileRef = FirebaseStorage.instance.ref().child(storagePath);
            
            // Ensure the file exists before deleting
            await oldFileRef.getMetadata();
            await oldFileRef.delete();
            debugPrint('Old resume deleted successfully.');
          } catch (e) {
            debugPrint('Error deleting old resume: $e');
          }
        }
  
        // Upload new file to Firebase Storage
        final storageRef = FirebaseStorage.instance.ref().child('resume/$fileName');
        final metadata = SettableMetadata(contentType: 'application/pdf');
        final uploadTask = storageRef.putData(_selectedDocument!.bytes!, metadata);
        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();

        debugPrint('Uploading file: resume/$fileName');
  
        // Update Firestore document with new resume URL
        await FirebaseFirestore.instance.collection('Student').doc(studentDocId).update({
          'resumeURL': downloadUrl,
          'uploadedAt': FieldValue.serverTimestamp(),
        });
  
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Resume uploaded successfully!')),
        );
  
        // Refresh the resume link by fetching student details again
        await fetchStudentDetails();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student record not found.')),
        );
      }

      Navigator.pop(context);
  
      setState(() {
        _selectedDocument = null;
        _uploadedFileName = null;
      });
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading resume: $e')),
      );
    }
  }
  
  // Function to launch URL (Resume)
  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch $url');
    }
  }

  // Function to build the resume display widget
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
                decorationColor: Colors.blue,
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
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text("Dashboard"),
          backgroundColor: Colors.transparent, 
          elevation: 0,
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
                      title: "Internship Recommendation Page",
                      onTap: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => InternshipRecommend(userId: widget.userId)),
                      ),
                    ),
                    buildDrawerItem(
                      icon: Icons.upload_file,
                      title: "Assessment Page",
                      onTap: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => Assessment(userId: widget.userId)),
                      ),
                    ),
                    buildDrawerItem(
                      icon: Icons.upload_file,
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
        body: SingleChildScrollView( 
          child: Padding(
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
                          studentName, // Display student name
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          studID, // Display student ID
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
                const Divider(height: 1, thickness: 1, color: Colors.black),

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

                // Application History Section
                Padding(
                  padding: const EdgeInsets.only(top: 30.0, right: 50, left: 50),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Application History:",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      applications.isEmpty // if empty shows text
                        ? const Center(
                            child: Text(
                              "No Application Yet...",
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          )
                        : isMobile(context) // if is mobile then shows in card, else in datatable
                            ? ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: applications.length,
                                itemBuilder: (context, index) {
                                  final app = applications[index];
                                  return Card(
                                    margin: const EdgeInsets.symmetric(vertical: 8),
                                    elevation: 3,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    child: ListTile(
                                      title: Text(app['jobTitle'] ?? 'Unknown Job'),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text("Company: ${app['companyName'] ?? 'Unknown'}"),
                                            Text("Status: ${app['applicationStatus'] ?? 'Pending'}"),
                                            Text("Interview: ${app['interviewStatus'] ?? 'N/A'}"),
                                            Text("Applied: ${app['dateApplied'] ?? '-'}"),
                                          ],
                                        ),
                                      trailing: app['applicationStatus'] == 'Pending'
                                      ? IconButton(
                                        icon: const Icon(Icons.cancel, color: Colors.orange),
                                        onPressed: () async {
                                          final applicationID = app['applicationID'] ?? '';

                                          if (applicationID.isEmpty) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Invalid application ID.')),
                                            );
                                            return;
                                          }

                                          // Show confirmation dialog
                                          final confirm = await showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text('Confirm Cancellation'),
                                              content: const Text('Are you sure you want to cancel this application?'),
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

                                          // If confirmed, delete the application
                                          if (confirm == true) {
                                            await deleteApplication(context, applicationID);

                                            // Remove from local list and notify listeners to update UI
                                            setState(() {
                                              applications.removeWhere((element) => element['applicationID'] == applicationID);
                                            });
                                          }
                                        },
                                      )
                                      : null, // Show cancel button only if status is Pending
                                    ),
                                  );
                                },
                              )
                            : SingleChildScrollView( // Datatable for web
                              scrollDirection: Axis.horizontal,
                              child: SizedBox(
                                width: 1200, 
                                child: PaginatedDataTable(
                                  columnSpacing: 16,
                                  dividerThickness: 1.5,
                                  horizontalMargin: 16,
                                  showFirstLastButtons: true,
                                  columns: const [
                                    DataColumn(label: Text("Job Title", style: TextStyle(color: Colors.white))),
                                    DataColumn(label: Text("Company Name", style: TextStyle(color: Colors.white))),
                                    DataColumn(label: Text("Application Status", style: TextStyle(color: Colors.white))),
                                    DataColumn(label: Text("Interview Status", style: TextStyle(color: Colors.white))),
                                    DataColumn(label: Text("Date Applied", style: TextStyle(color: Colors.white))),
                                    DataColumn(label: Text("Action", style: TextStyle(color: Colors.white))),
                                  ],
                                  source: ApplicationDataSource(applications, context, rowEvenColor, rowOddColor),
                                  dataRowMinHeight: 10,
                                  headingRowHeight: 60,
                                  rowsPerPage: 3,
                                  headingRowColor: WidgetStateProperty.resolveWith(
                                    (states) => headingRowColor,
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
        ),
      ),
    );
  }
}

// Application DataTable
class ApplicationDataSource extends DataTableSource {
  final List<Map<String, dynamic>> applications;
  final BuildContext context;
  final Color rowEvenColor;
  final Color rowOddColor;

  ApplicationDataSource(this.applications, this.context, this.rowEvenColor, this.rowOddColor);

  @override
  DataRow? getRow(int index) {
    if (index >= applications.length) return null;

    final item = applications[index];
    final isEven = index % 2 == 0;
    return DataRow(
      color: WidgetStateProperty.resolveWith(
        (states) => isEven ? rowEvenColor : rowOddColor,
      ),
      cells: [
      DataCell(Text(item['jobTitle'] ?? 'N/A')),
      DataCell(Text(item['companyName'] ?? 'N/A')),
      DataCell(Text(item['applicationStatus'] ?? 'Pending')),
      DataCell(Text(item['interviewStatus'] ?? 'N/A')),
      DataCell(Text(item['dateApplied'] ?? 'N/A')),
      DataCell(
        Row(
          children: [
            if (item['applicationStatus'] == 'Pending') // Cancel Button shows only if the status is Pending
              IconButton(
                icon: const Icon(Icons.cancel, color: Colors.orange),
                onPressed: () async {
                  final applicationID = item['applicationID'] ?? '';

                  if (applicationID.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invalid application ID.')),
                    );
                    return;
                  }

                  final confirm = await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Confirm Cancellation'),
                      content: const Text('Are you sure you want to cancel this application?'),
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
                    await deleteApplication(context, applicationID);

                    applications.removeWhere((element) => element['applicationID'] == applicationID);
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
  int get rowCount => applications.length;

  @override
  int get selectedRowCount => 0;
}

Future<void> deleteApplication(BuildContext context, String applicationID) async {
    try {
      // Reference to Firestore document
      DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
          .collection('Application')
          .doc(applicationID)
          .get();

      if (docSnapshot.exists) {
        // Delete document from Firestore
        await FirebaseFirestore.instance.collection('Application').doc(applicationID).delete();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Application $applicationID deleted successfully!')),
        );
      } 
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting application: $e')),
      );
    }
  }
