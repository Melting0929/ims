// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'color.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class EditGuideline extends StatefulWidget {
  final String docId;
  final VoidCallback refreshCallback;
  const EditGuideline({super.key, required this.docId, required this.refreshCallback});

  @override
  EditGuidelineTab createState() => EditGuidelineTab();
}

class EditGuidelineTab extends State<EditGuideline> {
  final formKey = GlobalKey<FormState>();

  String title = "Loading...";
  String accessType = "Loading...";
  String desc = 'Loading...';
  String? currentFileUrl; 

  final TextEditingController titleController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  final TextEditingController accessTypeController = TextEditingController();

  PlatformFile? _selectedDocument;
  String? _uploadedFileName;

  @override
  void initState() {
    super.initState();
    fetchGuidelineDetails();
  }

  // Fetch guideline details and current file URL
  Future<void> fetchGuidelineDetails() async {
    try {
      var guidelineDoc = await FirebaseFirestore.instance
          .collection('Guideline')
          .doc(widget.docId)
          .get();

      if (guidelineDoc.exists) {
        setState(() {
          title = guidelineDoc.data()?['title'] ?? 'No title';
          accessType = guidelineDoc.data()?['accessType'] ?? 'No accessType';
          desc = guidelineDoc.data()?['desc'];
          currentFileUrl = guidelineDoc.data()?['guidelineURL'];

          titleController.text = title;
          accessTypeController.text = accessType;
          descController.text = desc;
        });
      }
    } catch (e) {
      debugPrint("Error fetching guideline details: $e");
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
      return currentFileUrl; 
    }

    try {
      final fileName = _uploadedFileName ?? DateTime.now().millisecondsSinceEpoch.toString();
      final storageRef = FirebaseStorage.instance.ref().child('guidelines/$fileName');

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
                              key: formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Edit Guideline",
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
                                  const SizedBox(height: 10.0),
                                  const Text("Current Guideline Document:"),
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
                                  const SizedBox(height: 20.0),
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
                                      accessType = newValue ?? '';
                                    },
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return "Please select a valid access type.";
                                      }
                                      return null;
                                    },
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
                                              String updatedTitle = titleController.text;
                                              String updatedDesc = descController.text;

                                              // Upload new document if selected
                                              String? newFileUrl = await _uploadDocument();

                                              try {
                                                if (_selectedDocument != null && currentFileUrl != null) {
                                                  // Delete old document only if a new document was uploaded
                                                  final oldFileRef = FirebaseStorage.instance.refFromURL(currentFileUrl!);
                                                  await oldFileRef.delete();
                                                  debugPrint("Old document deleted.");
                                                }

                                                // Update Firestore
                                                await FirebaseFirestore.instance.collection('Guideline').doc(widget.docId).update({
                                                  'title': updatedTitle,
                                                  'desc': updatedDesc,
                                                  'guidelineURL': newFileUrl, // Only updates if a new file was selected
                                                  'accessType': accessType,
                                                });

                                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Guideline updated successfully')));
                                                widget.refreshCallback();
                                                Navigator.of(context).pop(true);
                                              } catch (e) {
                                                debugPrint("Error updating guideline: $e");
                                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update guideline')));
                                              }
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                                            backgroundColor: Colors.redAccent,
                                          ),
                                          child: const Text("Save Changes", style: TextStyle(fontSize: 16, color: Colors.white)),
                                        ),
                                        const SizedBox(width: 16),
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.pop(context, true);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                                            backgroundColor: Colors.black,
                                          ),
                                          child: const Text("Cancel", style: TextStyle(fontSize: 16, color: Colors.white)),
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