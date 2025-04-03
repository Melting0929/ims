// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'color.dart';

class AddExternal extends StatefulWidget {
  final String userId;
  final VoidCallback refreshCallback;
  const AddExternal({super.key, required this.userId, required this.refreshCallback});

  @override
  State<AddExternal> createState() => _AddExternalState();
} 

class _AddExternalState extends State<AddExternal> {
  final _formKey = GlobalKey<FormState>();

  String companyIndustry = '';
  String studID = '';

  PlatformFile? _selectedDocument;
  String? _uploadedFileName;

  // Text editing controllers
  final TextEditingController jobTitleController = TextEditingController();
  final TextEditingController jobDurationController = TextEditingController();
  final TextEditingController companyNameController = TextEditingController();
  final TextEditingController companyAddressController = TextEditingController();
  final TextEditingController companyRegNoController = TextEditingController();
  final TextEditingController companyYearController = TextEditingController();
  final TextEditingController companyIndustryController = TextEditingController();
  final TextEditingController companyEmailController = TextEditingController();
  
  final TextEditingController placementContactNameController = TextEditingController();
  final TextEditingController companyContactNoController = TextEditingController();
  final TextEditingController placementContactEmailController = TextEditingController();
  final TextEditingController placementContactJobTitleController = TextEditingController();

  RegExp emailRegExp = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  RegExp phoneRegExp = RegExp(r'^[0-9\s\-]+$');
  RegExp companyRegNoRegExp = RegExp(r'^[a-zA-Z0-9]+$');
  RegExp yearRegExp = RegExp(r'^(19|20)\d{2}$');
  RegExp empNoRegExp = RegExp(r'^[0-9]+$');
  RegExp numRegExp = RegExp(r'^\d+$');

  @override
  void initState() {
    super.initState();
    fetchStudentDetails();
  }

  Future<void> fetchStudentDetails() async {
    try {
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
    } catch (e) {
      debugPrint("Error fetching student details: $e");
    }
  }

  // Pick Document Function
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
      final storageRef = FirebaseStorage.instance.ref().child('offerletter/$fileName');

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
  
  Future<void> saveData() async {
    if (_formKey.currentState!.validate()) {
      final documentUrl = await _uploadDocument();

      if (documentUrl == null) {
        return;
      }
      try {
        // Generate a new document ID for the admin document
        await FirebaseFirestore.instance.collection('External').add({
          'studID': studID,
          'exCompName': companyNameController.text.trim(),
          'exCompEmail': companyEmailController.text.trim(),
          'exCompAddress': companyAddressController.text.trim(),
          'exCompRegNo': companyRegNoController.text.trim(),
          'exCompYear': companyYearController.text.trim(),
          'exJobTitle': jobTitleController.text.trim(),
          'exJobDuration': jobDurationController.text.trim(),
          'offerLetter': documentUrl,
          'offerLetterUploadedAt': FieldValue.serverTimestamp(),
          'exComIndustry': companyIndustry,
          'exJobType': 'External',
          'externalStatus': 'Pending',
          'placementContactName': placementContactNameController.text.trim().isEmpty ? null : placementContactNameController.text.trim(),
          'placementContactEmail': placementContactEmailController.text.trim().isEmpty ? null : placementContactEmailController.text.trim(),
          'placementContactNo': companyContactNoController.text.trim().isEmpty ? null : companyContactNoController.text.trim(),
          'placementContactJobTitle': placementContactJobTitleController.text.trim().isEmpty ? null : placementContactJobTitleController.text.trim(),
        });

        // Clear fields
        companyNameController.clear();
        companyAddressController.clear();
        companyRegNoController.clear();
        companyYearController.clear();
        companyIndustryController.clear();
        companyEmailController.clear();
        jobTitleController.clear();
        jobDurationController.clear();
        
        placementContactNameController.clear();
        companyContactNoController.clear();
        placementContactEmailController.clear();
        placementContactJobTitleController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application saved successfully'), backgroundColor: Colors.green),
        );

        widget.refreshCallback();
        Navigator.of(context).pop(true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding external: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Apply External Page"),
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
                                  "Apply External Company",
                                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  "Enter the information below",
                                  style: TextStyle(fontSize: 16, color: Colors.black),
                                ),
                                const SizedBox(height: 20),
                                _buildTextField(companyNameController, "Company Name", Icons.apartment_outlined),
                                const SizedBox(height: 16),
                                _buildTextField(placementContactNameController, "Placement Contact Full Name", Icons.people),
                                const SizedBox(height: 16),
                                _buildTextField(placementContactEmailController, "Placement Contact Email", Icons.email, isEmail: true),
                                const SizedBox(height: 16),
                                _buildTextField(placementContactJobTitleController, "Placement Contact Job Title", Icons.work),
                                const SizedBox(height: 16),
                                _buildTextField(companyEmailController, "Company Email", Icons.email, isEmail: true),
                                const SizedBox(height: 16),
                                _buildTextField(companyContactNoController, "Contact Number", Icons.call, isPhone: true),
                                const SizedBox(height: 16),
                                _buildTextField(companyAddressController, "Company Address", Icons.home, isMultiline: true),
                                const SizedBox(height: 16),
                                _buildTextField(companyRegNoController, "Company Registration No", Icons.pin, isRegister: true),
                                const SizedBox(height: 16),
                                _buildTextField(companyYearController, "Company Establish Year", Icons.calendar_month, isYear: true),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  decoration: InputDecoration(
                                    labelText: "Company Industry",
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    prefixIcon: const Icon(Icons.villa),
                                  ),
                                  items: <String>["Software Technology", "Manufacturing", "Retail Store", "E-Commerce"]
                                      .map((String value) => DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(value),
                                          ))
                                      .toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      companyIndustry = newValue ?? '';
                                    });
                                  },
                                  validator: (value) => value == null || value.isEmpty ? "Please select an industry." : null,
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
                                const Text("Offer Letter:"),
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
                                const SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    _buildButton("Apply", Colors.black, saveData),
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

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {bool isMultiline = false, bool isEmail = false, bool isPhone = false, bool isYear = false, bool isEmp = false, bool isRegister = false, int minLength = 0, String? hintText}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        prefixIcon: Icon(icon, color: Colors.black),
        filled: true,
        fillColor: Colors.white.withOpacity(0.2),
      ),
      maxLines: isMultiline ? 5 : 1,
      keyboardType: isMultiline
          ? TextInputType.multiline
          : (isYear || isEmp)
              ? TextInputType.number
              : TextInputType.text,
      style: const TextStyle(color: Colors.black),
      validator: (value) {
        if ((value == null || value.isEmpty) && !isPhone) {
          return "Please enter $label.";
        }
        if (isEmail && value!.isNotEmpty && !emailRegExp.hasMatch(value)) {
          return "Please enter a valid email.";
        }
        if (isPhone && value!.isNotEmpty && !phoneRegExp.hasMatch(value)) {
          return "Please enter a valid contact number.";
        }
        if (isRegister && value!.isNotEmpty && !companyRegNoRegExp.hasMatch(value)) {
          return "Please enter a valid registration number.";
        }
        if (isYear && value!.isNotEmpty && !yearRegExp.hasMatch(value)) {
          return "Please enter a valid year (e.g., 2005).";
        }
        if (isEmp && value!.isNotEmpty && !empNoRegExp.hasMatch(value)) {
          return "Please enter a valid number of employees.";
        }
        if (minLength > 0 && value!.isNotEmpty && value.length < minLength) {
          return "$label should be at least $minLength characters long.";
        }
        return null;
      },
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
