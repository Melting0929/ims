// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditJob extends StatefulWidget {
  final String jobId;
  final VoidCallback refreshCallback;
  const EditJob({super.key, required this.jobId, required this.refreshCallback});

  @override
  EditJobTab createState() => EditJobTab();
}

class EditJobTab extends State<EditJob> {
  final formKey = GlobalKey<FormState>();

  String jobID = "Loading...";
  String jobTitle = "Loading...";
  String jobDesc = 'Loading...';
  String jobType = "Loading...";
  String jobStatus = "Loading...";
  String program = "Loading...";

  double jobAllowance = 0.0;
  int jobDuration = 0;
  int numApplicant = 0;

  List<String> jobTags = [];

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
  final TextEditingController jobIDController = TextEditingController();
  final TextEditingController jobTitleController = TextEditingController();
  final TextEditingController jobDescController = TextEditingController();
  final TextEditingController jobTypeController = TextEditingController();
  final TextEditingController jobStatusController = TextEditingController();
  final TextEditingController jobAllowanceController = TextEditingController();
  final TextEditingController jobDurationController = TextEditingController();
  final TextEditingController numApplicantController = TextEditingController();
  final TextEditingController tagController = TextEditingController();

  RegExp numRegExp = RegExp(r'^\d+$');
  RegExp doubleRegExp = RegExp(r'^\d+(\.\d{1,2})?$');

  @override
  void initState() {
    super.initState();
    fetchJobDetails();
  }

  Future<void> fetchJobDetails() async {
    try {
      var jobDoc = await FirebaseFirestore.instance
          .collection('Job')
          .doc(widget.jobId)
          .get();

      if (jobDoc.exists) {
        setState(() {
          jobID = widget.jobId;
          jobTitle = jobDoc.data()?['jobTitle'] ?? 'No jobTitle';
          jobDesc = jobDoc.data()?['jobDesc'] ?? 'No jobDesc';
          jobType = jobDoc.data()?['jobType'] ?? 'No jobType';
          jobStatus = jobDoc.data()?['jobStatus'] ?? 'No jobStatus';
          jobAllowance = (jobDoc.data()?['jobAllowance'] as num?)?.toDouble() ?? 0.0;
          jobDuration = (jobDoc.data()?['jobDuration'] as num?)?.toInt() ?? 0;
          numApplicant = (jobDoc.data()?['numApplicant'] as num?)?.toInt() ?? 0;
          jobTags = List<String>.from(jobDoc.data()?['tags'] ?? []);

          // Set the values to the controllers
          jobIDController.text = jobID;
          jobTitleController.text = jobTitle;
          jobDescController.text = jobDesc;
          jobTypeController.text = jobType;
          jobStatusController.text = jobStatus;
          jobAllowanceController.text = jobAllowance.toStringAsFixed(2);
          jobDurationController.text = jobDuration.toString();
          numApplicantController.text = numApplicant.toString();
        });
      }
    } catch (e) {
      debugPrint("Error fetching job details: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Job Posting Page"),
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
                                  "Edit Job Posting",
                                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  "Enter the job information below",
                                  style: TextStyle(fontSize: 16, color: Colors.black),
                                ),
                                const SizedBox(height: 32),
                                TextFormField(
                                  controller: jobIDController,
                                  enabled: false,
                                  decoration: InputDecoration(
                                    labelText: "Job ID",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: const Icon(Icons.assignment),
                                  ),
                                ),
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
                                  maxLines: 5, // Allows up to 5 lines for longer text input
                                  keyboardType: TextInputType.multiline, // Enables multiline input
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Please enter the job description.";
                                    } else if (value.length < 20) {
                                      return "The description should be at least 20 characters long.";
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
                                      return "Please enter a valid job duration (e.g. 3 months).";
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
                                    if (value == null || value.isEmpty|| !numRegExp.hasMatch(value)) {
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
                                  controller: tagController,
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
                                      if (tagController.text.trim().isNotEmpty) {
                                          setState(() {
                                            jobTags.add(tagController.text.trim());
                                            tagController.clear();
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 32),
                                // Save Button
                                Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      ElevatedButton(
                                        onPressed: () async {
                                          if (formKey.currentState?.validate() ?? false) {
                                            if (jobTags.isEmpty) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Please add at least one tag before saving.'),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                              return;
                                            }

                                            // Get values from form fields
                                            String updatedTitle = jobTitleController.text;
                                            String updatedDesc = jobDescController.text;

                                            double updatedJobAllowance = double.tryParse(jobAllowanceController.text) ?? 0.0;
                                            int updatedJobDuration = int.tryParse(jobDurationController.text.trim()) ?? 0;
                                            int updatedNumApplicant = int.tryParse(numApplicantController.text.trim()) ?? 0;

                                            // Update Firestore data
                                            try {
                                              var updatedData = {
                                                'jobTitle': updatedTitle,
                                                'jobDesc': updatedDesc,
                                                'jobStatus': jobStatus,
                                                'jobAllowance': updatedJobAllowance,
                                                'jobDuration': updatedJobDuration,
                                                'numApplicant': updatedNumApplicant,
                                                'tags': jobTags,
                                                'program': program,
                                              };

                                              await FirebaseFirestore.instance
                                                  .collection('Job')
                                                  .doc(widget.jobId)
                                                  .update(updatedData);

                                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Job updated successfully')));
                                              widget.refreshCallback();
                                              Navigator.of(context).pop(true);
                                            } catch (e) {
                                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update job')));
                                              debugPrint("Error updating job: $e");
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