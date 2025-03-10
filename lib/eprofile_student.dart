// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  RegExp emailRegExp = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  RegExp phoneRegExp = RegExp(r'^[0-9\s\-]+$');
  RegExp passwordRegExp = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$');

  @override
  void initState() {
    super.initState();
    fetchStudentDetails();
    fetchSupervisorList();
    fetchCompanyList();
  }

  Future<void> fetchSupervisorList() async {
    try {
      var querySnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .where('userType', isEqualTo: 'Supervisor')
          .get();
      setState(() {
        supervisorOptions = querySnapshot.docs
            .map((doc) => doc.data()['name'] as String)
            .toList();
      });
    } catch (e) {
      debugPrint("Error fetching supervisors: $e");
    }
  }

  Future<void> fetchCompanyList() async {
    try {
      var querySnapshot = await FirebaseFirestore.instance
          .collection('Company')
          .get();
      setState(() {
        companyOptions = querySnapshot.docs
            .map((doc) => doc.data()['companyName'] as String)
            .toList();
      });
    } catch (e) {
      debugPrint("Error fetching companies: $e");
    }
  }

  // Mapping of departments to their programs
  final Map<String, List<String>> departmentProgramMap = {
    'Engineering': ['Mechanical', 'Civil', 'Electrical'],
    'IT': ['Computer Science', 'Information Technology'],
    'Business': ['Management', 'Accounting'],
    'Marketing': ['Digital Marketing', 'Brand Management'],
  };

  final Map<String, List<String>> programSpecializationMap = {
    'Computer Science': ['AI', 'Cyber Security'],
    'Information Technology': ['Business Software Development', 'Software Engineering'],
    'Management': ['Project Management', 'HR Management'],
  };

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
          } else {
            studentID = 'No Student ID';
            studentDept = 'No department';
            studentProgram = 'No Program';
            studentSpecialization = 'No specialization';
            studentIntakePeriod = 'No intake period';
            companyID = null;
            supervisorID = null;
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

          // Update dropdown options and selections
          selectedDept = studentDept;
          programOptions = departmentProgramMap[selectedDept!] ?? [];
          if (programOptions.contains(studentProgram)) {
            selectedProgram = studentProgram;
          } else {
            selectedProgram = null;
          }
          specializationOptions = programSpecializationMap[selectedProgram ?? ''] ?? [];
        });
      }
    } catch (e) {
      debugPrint("Error fetching student details: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile Page"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
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
              padding: const EdgeInsets.symmetric(horizontal: 80.0, vertical: 20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          width: 500,
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
                                DropdownButtonFormField<String>(
                                  value: studentDept.isEmpty ? null : studentDept,
                                  decoration: InputDecoration(
                                    labelText: "Department",
                                    hintText: "Select the department",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: const Icon(Icons.business),
                                  ),
                                  items: departmentProgramMap.keys
                                      .map<DropdownMenuItem<String>>((String key) {
                                    return DropdownMenuItem<String>(
                                      value: key,
                                      child: Text(key),
                                    );
                                  }).toList(),
                                  onChanged: null,
                                ),
                                const SizedBox(height: 16),
                                // Program Field
                                DropdownButtonFormField<String>(
                                  value: programOptions.contains(studentProgram) ? studentProgram : null,
                                  decoration: InputDecoration(
                                    labelText: "Program",
                                    hintText: "Select the program",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: const Icon(Icons.school),
                                  ),
                                  items: programOptions.map<DropdownMenuItem<String>>((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                  onChanged: null,
                                ),
                                const SizedBox(height: 16),
                                // Specialization Field
                                DropdownButtonFormField<String>(
                                  value: studentSpecialization.isEmpty ? null : studentSpecialization,
                                  decoration: InputDecoration(
                                    labelText: "Specialization",
                                    hintText: "Select the specialization",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: const Icon(Icons.science),
                                  ),
                                  items: specializationOptions
                                      .map<DropdownMenuItem<String>>((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                  onChanged: null,
                                ),
                                const SizedBox(height: 16),
                                // Intake Period Field
                                DropdownButtonFormField<String>(
                                  value: studentIntakePeriod.isEmpty ? null : studentIntakePeriod,
                                  decoration: InputDecoration(
                                    labelText: "Intake Period",
                                    hintText: "Select the intake period",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: const Icon(Icons.date_range),
                                  ),
                                  items: <String>['Jan-Apr 2025', 'May-Aug 2025', 'Sept-Dec 2025', 'Jan-Apr 2026'] 
                                      .map<DropdownMenuItem<String>>((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                  onChanged: null,
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
                                // Save Button
                                Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      ElevatedButton(
                                        onPressed: () async {
                                          if (formKey.currentState?.validate() ?? false) {
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
                                          Navigator.pop(context, true);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                          backgroundColor: Colors.redAccent,
                                        ),
                                        child: const Text("Cancel", style: TextStyle(color: Colors.white)),
                                      ),
                                    ],
                                  ),
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