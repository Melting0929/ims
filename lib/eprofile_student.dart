// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'student_dashboard.dart';

class EprofileStudent extends StatefulWidget {
  final String userId;
  const EprofileStudent({super.key, required this.userId});

  @override
  EprofileStudentTab createState() => EprofileStudentTab();
}

class EprofileStudentTab extends State<EprofileStudent> {
  final formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;

  String? selectedDept;
  List<String> programOptions = [];
  String? selectedProgram;
  List<String> specializationOptions = [];

  String studentEmail = "Loading...";
  String studentName = "Loading...";
  String? studentContactNo;
  String studentPassword = "Loading...";
  String studentID = "Loading...";
  String studentDept = '';
  String studentProgram = '';
  String studentSpecialization = '';
  String studentIntakePeriod = '';
  List<String> skill = [];

  String? companyID;
  String? supervisorID;
  String companyName = "";
  String supervisorName = "";
  List<String> supervisorOptions = [];
  List<String> companyOptions = [];

  // Text editing controllers
  final TextEditingController studentNameController = TextEditingController();
  final TextEditingController studentEmailController = TextEditingController();
  final TextEditingController studentContactNoController = TextEditingController();
  final TextEditingController studentPasswordController = TextEditingController();
  final TextEditingController studentIDController = TextEditingController();
  final TextEditingController studentProgramController = TextEditingController();
  final TextEditingController studentSpecializationController = TextEditingController();
  final TextEditingController studentDeptController = TextEditingController();
  final TextEditingController studentIntakePeriodController = TextEditingController();
  final TextEditingController companyNameController = TextEditingController();
  final TextEditingController supervisorNameController = TextEditingController();
  final TextEditingController skillController = TextEditingController();

  RegExp emailRegExp = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  RegExp phoneRegExp = RegExp(r'^[0-9\s\-]+$');
  RegExp passwordRegExp = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$');

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
      var studentSnapshot = await FirebaseFirestore.instance
          .collection('Student')
          .where('userID', isEqualTo: widget.userId)
          .get();

