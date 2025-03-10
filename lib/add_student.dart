// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddStudentPage extends StatefulWidget {
  final String userType;
  const AddStudentPage({super.key, required this.userType});

  @override
  State<AddStudentPage> createState() => _AddStudentPageState();
} 

class _AddStudentPageState extends State<AddStudentPage> {
  final _formKey = GlobalKey<FormState>();

  // Text editing controllers
  final TextEditingController studentNameController = TextEditingController();
  final TextEditingController studentEmailController = TextEditingController();
  final TextEditingController studentContactNoController = TextEditingController();

  final TextEditingController studentIDController = TextEditingController();
  final TextEditingController studentProgramController = TextEditingController();
  final TextEditingController studentSpecializationController = TextEditingController();
  final TextEditingController studentDeptController = TextEditingController();
  final TextEditingController studentIntakePeriodController = TextEditingController();

  RegExp emailRegExp = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  RegExp phoneRegExp = RegExp(r'^[0-9\s\-]+$');

  String studentDept = '';
  String studentProgram = '';
  String studentSpecialization = '';
  String studentIntakePeriod = '';

  String? selectedDept;
  List<String> programOptions = [];
  String? selectedProgram;
  List<String> specializationOptions = [];

  Future<List<String>>? supervisorListFuture;
  Future<List<String>>? companyListFuture;
  String? selectedSupervisorName;
  String? selectedCompanyName;

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

  @override
  void initState() {
    super.initState();
    supervisorListFuture = fetchSupervisorList();
    companyListFuture = fetchCompanyNames();
  }


  Future<List<String>> fetchSupervisorList() async {
    try {
      QuerySnapshot supervisorSnapshot = await FirebaseFirestore.instance
          .collection('Supervisor')
          .where('dept', isEqualTo: studentDept)
          .get();

      List<String> supervisorNames = [];

      for (var supervisorDoc in supervisorSnapshot.docs) {
        String userID = supervisorDoc['userID'];

        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(userID)
            .get();
        
        if (userDoc.exists) {
          String name = userDoc['name'].toString();
          supervisorNames.add(name);
        }
      }
      
      if (supervisorNames.isEmpty) {
        supervisorNames.add('No Supervisor');
      } else {
        supervisorNames.insert(0, 'No Supervisor');
      }
      
      return supervisorNames;
    } catch (e) {
      print('Error fetching supervisors: $e');
      return ['No Supervisor'];
    }
  }

  Future<List<String>> fetchCompanyNames() async {
    try {
      QuerySnapshot companySnapshot = await FirebaseFirestore.instance
          .collection('Company')
          .get();
      List<String> companyNames = companySnapshot.docs
          .map((doc) => doc['companyName'].toString())
          .toList();
      companyNames.insert(0, 'No Working Company');
      return companyNames;
    } catch (e) {
      print('Error fetching companies: $e');
      return ['No Working Company'];
    }
  }

