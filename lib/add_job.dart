// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddJob extends StatefulWidget {
  final String userId;
  final VoidCallback refreshCallback;
  const AddJob({super.key, required this.userId, required this.refreshCallback});

  @override
  State<AddJob> createState() => _AddJobState();
} 

class _AddJobState extends State<AddJob> {
  final _formKey = GlobalKey<FormState>();
  String jobStatus = '';
  String jobType = '';
  String program = '';
  String userType = '';
  List<String> jobTags = [];

  String selectedCompanyID = '';
  String? selectedCompanyName;
  List<String> companyNames = [];
  Map<String, String> companyMap = {};

  List<String> programs = [
    'Mechanical Engineering',
    'Civil Engineering',
    'Electrical Engineering',
    'Aerospace Engineering',
    'Mechatronics Engineering',
    'Biomedical Engineering',
    'Chemical Engineering',
    'Computer Science',
    'Information Technology',
    'Software Engineering',
    'Cybersecurity',
    'Data Science',
    'Game Development',
    'Business Administration',
    'Finance & Banking',
    'Accounting',
    'Human Resource Management',
    'Supply Chain Management',
    'Entrepreneurship',
    'Digital Marketing',
    'Brand Management',
    'Market Research',
    'Advertising & Media',
    'Mathematics',
    'Physics',
    'Chemistry',
    'Biotechnology',
    'Environmental Science',
    'Medicine',
    'Nursing',
    'Pharmacy',
    'Physiotherapy',
    'Dentistry',
    'Biomedical Science',
    'Graphic Design',
    'Multimedia & Animation',
    'Film & Television Production',
    'Fine Arts',
    'Interior Design',
    'Psychology',
    'Sociology',
    'Political Science',
    'International Relations',
    'Law',
    'Communication & Media Studies',
    'Early Childhood Education',
    'Primary Education',
    'Secondary Education',
    'TESOL',
  ];

  // Text editing controllers
  final TextEditingController jobTitleController = TextEditingController();
  final TextEditingController jobDescController = TextEditingController();
  final TextEditingController jobStatusController = TextEditingController();
  final TextEditingController jobAllowanceController = TextEditingController();
  final TextEditingController jobDurationController = TextEditingController();
  final TextEditingController numApplicantController = TextEditingController();
  final TextEditingController tagsController = TextEditingController();

  RegExp numRegExp = RegExp(r'^\d+$');
  RegExp doubleRegExp = RegExp(r'^\d+(\.\d{1,2})?$');

  @override
  void initState() {
    super.initState();
    fetchUserDetails().then((_) {
      if (userType == 'Admin') {
        fetchCompanyNames();
      }
    });
  }

  Future<void> fetchCompanyNames() async {
    try {
      QuerySnapshot companySnapshot = await FirebaseFirestore.instance
          .collection('Company')
          .where('companyType', isEqualTo: 'External')
          .get();

      List<String> names = [];
      Map<String, String> map = {};

      for (var doc in companySnapshot.docs) {
        String companyName = doc['companyName'];
        String companyID = doc.id;
        names.add(companyName);
        map[companyName] = companyID;
      }

      setState(() {
        companyNames = names;
        companyMap = map;
      });
    } catch (e) {
      debugPrint("Error fetching company names: $e");
    }
  }

