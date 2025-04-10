// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'color.dart';

class EditStudent extends StatefulWidget {
  final String userId;
  final VoidCallback refreshCallback;
  const EditStudent({super.key, required this.userId, required this.refreshCallback});

  @override
  EditStudentTab createState() => EditStudentTab();
}

class EditStudentTab extends State<EditStudent> {
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
  String? selectedCompanyName;
  List<String> supervisorOptions = [];
  List<String> companyOptions = [];

  String? currentFileUrl; 
  PlatformFile? _selectedDocument;
  String? _uploadedFileName;

  List<String> intakes = ['All', 'Jan-Apr 2021', 'May-Aug 2021', 'Sept-Dec 2021', 
                        'Jan-Apr 2022', 'May-Aug 2022', 'Sept-Dec 2022', 
                        'Jan-Apr 2023', 'May-Aug 2023', 'Sept-Dec 2023', 
                        'Jan-Apr 2024', 'May-Aug 2024', 'Sept-Dec 2024', 
                        'Jan-Apr 2025', 'May-Aug 2025', 'Sept-Dec 2025'];


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
    fetchStudentDetails().then((_) {
      fetchSupervisorList();
      fetchCompanyList();
    });
    
  }

    Future<void> _pickDocument() async {
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No document selected.')),
      );
    }
  }

  Future<String?> _uploadDocument() async {
    if (_selectedDocument == null) {
      return currentFileUrl; 
    }

    try {
      final fileName = _uploadedFileName ?? DateTime.now().millisecondsSinceEpoch.toString();
      final storageRef = FirebaseStorage.instance.ref().child('letters/$fileName');

      String fileExtension = fileName.split('.').last.toLowerCase();
      String contentType = 'application/octet-stream';
      if (fileExtension == 'pdf') contentType = 'application/pdf';
      if (fileExtension == 'doc') contentType = 'application/msword';
      if (fileExtension == 'docx') contentType = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';

      final metadata = SettableMetadata(contentType: contentType);
      final uploadTask = storageRef.putData(_selectedDocument!.bytes!, metadata);

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint("Failed to upload document: $e");
      return null;
    }
  }
  
  Future<void> fetchSupervisorList() async {
    try {
      if (studentDept != 'No department') {
        debugPrint('Dept: $studentDept');
        var querySnapshot = await FirebaseFirestore.instance
            .collection('Users')
            .where('userType', isEqualTo: 'Supervisor')
            .get();

        List<String> filteredSupervisorNames = [];

        for (var doc in querySnapshot.docs) {
          var userId = doc.id;

          var supervisorSnapshot = await FirebaseFirestore.instance
              .collection('Supervisor')
              .where('userID', isEqualTo: userId)
              .where('dept', isEqualTo: studentDept)
              .get();

          if (supervisorSnapshot.docs.isNotEmpty) {
            var name = doc.data()['name'] as String;
              filteredSupervisorNames.add(name);
              debugPrint(name);
          }
        }

        if (filteredSupervisorNames.isNotEmpty) {
          setState(() {
            supervisorOptions = filteredSupervisorNames.toSet().toList();
            supervisorOptions.insert(0, 'No Supervisor');
          });
        } else {
          setState(() {
            supervisorOptions = ['No Supervisor'];
          });
        }

        supervisorNameController.clear();
      } else {
        debugPrint("Student department is not set or invalid.");
        setState(() {
          supervisorOptions = ['No Supervisor'];
        });
      }
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
        companyOptions.insert(0, 'No Working Company');

      });
    } catch (e) {
      debugPrint("Error fetching companies: $e");
    }
  }

  // Mapping of departments to their programs
  final Map<String, List<String>> departmentProgramMap = {
    'Engineering': [
      'Mechanical Engineering',
      'Civil Engineering',
      'Electrical Engineering',
      'Aerospace Engineering',
      'Mechatronics Engineering',
      'Biomedical Engineering',
      'Chemical Engineering',
    ],
    'IT': [
      'Computer Science',
      'Information Technology',
      'Cybersecurity',
      'Data Science',
      'Game Development',
    ],
    'Business': [
      'Business Administration',
      'Finance & Banking',
      'Accounting',
      'Human Resource Management',
      'Supply Chain Management',
    ],
    'Marketing': [
      'Digital Marketing',
      'Brand Management',
      'Market Research',
      'Advertising & Media',
    ],
    'Science': [
      'Mathematics',
      'Physics',
      'Chemistry',
      'Biotechnology',
      'Environmental Science',
    ],
    'Health & Medical': [
      'Medicine',
      'Nursing',
      'Pharmacy',
      'Physiotherapy',
      'Dentistry',
      'Biomedical Science',
    ],
    'Arts & Design': [
      'Graphic Design',
      'Multimedia & Animation',
      'Film & Television Production',
      'Fine Arts',
      'Interior Design',
    ],
    'Social Sciences': [
      'Psychology',
      'Sociology',
      'Political Science',
      'International Relations',
      'Law',
      'Communication & Media Studies',
    ],
    'Education': [
      'Early Childhood Education',
      'Primary Education',
      'Secondary Education',
      'TESOL',
    ],
  };

  final Map<String, List<String>> programSpecializationMap = {
    'Mechanical Engineering': ['Automotive Engineering', 'Robotics', 'Thermodynamics'],
    'Civil Engineering': ['Structural Engineering', 'Geotechnical Engineering', 'Construction Management'],
    'Electrical Engineering': ['Power Systems', 'Control Engineering', 'Signal Processing'],
    'Aerospace Engineering': ['Aerodynamics', 'Space Systems', 'Propulsion'],
    'Mechatronics Engineering': ['Automation', 'Embedded Systems', 'Robotics'],
    'Biomedical Engineering': ['Medical Imaging', 'Biomechanics', 'Neuroengineering'],
    'Chemical Engineering': ['Process Engineering', 'Polymer Science', 'Biochemical Engineering'],

    'Computer Science': ['Artificial Intelligence', 'Cybersecurity', 'Cloud Computing'],
    'Information Technology': ['Business Software Development', 'Network Security', 'Software Engineering'],
    'Cybersecurity': ['Ethical Hacking', 'Forensic Computing', 'Network Security', 'Cryptography'],
    'Data Science': ['Machine Learning', 'Big Data Analytics', 'Data Visualization', 'Natural Language Processing'],
    'Game Development': ['Game AI', '3D Modeling & Animation', 'Game Physics', 'VR & AR Development'],

    'Business Administration': ['Entrepreneurship', 'Strategic Management', 'Corporate Leadership'],
    'Finance & Banking': ['Investment Banking', 'Financial Risk Management', 'Wealth Management', 'Corporate Finance'],
    'Accounting': ['Tax Accounting', 'Auditing', 'Forensic Accounting', 'Financial Accounting'],
    'Human Resource Management': ['Employee Relations', 'Talent Management', 'Compensation & Benefits'],
    'Supply Chain Management': ['Logistics', 'Operations Management', 'Procurement'],

    'Digital Marketing': ['SEO & SEM', 'Content Marketing', 'Social Media Marketing'],
    'Brand Management': ['Luxury Brand Management', 'Consumer Behavior', 'Product Branding'],
    'Market Research': ['Data Analytics', 'Consumer Insights', 'Competitive Analysis'],
    'Advertising & Media': ['Creative Advertising', 'Public Relations', 'Media Planning'],

    'Mathematics': ['Applied Mathematics', 'Statistics', 'Computational Mathematics'],
    'Physics': ['Quantum Mechanics', 'Astrophysics', 'Electromagnetism'],
    'Chemistry': ['Organic Chemistry', 'Inorganic Chemistry', 'Physical Chemistry'],
    'Biotechnology': ['Genetics', 'Bioinformatics', 'Industrial Biotechnology'],
    'Environmental Science': ['Climate Science', 'Environmental Policy', 'Sustainability Studies'],

    'Medicine': ['General Practice', 'Cardiology', 'Neurology', 'Pediatrics'],
    'Nursing': ['Critical Care Nursing', 'Geriatric Nursing', 'Pediatric Nursing'],
    'Pharmacy': ['Pharmaceutical Chemistry', 'Clinical Pharmacy', 'Pharmacology'],
    'Physiotherapy': ['Sports Physiotherapy', 'Rehabilitation Therapy', 'Neurological Physiotherapy'],
    'Dentistry': ['Orthodontics', 'Periodontology', 'Prosthodontics'],
    'Biomedical Science': ['Medical Microbiology', 'Immunology', 'Molecular Biology'],

    'Graphic Design': ['UI/UX Design', 'Typography', 'Illustration'],
    'Multimedia & Animation': ['3D Animation', 'Motion Graphics', 'Game Art'],
    'Film & Television Production': ['Cinematography', 'Screenwriting', 'Film Editing'],
    'Fine Arts': ['Sculpture', 'Painting', 'Printmaking'],
    'Interior Design': ['Residential Design', 'Commercial Interior', 'Sustainable Design'],

    'Psychology': ['Clinical Psychology', 'Counseling Psychology', 'Industrial-Organizational Psychology', 'Forensic Psychology'],
    'Sociology': ['Cultural Sociology', 'Urban Sociology', 'Political Sociology'],
    'Political Science': ['Public Policy', 'International Relations', 'Comparative Politics'],
    'International Relations': ['Diplomacy', 'Global Security', 'Human Rights'],
    'Law': ['Criminal Law', 'Corporate Law', 'International Law'],
    'Communication & Media Studies': ['Journalism', 'Broadcasting', 'Public Relations'],

    'Early Childhood Education': ['Montessori Education', 'Child Psychology', 'Curriculum Development'],
    'Primary Education': ['STEM Education', 'Special Education', 'Language Learning'],
    'Secondary Education': ['Mathematics Education', 'Science Education', 'Social Studies Education'],
    'TESOL': ['Applied Linguistics', 'Second Language Acquisition', 'English for Specific Purposes'],
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
            skill = List<String>.from(studentDoc['skill'] ?? []);
            currentFileUrl = studentDoc['letterURL'];
          } else {
            studentID = 'No Student ID';
            studentDept = 'No department';
            studentProgram = 'No Program';
            studentSpecialization = 'No specialization';
            studentIntakePeriod = 'No intake period';
            companyID = 'No working company';
            supervisorID = 'No supervisor';
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
          companyNameController.text = companyName;
          supervisorNameController.text = supervisorName;

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
        title: const Text("Edit Student Profile Page"),
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
                                  "Edit Student",
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
                                  onChanged: (String? newValue) {
                                    setState(() {                      
                                      selectedDept = newValue;
                                      studentDept = newValue ?? '';
                                      programOptions = departmentProgramMap[selectedDept!] ?? [];
                                      selectedProgram = null;
                                      specializationOptions = [];
                                      studentSpecialization = '';
                                      supervisorName = 'No Supervisor';
                                      supervisorOptions = [];
                                      supervisorNameController.clear();
                                      fetchSupervisorList();
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
                                  value: studentIntakePeriod.isEmpty ? null : studentIntakePeriod,
                                  decoration: InputDecoration(
                                    labelText: "Intake Period",
                                    hintText: "Select the intake period",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: const Icon(Icons.date_range),
                                  ),
                                  items: intakes 
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
                                // Supervisor Field
                                DropdownButtonFormField<String>(
                                  value: supervisorName.isEmpty ? null : supervisorName,
                                  decoration: InputDecoration(
                                    labelText: "Supervisor",
                                    hintText: "Select a supervisor",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: const Icon(Icons.supervisor_account),
                                  ),
                                  items: supervisorOptions.map<DropdownMenuItem<String>>((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      supervisorName = newValue ?? '';
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Please select one option.";
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 10.0),
                                const Text("Letter Document:"),
                                const SizedBox(height: 5.0),
                                if (currentFileUrl != null)
                                  GestureDetector(
                                    onTap: () async {
                                      if (currentFileUrl != null && await canLaunchUrl(Uri.parse(currentFileUrl!))) {
                                        await launchUrl(Uri.parse(currentFileUrl!));
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Cannot open the file URL.')),
                                        );
                                      }
                                    },
                                    child: const Text(
                                      'View Current File',
                                      style: TextStyle(
                                        color: Color.fromARGB(255, 14, 118, 203),
                                        decoration: TextDecoration.underline,
                                        decorationColor: Color.fromARGB(255, 14, 118, 203),
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 10.0),
                                ElevatedButton.icon(
                                  onPressed: _pickDocument,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.backgroundCream,
                                    foregroundColor: Colors.white,
                                    elevation: 2,
                                  ),
                                  icon: const Icon(Icons.upload_file, color: Colors.black),
                                  label: Text(_uploadedFileName ?? 'Upload New Document', style: const TextStyle(color: Colors.black)),
                                ),
                                const SizedBox(height: 16),
                                // Company Field
                                DropdownButtonFormField<String>(
                                  value: companyNameController.text.isEmpty ? null : companyNameController.text,
                                  decoration: InputDecoration(
                                    labelText: "Company",
                                    hintText: "Select a company",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: const Icon(Icons.business),
                                  ),
                                  items: companyOptions.map<DropdownMenuItem<String>>((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    selectedCompanyName = newValue ?? '';
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Please select one option.";
                                    }
                                    return null;
                                  },
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
                                            String updatedstudentID = studentIDController.text;

                                            String? newFileUrl = await _uploadDocument();

                                            // Update Firestore data
                                            try {
                                              // Retrieve supervisor document ID
                                              String? supervisorId;
                                              if (supervisorName == "No Supervisor") {
                                                supervisorId = null;
                                              } else if (supervisorID != null) {
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
                                              if (selectedCompanyName == "No Working Company") {
                                                companyId = null;
                                              } else if (companyID != null) {
                                                QuerySnapshot companySnapshot = await FirebaseFirestore.instance
                                                    .collection('Company')
                                                    .where('companyName', isEqualTo: selectedCompanyName)
                                                    .get();

                                                if (companySnapshot.docs.isNotEmpty) {
                                                  companyId = companySnapshot.docs.first.id;
                                                }
                                              }

                                              if (_selectedDocument != null && currentFileUrl != null) {
                                                  // Delete old document only if a new document was uploaded
                                                  final oldFileRef = FirebaseStorage.instance.refFromURL(currentFileUrl!);
                                                  await oldFileRef.delete();
                                                  debugPrint("Old document deleted.");
                                                }

                                              var updatedUserData = {
                                                'name': updatedName,
                                                'email': updatedEmail,
                                                'contactNo': updatedPhone,
                                                'password': updatedPassword,
                                              };

                                              var updatedStudentData = {
                                                'studID': updatedstudentID,
                                                'dept': studentDept,
                                                'studProgram': studentProgram,
                                                'specialization': studentSpecialization,
                                                'intakePeriod': studentIntakePeriod,
                                                'companyID': companyId,
                                                'supervisorID': supervisorId,
                                                'skill': skill,
                                                'letterURL': newFileUrl,
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
                                              widget.refreshCallback();
                                              Navigator.of(context).pop(true);
                                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully')));
                                              
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