  // Save user to Firestore
  Future<void> saveUser() async {
    if (_formKey.currentState!.validate()) {
      String? supervisorID;
      String? companyID;

      try {
        if (selectedSupervisorName != 'No Supervisor') {
          // Step 1: Retrieve the user document for the selected supervisor
          QuerySnapshot supervisorUserSnapshot = await FirebaseFirestore.instance
              .collection('Users')
              .where('name', isEqualTo: selectedSupervisorName)
              .where('userType', isEqualTo: 'Supervisor')
              .limit(1)
              .get();

          if (supervisorUserSnapshot.docs.isEmpty) {
            throw Exception("Supervisor not found in Users collection.");
          }

          String supervisorUserID = supervisorUserSnapshot.docs.first.id;

          // Step 2: Retrieve the supervisor document ID from the Supervisor collection
          QuerySnapshot supervisorSnapshot = await FirebaseFirestore.instance
              .collection('Supervisor')
              .where('userID', isEqualTo: supervisorUserID)
              .limit(1)
              .get();

          if (supervisorSnapshot.docs.isEmpty) {
            throw Exception("Supervisor not found in Supervisor collection.");
          }
          
          supervisorID = selectedSupervisorName == 'No Supervisor' ? null : supervisorSnapshot.docs.first.id;
        }

        if (selectedCompanyName != 'No Working Company') {
          // Step 3: Retrieve the company document ID
          QuerySnapshot companySnapshot = await FirebaseFirestore.instance
              .collection('Company')
              .where('companyName', isEqualTo: selectedCompanyName)
              .limit(1)
              .get();

          if (companySnapshot.docs.isEmpty) {
            throw Exception("Company not found in Company collection.");
          }

          companyID = selectedCompanyName == 'No Working Company' ? null : companySnapshot.docs.first.id;
        }

        // Step 4: Prepare user data
        Map<String, dynamic> userData = {
          'name': studentNameController.text.trim(),
          'email': studentEmailController.text.trim(),
          'contactNo': studentContactNoController.text.trim(),
          'password': 'Password123',
          'userType': widget.userType,
        };

        // Step 5: Add the user to the Users collection
        var userRef = await FirebaseFirestore.instance.collection('Users').add(userData);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User added successfully!')),
        );

        // Step 6: Add the student data to the Student collection
        String userID = userRef.id;
        String studID = studentIDController.text.trim();

        await FirebaseFirestore.instance.collection('Student').doc(studID).set({
          'userID': userID,
          'studID': studID,
          'specialization': studentSpecialization,
          'resumeURL': null,
          'studProgram': studentProgram,
          'dept': studentDept,
          'companyID': companyID,
          'supervisorID': supervisorID,
          'intakePeriod': studentIntakePeriod,
        });

        // Clear fields
        studentNameController.clear();
        studentEmailController.clear();
        studentContactNoController.clear();
        studentIDController.clear();
        studentProgramController.clear();
        studentSpecializationController.clear();
        studentDeptController.clear();
        studentIntakePeriodController.clear();

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding student: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Student Page"),
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
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Add New Student",
                                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  "Enter the student information below",
                                  style: TextStyle(fontSize: 16, color: Colors.black),
                                ),
                                const SizedBox(height: 32),
                                // Student ID Field
                                TextFormField(
                                  controller: studentIDController,
                                  decoration: InputDecoration(
                                    labelText: "Student ID",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: const Icon(Icons.group),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Please enter the student ID.";
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
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
                                // Dept Field
                                DropdownButtonFormField<String>(
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
                                  value: selectedDept,
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      selectedDept = newValue;
                                      studentDept = newValue ?? '';
                                      programOptions = departmentProgramMap[selectedDept!] ?? [];
                                      selectedProgram = null;
                                      specializationOptions = [];
                                      studentSpecialization = '';
                                      selectedSupervisorName = null;
                                      supervisorListFuture = fetchSupervisorList();
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Please select a department.";
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                // Program Field
                                DropdownButtonFormField<String>(
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
                                  value: selectedProgram,
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      selectedProgram = newValue;
                                      studentProgram = newValue ?? '';
                                      specializationOptions = programSpecializationMap[selectedProgram!] ?? [];
                                      studentSpecialization = '';
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Please select a program.";
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                // Specialization Field
                                DropdownButtonFormField<String>(
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
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      studentSpecialization = newValue ?? '';
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Please select a specialization.";
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                // Intake Period Field
                                DropdownButtonFormField<String>(
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
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      studentIntakePeriod = newValue ?? '';
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Please select a intake period.";
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                // Supervisor Dropdown
                                FutureBuilder<List<String>>(
                                  future: supervisorListFuture,
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return const CircularProgressIndicator();
                                    } else if (snapshot.hasError) {
                                      return Text('Error: ${snapshot.error}');
                                    } else if (snapshot.hasData) {
                                      List<String> supervisors = snapshot.data ?? [];
                                      return DropdownButtonFormField<String>(
                                        decoration: InputDecoration(
                                          labelText: "Supervisor",
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          prefixIcon: const Icon(Icons.person),
                                        ),
                                        items: supervisors.map<DropdownMenuItem<String>>((String value) {
                                          return DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(value),
                                          );
                                        }).toList(),
                                        value: selectedSupervisorName,
                                        onChanged: (String? newValue) {
                                          setState(() {
                                            selectedSupervisorName = newValue ?? '';
                                          });
                                        },
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return "Please select one option.";
                                          }
                                          return null;
                                        },
                                      );
                                    } 
                                    return const Text('No supervisors found');
                                  },
                                ),
                                const SizedBox(height: 16),
                                // Working Company Dropdown
                                FutureBuilder<List<String>>(
                                  future: companyListFuture,
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return const CircularProgressIndicator();
                                    } else if (snapshot.hasError) {
                                      return Text('Error: ${snapshot.error}');
                                    } else if (snapshot.hasData) {
                                      List<String> companies = snapshot.data ?? [];
                                      return DropdownButtonFormField<String>(
                                        decoration: InputDecoration(
                                          labelText: "Working Company",
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          prefixIcon: const Icon(Icons.business),
                                        ),
                                        items: companies.map<DropdownMenuItem<String>>((String value) {
                                          return DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(value),
                                          );
                                        }).toList(),
                                        onChanged: (String? newValue) {
                                          setState(() {
                                            selectedCompanyName = newValue ?? '';
                                          });
                                        },
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return "Please select one option.";
                                          }
                                          return null;
                                        },
                                      );
                                    }
                                    return const Text('No companies found');
                                  },
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    _buildButton("Add User", Colors.black, saveUser),
                                    const SizedBox(width: 16),
                                    _buildButton("Cancel", Colors.redAccent, () => Navigator.pop(context)),
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

  Widget _buildButton(String text, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
        backgroundColor: color,
      ),
      child: Text(text, style: const TextStyle(fontSize: 16, color: Colors.white)),
    );
  }
}
