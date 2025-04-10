import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'download_guideline.dart';
import 'manage_external.dart';
import 'internship_recommend.dart';
import 'student_dashboard.dart';
import 'assessmentdetail.dart';
import 'eprofile_student.dart';
import 'login_web.dart';
import 'login_mobile.dart';
import 'color.dart';

class Assessment extends StatefulWidget {
  final String userId;
  const Assessment({super.key, required this.userId});

  @override
  AssessmentState createState() => AssessmentState();
}

class AssessmentItem {
  final String assessmentID;
  final String templateTitle;
  final String templateID;
  final String studId;
  final String submissionStatus;
  final Timestamp assessmentEndDate;

  AssessmentItem({
    required this.assessmentID,
    required this.templateTitle,
    required this.templateID,
    required this.studId,
    required this.submissionStatus,
    required this.assessmentEndDate,
  });
}

class AssessmentState extends State<Assessment> {
  String studID = '';
  String studentEmail = "Loading...";
  String studentName = "Loading...";
  String selectedMenu = "Assessment Page";
  List<AssessmentItem> assessment = [];

  @override
  void initState() {
    super.initState();
    fetchStudentDetails().then((_) {
      fetchAssessmentData();
    });
  }

  bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
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
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching student details: $e");
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

Future<void> fetchAssessmentData() async {
  try {
    DateTime now = DateTime.now();
    var userDoc = await FirebaseFirestore.instance
        .collection('Student')
        .where('userID', isEqualTo: widget.userId)
        .get();

    if (userDoc.docs.isNotEmpty) {
      var studData = userDoc.docs.first.data();

      setState(() {
        studID = studData['studID'] ?? 'No studID';
      });

      final querySnapshot = await FirebaseFirestore.instance
          .collection('Assessment')
          .where('studID', isEqualTo: studID)
          .get();

      List<AssessmentItem> tempAssessmentList = [];

      for (var doc in querySnapshot.docs) {
        final appData = doc.data();

        final String templateId = appData['templateID'];
        final Timestamp endDate = appData['assessmentEndDate'];

        Timestamp endDateTimestamp = appData['assessmentEndDate'] ?? Timestamp(0, 0);
        DateTime endDateTime = endDateTimestamp.toDate(); 

        // Determine submission status
        String submissionStatus = endDateTime.isBefore(now) ? 'Due' : 'Active';

        final templateDoc = await FirebaseFirestore.instance
            .collection('Template')
            .doc(templateId)
            .get();

        final templateData = templateDoc.data();
        final String templateTitle = templateData?['templateTitle'] ?? 'Unknown Title';

        tempAssessmentList.add(
          AssessmentItem(
            assessmentID: doc.id,
            templateTitle: templateTitle,
            templateID: templateId,
            studId: studID,
            assessmentEndDate: endDate,
            submissionStatus: submissionStatus,
          ),
        );
      }

      setState(() {
        assessment = tempAssessmentList;
      });
    } else {
      debugPrint('No student document found for userID: ${widget.userId}');
    }
  } catch (e) {
    debugPrint('Error fetching assessment data: $e');
  }
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
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(left: MediaQuery.of(context).size.width * 0.15),
                child: const Text(
                  "My Assessment",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 30),
              Expanded(
                child: assessment.isEmpty
                    ? const Center(child: Text("No assessment yet. Kindly wait for your supervisor to open."))
                    : ListView.builder(
                        itemCount: assessment.length > 5 ? 5 : assessment.length,
                        itemBuilder: (context, index) {
                          final item = assessment[index];
                          return Center(
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width * 0.55, 
                              child: Card(
                                color: Colors.white,
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.templateTitle,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        "Due Date: ${DateFormat('yyyy-MM-dd').format(item.assessmentEndDate.toDate())}",
                                        style: const TextStyle(
                                          fontSize: 15,
                                          color: Colors.blueGrey,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        "Status: ${item.submissionStatus}",
                                        style: const TextStyle(
                                          fontSize: 15,
                                          color: Colors.blueGrey,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => Assessmentdetail(
                                                  studID: item.studId,
                                                  assessmentID: item.assessmentID,
                                                ),
                                              ),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.black,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: const Text("View Details", style: TextStyle(color: Colors.white)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}