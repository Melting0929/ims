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
  bool _isOfferLetterMissing = false;


  List<String> companyIndustries = [
    'Information Technology',
    'Software Development',
    'Healthcare',
    'Finance',
    'Education',
    'Manufacturing',
    'Construction',
    'Real Estate',
    'Telecommunications',
    'Marketing & Advertising',
    'Automotive',
    'E-commerce',
    'Energy & Utilities',
    'Hospitality',
    'Transportation & Logistics',
    'Media & Entertainment',
    'Insurance',
    'Pharmaceuticals',
    'Food & Beverage',
    'Retail Store',
    'Tourism',
    'Non-Profit',
    'Government & Public Sector',
    'Legal Services',
    'Consulting',
    'Research & Development',
    'Architecture',
    'Agriculture',
    'Electronics',
    'Fashion & Apparel',
    'Sports & Recreation',
    'Financial Services',
    'Aerospace & Defense',
    'Biotechnology',
    'Chemicals',
    'Marine & Shipping',
    'Wholesale & Distribution',
    'Human Resources',
    'Security Services',
    'Art & Design',
    'Environmental Services',
    'Healthcare Services',
    'IT Services',
    'Logistics & Supply Chain',
    'Media Production',
    'Event Management',
  ];

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
  RegExp yearRegExp = RegExp(r'^(1|2)\d{3}$');
  RegExp empNoRegExp = RegExp(r'^[0-9]+$');
  //RegExp numRegExp = RegExp(r'^\d+$');
  RegExp durRegExp = RegExp(r'^[3-6]$');

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
    if (_selectedDocument == null) {
      setState(() {
        _isOfferLetterMissing = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload the offer letter.')),
      );
      return;
    } else {
      setState(() {
        _isOfferLetterMissing = false;
      });
    }

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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: const SizedBox.shrink(),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 30, color: Colors.white),
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
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Apply External Company",
                                  style: TextStyle(
                                    fontSize: isMobile ? 22 : 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Enter the information below",
                                  style: TextStyle(
                                    fontSize: isMobile ? 14 : 16,
                                    color: Colors.black,
                                  ),
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
                                  items: companyIndustries
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
                                  validator: (value) =>
                                      value == null || value.isEmpty ? "Please select an industry." : null,
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(jobTitleController, "Job Title", Icons.title),
                                const SizedBox(height: 16),
                                _buildTextField(jobDurationController, "Job Duration (in months)", Icons.timer, isDur: true),
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
                                  label: Text(
                                    _uploadedFileName ?? 'Upload Document',
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                ),
                                if (_isOfferLetterMissing)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      "Please upload the offer letter.",
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                const SizedBox(height: 24),
                                Wrap(
                                  spacing: 16,
                                  runSpacing: 8,
                                  alignment: WrapAlignment.end,
                                  children: [
                                    _buildButton("Apply", Colors.black, saveData),
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
      {bool isMultiline = false, bool isEmail = false, bool isPhone = false, bool isYear = false, bool isEmp = false, bool isRegister = false, bool isDur = false, int minLength = 0, String? hintText}) {
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
        if (isYear && value!.isNotEmpty && !yearRegExp.hasMatch(value)) {
          return "Please enter a valid year (e.g., 2005).";
        }
        if (isEmp && value!.isNotEmpty && !empNoRegExp.hasMatch(value)) {
          return "Please enter a valid number of employees.";
        }
        if (isDur && value!.isNotEmpty && !durRegExp.hasMatch(value)) {
          return "Please enter a valid duration (3-6).";
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
