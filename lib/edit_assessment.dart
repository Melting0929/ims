// ignore_for_file: deprecated_member_use
import 'package:intl/intl.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditAssessment extends StatefulWidget {
  final String assessmentID;
  final String userId;
  final VoidCallback refreshCallback;
  const EditAssessment({super.key, required this.assessmentID, required this.userId, required this.refreshCallback});

  @override
  State<EditAssessment> createState() => _EditAssessmentState();
}

class _EditAssessmentState extends State<EditAssessment> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController assessmentNameController = TextEditingController();
  final TextEditingController studIDController = TextEditingController();
  final TextEditingController submissionURLController = TextEditingController();
  final TextEditingController intakePeriodController = TextEditingController();
  final TextEditingController assessmentOpenDateController = TextEditingController();
  final TextEditingController assessmentEndDateController = TextEditingController();

  String templateID = '';
  String assessmentName = '';
  String studID = '';
  String intakePeriod = '';
  DateTime? assessmentOpenDate;
  DateTime? assessmentEndDate;

  Future<List<String>>? assessmentListFuture;
  Future<List<String>>? studentListFuture;

  String supervisorID = '';

  @override
  void initState() {
    super.initState();
    fetchSubmissionDetails().then((_) {
      assessmentListFuture = fetchAssessmentNames();
      studentListFuture = fetchStudentIDs();
    });
  }

  Future<void> _pickStartDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: assessmentOpenDate ?? DateTime.now(),
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
    );

    if (pickedDate != null) {
      setState(() {
        assessmentOpenDate = pickedDate;
        assessmentEndDate = null;
        assessmentOpenDateController.text = DateFormat('dd MMM yyyy').format(pickedDate);
      });
    }
  }

  Future<void> _pickEndDate(BuildContext context) async {
    if (assessmentOpenDate == null) {
      // Show a message if the start date is not selected yet
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a start date first.')),
      );
      return;
    }

    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: assessmentEndDate ?? assessmentOpenDate!,
      firstDate: assessmentOpenDate!,
      lastDate: DateTime(2030),
    );

    if (pickedDate != null) {
      setState(() {
        assessmentEndDate = pickedDate;
        assessmentEndDateController.text = DateFormat('dd MMM yyyy').format(pickedDate);
      });
    }
  }

  Future<List<String>> fetchAssessmentNames() async {
    try {
      QuerySnapshot docSnapshot = await FirebaseFirestore.instance
          .collection('Template')
          .get();

      // Extract only template titles as a list of strings
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

  Future<void> fetchSubmissionDetails() async {
  try {
    var assessmentDoc = await FirebaseFirestore.instance
        .collection('Assessment')
        .doc(widget.assessmentID)
        .get();

    if (assessmentDoc.exists) {
      templateID = assessmentDoc.data()?['templateID'] ?? 'No templateID';
      DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
          .collection('Template')
          .doc(templateID)
          .get();

      if (docSnapshot.exists) {
        setState(() {
          var docData = docSnapshot.data() as Map<String, dynamic>?;
          assessmentName = docData?['templateTitle'] ?? 'No Assessment Name';
          studID = assessmentDoc.data()?['studID'] ?? 'No studID';
          intakePeriod = assessmentDoc.data()?['intakePeriod'] ?? 'No intake period';

          assessmentOpenDate = assessmentDoc.data()?['assessmentOpenDate'] is Timestamp
              ? (assessmentDoc.data()?['assessmentOpenDate'] as Timestamp).toDate()
              : null;

          assessmentEndDate = assessmentDoc.data()?['assessmentEndDate'] is Timestamp
              ? (assessmentDoc.data()?['assessmentEndDate'] as Timestamp).toDate()
              : null;

          assessmentNameController.text = assessmentName;
          studIDController.text = studID;
          intakePeriodController.text = intakePeriod;

          assessmentOpenDateController.text =
              assessmentOpenDate != null ? DateFormat('dd MMM yyyy').format(assessmentOpenDate!) : '';

          assessmentEndDateController.text =
              assessmentEndDate != null ? DateFormat('dd MMM yyyy').format(assessmentEndDate!) : '';
        });
      }
    }
  } catch (e) {
    debugPrint("Error fetching assessment details: $e");
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Assessment Page"),
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
                                  "Edit Assessment",
                                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  "Enter the assessment information below",
                                  style: TextStyle(fontSize: 16, color: Colors.black),
                                ),
                                // Assessment Dropdown
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
                                        value: assessmentNameController.text.isNotEmpty ? assessmentNameController.text : null,
                                        decoration: InputDecoration(
                                          labelText: "Assessment",
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
                                            assessmentName = newValue ?? '';
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

                                // Student ID Dropdown
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
                                        value: studIDController.text.isNotEmpty ? studIDController.text : null,
                                        decoration: InputDecoration(
                                          labelText: "Student ID",
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
                                            studID = newValue ?? '';
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
                                    return const Text('No Student ID found');
                                  },
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  value: intakePeriodController.text.isEmpty ? null : intakePeriodController.text,
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
                                      intakePeriod = newValue ?? '';
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
                                // Assessment Start Date Display
                                TextField(
                                  controller: assessmentOpenDateController,
                                  readOnly: true,
                                  decoration: const InputDecoration(
                                    labelText: "Assessment Start Date",
                                    suffixIcon: Icon(Icons.calendar_today),
                                  ),
                                  onTap: () => _pickStartDate(context),
                                ),
                                const SizedBox(height: 16),
                                // Assessment End Date Display
                                TextField(
                                  controller: assessmentEndDateController,
                                  readOnly: true,
                                  decoration: const InputDecoration(
                                    labelText: "Assessment End Date",
                                    suffixIcon: Icon(Icons.calendar_today),
                                  ),
                                  onTap: () => _pickEndDate(context),
                                ),
                                const SizedBox(height: 16),
                                // Save Button
                                Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      ElevatedButton(
                                        onPressed: () async {
                                          if (_formKey.currentState?.validate() ?? false) {
                                            try {
                                              QuerySnapshot templateSnapshot = await FirebaseFirestore.instance
                                                  .collection('Template')
                                                  .where('templateTitle', isEqualTo: assessmentName)
                                                  .get();

                                              if (templateSnapshot.docs.isEmpty) {
                                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Template not found')));
                                                return;
                                              }

                                              String templateID = templateSnapshot.docs.first.id;

                                              var updatedassessmentData = {
                                                'templateID': templateID,
                                                'studID': studID,
                                                'supervisorID': widget.userId,
                                                'submissionURL': '',
                                                'assessmentOpenDate': assessmentOpenDate,
                                                'assessmentEndDate': assessmentEndDate,
                                                'intakePeriod': intakePeriod,
                                                'submissionDate': '',
                                              };

                                              await FirebaseFirestore.instance
                                                  .collection('Assessment')
                                                  .doc(widget.assessmentID)
                                                  .update(updatedassessmentData);
                                              
                                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Assessment updated successfully')));
                                              widget.refreshCallback();
                                              Navigator.of(context).pop(true);
                                            } catch (e) {
                                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update assessment')));
                                              debugPrint("Error updating assessment: $e");
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