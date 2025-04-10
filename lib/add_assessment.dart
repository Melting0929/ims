// ignore_for_file: deprecated_member_use
import 'package:intl/intl.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddAssessment extends StatefulWidget {
  final String userId;
  final VoidCallback refreshCallback;
  const AddAssessment({super.key, required this.userId, required this.refreshCallback});

  @override
  State<AddAssessment> createState() => _AddAssessmentState();
}

class _AddAssessmentState extends State<AddAssessment> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;

  Future<List<String>>? assessmentListFuture;
  Future<List<String>>? studentListFuture;

  String selectedAssessmentName = '';
  String selectedStudentID = '';
  String selectedIntakePeriod = '';

  String supervisorID = '';

  @override
  void initState() {
    super.initState();
    assessmentListFuture = fetchAssessmentNames();
    studentListFuture = fetchStudentIDs();
  }

  Future<void> _pickStartDate(BuildContext context) async {
    DateTime? pickedStartDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
    );

    if (pickedStartDate != null) {
      setState(() {
        _selectedStartDate = DateTime(
          pickedStartDate.year, 
          pickedStartDate.month, 
          pickedStartDate.day,
        );
        _selectedEndDate = null;
      });
    }
  }

  Future<void> _pickEndDate(BuildContext context) async {
    if (_selectedStartDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a start date first.')),
      );
      return;
    }

    DateTime? pickedEndDate = await showDatePicker(
      context: context,
      initialDate: _selectedEndDate ?? _selectedStartDate!,
      firstDate: _selectedStartDate!,
      lastDate: DateTime(2030),
    );

    if (pickedEndDate != null) {
      setState(() {
        _selectedEndDate = DateTime(
          pickedEndDate.year, 
          pickedEndDate.month, 
          pickedEndDate.day,
        );
      });
    }
  }

  Future<List<String>> fetchAssessmentNames() async {
    try {
      QuerySnapshot docSnapshot = await FirebaseFirestore.instance
          .collection('Template')
          .get();

      List<String> templateTitles = docSnapshot.docs
          .map((doc) => doc['templateTitle']?.toString() ?? '')
          .where((title) => title.isNotEmpty)
          .toList();

      return templateTitles;
    } catch (e) {
      print('Error retrieving assessment data: $e');
      return [];
    }
  }

  Future<List<String>> fetchStudentIDs() async {
    try {
      var supervisorDoc = await FirebaseFirestore.instance
          .collection('Supervisor')
          .where('userID', isEqualTo: widget.userId)
          .get();
      
      if (supervisorDoc.docs.isNotEmpty) {
        var supervisorData = supervisorDoc.docs.first.data();
        setState(() {
          supervisorID = supervisorData['supervisorID'] ?? 'No ID';
        });
      } 

      QuerySnapshot docSnapshot = await FirebaseFirestore.instance
          .collection('Student')
          .where('supervisorID', isEqualTo: supervisorID)
          .get();
  
      List<String> studIDs = docSnapshot.docs.map((doc) {
        return doc['studID']?.toString() ?? '';
      }).toList();
  
      return studIDs;
    } catch (e) {
      print('Error retrieving studIDs data: $e');
      return [];
    }
  }

  Future<void> saveData() async {
    if (_formKey.currentState!.validate()) {
      String templateTitle = selectedAssessmentName;
      try {
        QuerySnapshot templateSnapshot = await FirebaseFirestore.instance
            .collection('Template')
            .where('templateTitle', isEqualTo: templateTitle)
            .get();

        String templateID = templateSnapshot.docs.first.id;

        // Validate fields before adding to Firestore
        if (_selectedStartDate == null ||
            _selectedEndDate == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: All fields must be filled')),
          );
          return;
        }

        Map<String, dynamic> assessmentData = {
          'templateID': templateID,
          'studID': selectedStudentID,
          'supervisorID': widget.userId,
          'submissionURL': '',
          'assessmentOpenDate': _selectedStartDate,
          'assessmentEndDate': _selectedEndDate,
          'intakePeriod': selectedIntakePeriod,
          'submissionDate': '',
        };

        await FirebaseFirestore.instance.collection('Assessment').add(assessmentData);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assessment added successfully!')),
        );

        widget.refreshCallback();
        Navigator.of(context).pop(true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving data: $e')),
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
                                  "Add New Assessment",
                                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  "Enter the assessment information below",
                                  style: TextStyle(fontSize: 16, color: Colors.black),
                                ),
                                const SizedBox(height: 32),
                                FutureBuilder<List<String>>(
                                  future: assessmentListFuture,
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return const CircularProgressIndicator();
                                    } else if (snapshot.hasError) {
                                      return Text('Error: ${snapshot.error}');
                                    } else if (snapshot.hasData) {
                                      List<String> assessment = snapshot.data ?? [];
                                      return DropdownButtonFormField<String>(
                                        decoration: InputDecoration(
                                          labelText: "Assessment",
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          prefixIcon: const Icon(Icons.assignment),
                                        ),
                                        items: assessment.map<DropdownMenuItem<String>>((String value) {
                                          return DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(value),
                                          );
                                        }).toList(),
                                        onChanged: (String? newValue) {
                                          setState(() {
                                            selectedAssessmentName = newValue ?? '';
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
                                    return const Text('No Assessment found');
                                  },
                                ),
                                const SizedBox(height: 16),
                                FutureBuilder<List<String>>(
                                  future: studentListFuture,
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return const CircularProgressIndicator();
                                    } else if (snapshot.hasError) {
                                      return Text('Error: ${snapshot.error}');
                                    } else if (snapshot.hasData) {
                                      List<String> student = snapshot.data ?? [];
                                      return DropdownButtonFormField<String>(
                                        decoration: InputDecoration(
                                          labelText: "Student ID",
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          prefixIcon: const Icon(Icons.person),
                                        ),
                                        items: student.map<DropdownMenuItem<String>>((String value) {
                                          return DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(value),
                                          );
                                        }).toList(),
                                        onChanged: (String? newValue) {
                                          setState(() {
                                            selectedStudentID = newValue ?? '';
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
                                    return const Text('No studID found');
                                  },
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  decoration: InputDecoration(
                                    labelText: "Internship Intake Period",
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
                                      selectedIntakePeriod = newValue ?? '';
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
                                Text(
                                  _selectedStartDate == null
                                      ? "Assessment Start Date: No date selected"
                                      : "Selected Date: ${DateFormat('yyyy-MM-dd').format(_selectedStartDate!)}",
                                  style: const TextStyle(fontSize: 18),
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: () => _pickStartDate(context),
                                  child: const Text("Pick a Start Date"),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _selectedEndDate == null
                                      ? "Assessment End Date: No date selected"
                                      : "Selected Date: ${DateFormat('yyyy-MM-dd').format(_selectedEndDate!)}",
                                  style: const TextStyle(fontSize: 18),
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: () => _pickEndDate(context),
                                  child: const Text("Pick a Due Date"),
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    _buildButton("Add Assessment", Colors.black, saveData),
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