      if (userDoc.exists) {
        setState(() {
          studentEmail = userDoc.data()?['email'] ?? 'No Email';
          studentName = userDoc.data()?['name'] ?? 'No Name';
          studentContactNo = userDoc.data()?['contactNo'];
          studentPassword = userDoc.data()?['password'] ?? 'No Password';

          if (studentSnapshot.docs.isNotEmpty) {
            var studentDoc = studentSnapshot.docs.first.data();
            studentID = studentDoc['studID'] ?? 'No Student ID';
            studentDept = studentDoc['dept'] ?? 'No department';
            studentProgram = studentDoc['studProgram'] ?? 'No Program';
            studentSpecialization = studentDoc['specialization'] ?? 'No specialization';
            studentIntakePeriod = studentDoc['intakePeriod'] ?? 'No intake period';
            companyID = studentDoc['companyID'] ?? 'No working company';
            supervisorID = studentDoc['supervisorID'] ?? 'No supervisor';
            skill = List<String>.from(studentDoc['skill'] ?? []);
          } 
        });

        // Fetch company name
        if (companyID != null) {
          var companyDoc = await FirebaseFirestore.instance
              .collection('Company')
              .doc(companyID)
              .get();

          if (companyDoc.exists) {
            setState(() {
              companyName = companyDoc.data()?['companyName'] ?? 'Unknown Company';
            });
          }
        }

        // Fetch supervisor name
        if (supervisorID != null) {
          var supervisorDoc = await FirebaseFirestore.instance
              .collection('Supervisor')
              .doc(supervisorID)
              .get();

          if (supervisorDoc.exists) {
            var supervisorUserID = supervisorDoc.data()?['userID'];
            if (supervisorUserID != null) {
              var userDoc = await FirebaseFirestore.instance
                  .collection('Users')
                  .doc(supervisorUserID)
                  .get();

              if (userDoc.exists) {
                setState(() {
                  supervisorName = userDoc.data()?['name'] ?? 'Unknown Supervisor';
                });
              }
            }
          }
        }

        setState(() {
          // Set the values to the controllers
          studentNameController.text = studentName;
          studentEmailController.text = studentEmail;
          studentContactNoController.text = studentContactNo ?? '';
          studentPasswordController.text = studentPassword;
          studentIDController.text = studentID;
          studentProgramController.text = studentProgram;
          studentSpecializationController.text = studentSpecialization;
          studentDeptController.text = studentDept;
          studentIntakePeriodController.text = studentIntakePeriod;
          supervisorNameController.text = supervisorName.isNotEmpty ? supervisorName : 'No Supervisor Assigned';
          companyNameController.text = companyName.isNotEmpty ? companyName : 'No Working Company';
        });
      }
    } catch (e) {
      debugPrint("Error fetching student details: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: const SizedBox.shrink(),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 47, color: Colors.white),
          onPressed: () => Navigator.pop(context),                             
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/admin_background.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.black.withOpacity(0.2)),
            ),
          ),
          Center(
            child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16.0 : 80.0,
                  vertical: isMobile ? 16.0 : 20.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          width: isMobile ? double.infinity : 500,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          padding: const EdgeInsets.all(24.0),
                          child: Form(
                            key: formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Edit Profile",
                                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  "Enter the your information below",
                                  style: TextStyle(fontSize: 16, color: Colors.black),
                                ),
                                const SizedBox(height: 32),
                                // Student ID Field
                                TextFormField(
                                  controller: studentIDController,
                                  enabled: false,
                                  decoration: InputDecoration(
                                    labelText: "Student ID",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: const Icon(Icons.group),
                                  ),
                                ),
                                const SizedBox(height: 32),
                                // Full Name Field
                                TextFormField(
                                  controller: studentNameController,
                                  enabled: false,
                                  decoration: InputDecoration(
                                    labelText: "Full Name",
                                    hintText: "Enter the full name",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: const Icon(Icons.people),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Please enter the full name.";
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                // Email Field
                                TextFormField(
                                  controller: studentEmailController,
                                  enabled: false,
                                  decoration: InputDecoration(
                                    labelText: "Email",
                                    hintText: "Enter the email address",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: const Icon(Icons.email),
                                  ),
                                  validator: (value) {
                                    if (value == null || !emailRegExp.hasMatch(value)) {
                                      return "Please enter a valid email address.";
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                // Contact Number Field
                                TextFormField(
                                  controller: studentContactNoController,
                                  decoration: InputDecoration(
                                    labelText: "Contact Number",
                                    hintText: "Enter the contact number",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: const Icon(Icons.call),
                                  ),
                                  validator: (value) {
                                    if (value != null && value.isNotEmpty && !phoneRegExp.hasMatch(value)) {
                                      return "Please enter a valid contact number.";
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                // Password Field
                                TextFormField(
                                  controller: studentPasswordController,
                                  obscureText: !_isPasswordVisible,
                                  decoration: InputDecoration(
                                    labelText: "Password",
                                    hintText: "Enter the new password",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  prefixIcon: const Icon(Icons.lock),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPasswordVisible
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _isPasswordVisible = !_isPasswordVisible;
                                        });
                                      },
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || !passwordRegExp.hasMatch(value)) {
                                      return "Password must be at least 8 characters long with at least one capital letter and contain both letters and numbers.";
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                // Dept Field
                                TextFormField(
                                  controller: studentDeptController,
                                  enabled: false,
                                  decoration: InputDecoration(
                                    labelText: "Department",
                                    hintText: "Enter the department",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: const Icon(Icons.business),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Program Field
                                TextFormField(
                                  controller: studentProgramController,
                                  enabled: false,
                                  decoration: InputDecoration(
                                    labelText: "Program",
                                    hintText: "Enter the Program",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: const Icon(Icons.school),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Specialization Field
                                TextFormField(
                                  controller: studentSpecializationController,
                                  enabled: false,
                                  decoration: InputDecoration(
                                    labelText: "Specialization",
                                    hintText: "Enter the Specialization",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: const Icon(Icons.science),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Intake Period Field
                                TextFormField(
                                  controller: studentIntakePeriodController,
                                  enabled: false,
                                  decoration: InputDecoration(
                                    labelText: "Intake Period",
                                    hintText: "Enter the intake period",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: const Icon(Icons.date_range),
                                  ),
                                ),
                                const SizedBox(height: 32),
                                // Supervisor Name Field
                                TextFormField(
                                  controller: supervisorNameController,
                                  enabled: false,
                                  decoration: InputDecoration(
                                    labelText: "Supervisor Name",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: const Icon(Icons.group),
                                  ),
                                ),
                                const SizedBox(height: 32),
                                // Company Name Field
                                TextFormField(
                                  controller: companyNameController,
                                  enabled: false,
                                  decoration: InputDecoration(
                                    labelText: "Working Company",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: const Icon(Icons.apartment),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  "Assign Skill",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  children: skill
                                    .map((tag) => Chip(
                                        label: Text(tag),
                                        onDeleted: () {
                                          setState(() {
                                            skill.remove(tag);
                                          });
                                        },
                                      ))
                                  .toList(),
                                ),
                                if (skill.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    "Please add at least one skill.",
                                    style: TextStyle(color: Colors.red, fontSize: 14),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: skillController,
                                  decoration: InputDecoration(
                                    labelText: "Add Skill",
                                    hintText: "Enter a skill and press Add",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: const Icon(Icons.tag),
                                    suffixIcon: IconButton(
                                      icon: const Icon(Icons.add),
                                      onPressed: () {
                                      if (skillController.text.trim().isNotEmpty) {
                                          setState(() {
                                            skill.add(skillController.text.trim());
                                            skillController.clear();
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Save Button
                                Wrap(
                                  spacing: 16,
                                  runSpacing: 8,
                                  alignment: WrapAlignment.end,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () async {
                                        if (formKey.currentState?.validate() ?? false) {
                                          if (skill.isEmpty) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Please add at least one skill before saving.'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                            return;
                                          }

                                          // Get values from form fields
                                          String updatedName = studentNameController.text;
                                          String updatedEmail = studentEmailController.text;
                                          String? updatedPhone = studentContactNoController.text.isEmpty ? null : studentContactNoController.text;
                                          String updatedPassword = studentPasswordController.text;

                                          // Update Firestore data
                                          try {
                                            // Retrieve supervisor document ID
                                            String? supervisorId;
                                            if (supervisorID != null) {
                                              // Step 1: Get userID of the supervisor from Users collection
                                              QuerySnapshot userSnapshot = await FirebaseFirestore.instance
                                                  .collection('Users')
                                                  .where('name', isEqualTo: supervisorName)
                                                  .get();

                                              if (userSnapshot.docs.isNotEmpty) {
                                                String supervisorUserID = userSnapshot.docs.first.id;

                                                // Step 2: Get supervisor document ID from Supervisors collection using userID
                                                QuerySnapshot supervisorSnapshot = await FirebaseFirestore.instance
                                                    .collection('Supervisor')
                                                    .where('userID', isEqualTo: supervisorUserID)
                                                    .get();

                                                if (supervisorSnapshot.docs.isNotEmpty) {
                                                  supervisorId = supervisorSnapshot.docs.first.id;
                                                }
                                              }
                                            }

                                            // Retrieve company document ID
                                            String? companyId;
                                            if (companyID != null) {
                                              QuerySnapshot companySnapshot = await FirebaseFirestore.instance
                                                  .collection('Company')
                                                  .where('companyName', isEqualTo: companyName)
                                                  .get();

                                              if (companySnapshot.docs.isNotEmpty) {
                                                companyId = companySnapshot.docs.first.id;
                                              }
                                            }

                                            var updatedUserData = {
                                              'name': updatedName,
                                              'email': updatedEmail,
                                              'contactNo': updatedPhone,
                                              'password': updatedPassword,
                                            };

                                            var updatedStudentData = {
                                              'studID': studentID,
                                              'dept': studentDept,
                                              'studProgram': studentProgram,
                                              'specialization': studentSpecialization,
                                              'intakePeriod': studentIntakePeriod,
                                              'supervisorID': supervisorId,
                                              'companyID': companyId,
                                              'skill': skill,
                                            };

                                            await FirebaseFirestore.instance
                                                .collection('Users')
                                                .doc(widget.userId)
                                                .update(updatedUserData);
                                            
                                            QuerySnapshot studentSnapshot = await FirebaseFirestore.instance
                                                .collection('Student')
                                                .where('userID', isEqualTo: widget.userId)
                                                .get();

                                            for (QueryDocumentSnapshot doc in studentSnapshot.docs) {
                                              await doc.reference.update(updatedStudentData);
                                            }

                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully')));
                                            Navigator.pop(context, true);
                                          } catch (e) {
                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update profile')));
                                            debugPrint("Error updating profile: $e");
                                          }
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                        backgroundColor: Colors.black,
                                      ),
                                      child: const Text("Save Changes", style: TextStyle(color: Colors.white)),
                                    ),
                                    const SizedBox(width: 16),
                                    ElevatedButton(
                                      onPressed: () {
                                        if (Navigator.canPop(context)) {
                                          Navigator.pop(context);
                                        } else {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  StudentDashboard(userId: widget.userId),
                                            ),
                                          );
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                      child: const Text("Cancel", style: TextStyle(color: Colors.white)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}