  Future<void> fetchUserDetails() async {
    try {
      var userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists) {
        setState(() {
          userType = userDoc.data()?['userType'] ?? 'No userType';
        });
      }
    } catch (e) {
      debugPrint("Error fetching user details: $e");
    }
  }
  
  // Save user to Firestore
  Future<void> saveData() async {
    if (_formKey.currentState!.validate()) {
      if (jobTags.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please add at least one tag before saving.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (userType =='Company') {
        jobType = 'Registered';
        try {
          var companyDoc = await FirebaseFirestore.instance
              .collection('Company')
              .where('userID', isEqualTo: widget.userId)
              .get();

          if (companyDoc.docs.isNotEmpty) {
            setState(() {
              selectedCompanyID = companyDoc.docs.first.id;
            });
          }
        } catch (e) {
          print("Error fetching company data: $e");
        }
      } else {
        jobType = 'External';
        try {
          selectedCompanyID = companyMap[selectedCompanyName] ?? '';

          if (selectedCompanyID.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please select a company before saving.'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
        } catch (e) {
          print("Error fetching company data: $e");
        }
      }

      Map<String, dynamic> jobData = {
        'jobTitle': jobTitleController.text.trim(),
        'jobDesc': jobDescController.text.trim(),
        'jobType': jobType,
        'program': program,
        'jobStatus': jobStatus,
        'jobAllowance': double.tryParse(jobAllowanceController.text.trim()) ?? 0.0,
        'jobDuration': int.tryParse(jobDurationController.text.trim()) ?? 0,
        'numApplicant': int.tryParse(numApplicantController.text.trim()) ?? 0,
        'tags': jobTags,
        'companyID': selectedCompanyID,
        'userID': widget.userId,
      };

      try {
        await FirebaseFirestore.instance.collection('Job').add(jobData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job added successfully!')),
        );

        // Clear fields
        jobTitleController.clear();
        jobDescController.clear();
        jobStatusController.clear();
        jobAllowanceController.clear();
        jobDurationController.clear();
        numApplicantController.clear();
        tagsController.clear();

        widget.refreshCallback();
        Navigator.of(context).pop(true);

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding job: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Job Posting Page"),
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
                                  "Add New Job Posting",
                                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  "Enter the job information below",
                                  style: TextStyle(fontSize: 16, color: Colors.black),
                                ),
                                const SizedBox(height: 32),
                                if (userType == 'Admin') ...[
                                  const Text(
                                    "Company:",
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
                                        value: selectedCompanyName,
                                        onChanged: (newValue) {
                                          setState(() {
                                            selectedCompanyName = newValue!;
                                          });
                                        },
                                        items: companyNames.map((status) {
                                          return DropdownMenuItem(
                                            value: status,
                                            child: Text(status),
                                          );
                                        }).toList(),
                                        icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                                        dropdownColor: Colors.white,
                                        style: const TextStyle(color: Colors.black, fontSize: 14),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: jobTitleController,
                                  decoration: InputDecoration(
                                    labelText: "Job Title",
                                    hintText: "Enter the job title",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: const Icon(Icons.title),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Please enter the job title.";
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: jobDescController,
                                  decoration: InputDecoration(
                                    labelText: "Job Description",
                                    hintText: "Enter the job description",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: const Icon(Icons.description),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Please enter the job description.";
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  value: jobStatusController.text.isEmpty ? null : jobStatusController.text, 
                                  decoration: InputDecoration(
                                    labelText: "Job Status",
                                    hintText: "Select the Job Status",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: const Icon(Icons.person_search),
                                  ),
                                  items: <String>['Accepting', 'Closed'] 
                                      .map<DropdownMenuItem<String>>((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    jobStatus = newValue ?? '';
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Please select a valid job status.";
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: jobAllowanceController,
                                  decoration: InputDecoration(
                                    labelText: "Job Allowance (in RM)",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: const Icon(Icons.paid),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty || !doubleRegExp.hasMatch(value)) {
                                      return "Please enter a valid job allowance (e.g. 800.00).";
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: jobDurationController,
                                  decoration: InputDecoration(
                                    labelText: "Job Duration (in months)",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: const Icon(Icons.calendar_month),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty || !numRegExp.hasMatch(value)) {
                                      return "Please enter a valid job duration (e.g. 3).";
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: numApplicantController,
                                  decoration: InputDecoration(
                                    labelText: "Number of Applicant Needed",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: const Icon(Icons.group),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty || !numRegExp.hasMatch(value)) {
                                      return "Please enter a valid number of applicant needed (e.g. 3).";
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  "Desired Candidate Program:",
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: const Icon(Icons.school),
                                  ),
                                  hint: const Text("Select a program"),
                                  items: programs
                                      .map<DropdownMenuItem<String>>((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      program = newValue ?? '';
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Please select a desired student program.";
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  "Assign Job Tags",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  children: jobTags
                                    .map((tag) => Chip(
                                        label: Text(tag),
                                        onDeleted: () {
                                          setState(() {
                                            jobTags.remove(tag);
                                          });
                                        },
                                      ))
                                  .toList(),
                                ),
                                if (jobTags.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    "Please add at least one tag.",
                                    style: TextStyle(color: Colors.red, fontSize: 14),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: tagsController,
                                  decoration: InputDecoration(
                                    labelText: "Add Tag",
                                    hintText: "Enter a tag and press Add",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: const Icon(Icons.tag),
                                    suffixIcon: IconButton(
                                      icon: const Icon(Icons.add),
                                      onPressed: () {
                                      if (tagsController.text.trim().isNotEmpty) {
                                          setState(() {
                                            jobTags.add(tagsController.text.trim());
                                            tagsController.clear();
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    _buildButton("Add Job Posting", Colors.black, saveData),
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
