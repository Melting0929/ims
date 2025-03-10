import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'download_guideline.dart';
import 'login_web.dart';
import 'eprofile_student.dart';
import 'color.dart';

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
  String selectedMenu = "Dashboard";

  @override
  void initState() {
    super.initState();
    fetchStudentDetails();
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    children: [
                      const Icon(Icons.account_circle, size: 40),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            studentName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            studID,
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
        ],
      ),
    );
  }
}
