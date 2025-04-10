// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'color.dart';

class AddStudentPage extends StatefulWidget {
  final String userType;
  final VoidCallback refreshCallback;
  const AddStudentPage({super.key, required this.userType, required this.refreshCallback});

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

  PlatformFile? _selectedDocument;
  String? _uploadedFileName;

  List<String> intakes = ['All', 'Jan-Apr 2021', 'May-Aug 2021', 'Sept-Dec 2021', 
                        'Jan-Apr 2022', 'May-Aug 2022', 'Sept-Dec 2022', 
                        'Jan-Apr 2023', 'May-Aug 2023', 'Sept-Dec 2023', 
                        'Jan-Apr 2024', 'May-Aug 2024', 'Sept-Dec 2024', 
                        'Jan-Apr 2025', 'May-Aug 2025', 'Sept-Dec 2025'];

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

  @override
  void initState() {
    super.initState();
    supervisorListFuture = fetchSupervisorList();
    companyListFuture = fetchCompanyNames();
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No document selected.')),
      );
      return null;
    }

    try {
      final fileName = _uploadedFileName ?? DateTime.now().millisecondsSinceEpoch.toString();
      final storageRef = FirebaseStorage.instance.ref().child('letters/$fileName');

      // Determine content type based on file extension
      String fileExtension = fileName.split('.').last.toLowerCase();
      String contentType = 'application/octet-stream'; // Default for unknown types

      if (fileExtension == 'pdf') {
        contentType = 'application/pdf';
      } else if (fileExtension == 'doc') {
        contentType = 'application/msword';
      } else if (fileExtension == 'docx') {
        contentType = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      }

      final metadata = SettableMetadata(contentType: contentType);
      final uploadTask = storageRef.putData(_selectedDocument!.bytes!, metadata);

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload document: $e')),
      );
      return null;
    }
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

      // Check if studID already exists
      QuerySnapshot studentIdSnapshot = await FirebaseFirestore.instance
          .collection('Student')
          .where('studID', isEqualTo: studentIDController.text.trim())
          .get();

      if (studentIdSnapshot.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student ID already exists. Please use a different ID.')),
        );
        return;
      }

      // Check if email already exists
      QuerySnapshot emailSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .where('email', isEqualTo: studentEmailController.text.trim())
          .get();

      if (emailSnapshot.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email is already registered. Please use a different email.')),
        );
        return;
      }

      final documentUrl = await _uploadDocument();

      if (documentUrl == null) {
        return;
      }

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
          'skill': null,
          'letterURL': documentUrl,
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

        widget.refreshCallback();
        Navigator.of(context).pop(true);
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
        automaticallyImplyLeading: true,
        title: const SizedBox.shrink(),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 47, color: Colors.white), // Increase the size and set color
          onPressed: () => Navigator.of(context).pop(), // Default back button action
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
                                const Text("Letter Document:"),
                                const SizedBox(height: 5),
                                ElevatedButton.icon(
                                  onPressed: _pickDocument,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.backgroundCream,
                                    foregroundColor: Colors.white,
                                    elevation: 2,
                                  ),
                                  icon: const Icon(Icons.upload_file, color: Colors.black),
                                  label: Text(_uploadedFileName ?? 'Upload Document', style: const TextStyle(color: Colors.black)),
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
