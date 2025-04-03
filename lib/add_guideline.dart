// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'color.dart';

class AddGuideline extends StatefulWidget {
  final VoidCallback refreshCallback;
  const AddGuideline({super.key, required this.refreshCallback});

  @override
  State<AddGuideline> createState() => _AddGuidelineState();
}

class _AddGuidelineState extends State<AddGuideline> {
  final _formKey = GlobalKey<FormState>();

  // Text editing controllers
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  final TextEditingController accessTypeController = TextEditingController();

  PlatformFile? _selectedDocument;
  String? _uploadedFileName;

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
      final storageRef = FirebaseStorage.instance.ref().child('guidelines/$fileName');

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

  // Save Data to Firestore and Storage
  Future<void> saveData() async {
    if (_formKey.currentState!.validate()) {
      final documentUrl = await _uploadDocument();

      if (documentUrl == null) {
        return;
      }

      Map<String, dynamic> guidelineData = {
        'title': titleController.text.trim(),
        'guidelineURL': documentUrl,
        'desc': descController.text.trim(),
        'accessType': accessTypeController.text.trim(),
        'uploadedAt': FieldValue.serverTimestamp(),
      };

      try {
        await FirebaseFirestore.instance.collection('Guideline').add(guidelineData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Guideline added successfully!')),
        );

        // Clear fields
        titleController.clear();
        descController.clear();
        accessTypeController.clear();
        setState(() {
          _selectedDocument = null;
          _uploadedFileName = null;
        });
        widget.refreshCallback();
        Navigator.of(context).pop(true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding guideline: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Guideline Page"),
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
                                  "Add New Guideline",
                                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  "Enter the guideline information below",
                                  style: TextStyle(fontSize: 16, color: Colors.black),
                                ),
                                const SizedBox(height: 32),
                                TextFormField(
                                  controller: titleController,
                                  decoration: InputDecoration(
                                    labelText: "Guideline Title",
                                    hintText: "Enter the guideline title",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: const Icon(Icons.title),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Please enter the guideline title.";
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: descController,
                                  decoration: InputDecoration(
                                    labelText: "Guideline Description",
                                    hintText: "Enter the guideline description",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: const Icon(Icons.description),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Please enter the guideline description.";
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                const Text("Guideline Document:"),
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
                                DropdownButtonFormField<String>(
                                  value: accessTypeController.text.isEmpty ? null : accessTypeController.text,
                                  decoration: InputDecoration(
                                    labelText: "Access Type",
                                    hintText: "Select the access type",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: const Icon(Icons.security),
                                  ),
                                  items: <String>['Supervisor', 'Student', 'Company']
                                      .map<DropdownMenuItem<String>>((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    if (newValue != null) {
                                      setState(() {
                                        accessTypeController.text = newValue;
                                      });
                                    }
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Please select a valid access type.";
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    _buildButton("Add Guideline", Colors.black, saveData),
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