import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'color.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:url_launcher/url_launcher.dart';

class Assessmentdetail extends StatefulWidget {
  final String assessmentID;
  final String studID;
  const Assessmentdetail({super.key, required this.assessmentID, required this.studID});

  @override
  AssessmentdetailState createState() => AssessmentdetailState();
}

class AssessmentdetailState extends State<Assessmentdetail> {
  String templateTitle = "Loading...";
  String attempt = "Loading...";
  String instruction = "Loading...";
  String duedate = "Loading...";
  String templateID = "Loading...";
  String templateURL = "Loading...";
  String submissionStatus = "Loading...";

  final dateFormat = DateFormat('yyyy-MM-dd');

  PlatformFile? _selectedDocument;
  String? _uploadedFileName;

  @override
  void initState() {
    super.initState();
    fetchAssessmentDetails();
  }

  Future<void> fetchAssessmentDetails() async {
    try {
      var assessmentDoc = await FirebaseFirestore.instance
          .collection('Assessment')
          .doc(widget.assessmentID)
          .get();

      DateTime now = DateTime.now();

      if (assessmentDoc.exists) {
        setState(() {
          attempt = assessmentDoc['submissionURL'] ?? 'No submissionURL';
          
          Timestamp? rawTimestamp = assessmentDoc.data()?['assessmentEndDate'];
          duedate = rawTimestamp != null
              ? dateFormat.format(rawTimestamp.toDate())
              : 'No assessmentEndDate';
          templateID = assessmentDoc['templateID'] ?? 'No templateID';
        });

        Timestamp endDateTimestamp = assessmentDoc['assessmentEndDate'] ?? Timestamp(0, 0);
        DateTime endDate = endDateTimestamp.toDate(); 

        // Determine submission status
        submissionStatus = endDate.isBefore(now) ? 'Due' : 'Active';

        // Fetch company details using the userID
        var templateDoc = await FirebaseFirestore.instance
            .collection('Template')
            .doc(templateID)
            .get();

        if (templateDoc.exists) {
          setState(() {
            templateTitle = templateDoc['templateTitle'] ?? 'No templateTitle';
            instruction = templateDoc['templateDesc'] ?? 'No templateDesc';
            templateURL = templateDoc['templateURL'] ?? 'No templateURL';
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching job details: $e");
    }
  }

  Future<void> _pickAndUploadDocument() async {
    // Pick file
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

      try {
        if (_selectedDocument == null) {
          throw "No document selected";
        }

        // Prepare upload
        final fileName = _uploadedFileName ?? DateTime.now().millisecondsSinceEpoch.toString();
        final storageRef = FirebaseStorage.instance.ref().child('assessment/$fileName');

        // Determine content type
        String fileExtension = fileName.split('.').last.toLowerCase();
        String contentType = 'application/octet-stream';

        if (fileExtension == 'pdf') {
          contentType = 'application/pdf';
        } else if (fileExtension == 'doc') {
          contentType = 'application/msword';
        } else if (fileExtension == 'docx') {
          contentType = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
        }

        final metadata = SettableMetadata(contentType: contentType);

        // Upload file data
        final uploadTask = storageRef.putData(_selectedDocument!.bytes!, metadata);
        final snapshot = await uploadTask;

        // Get the download URL
        final downloadUrl = await snapshot.ref.getDownloadURL();

        // Update Firestore with URL
        await FirebaseFirestore.instance
            .collection('Assessment')
            .doc(widget.assessmentID) 
            .update({'submissionURL': downloadUrl, 'submissionDate': DateTime.now().toString()});

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload successful')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload document: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No document selected.')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.backgroundCream,
        elevation: 0,
      ),
      backgroundColor: AppColors.backgroundCream,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  templateTitle,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(thickness: 1.2),
                const SizedBox(height: 12),
                // Due Date
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.calendar_month, color: Colors.blue),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Due Date:",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            duedate,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Template
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.file_download, color: Colors.blue),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Template:",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextButton(
                            onPressed: () async {
                              final url = Uri.parse(templateURL);
                              try {
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(url, mode: LaunchMode.externalApplication);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Could not open the template')),
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              alignment: Alignment.centerLeft,
                            ),
                            child: const Text(
                              "Download Template",
                              style: TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.blue,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.description, color: Colors.blue),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Instruction:",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            instruction,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.assignment_turned_in, color: Colors.blue),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Submission:",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 6),
                          attempt.isNotEmpty
                              ? TextButton(
                                  onPressed: () async {
                                    final url = Uri.parse(attempt);
                                    try {
                                      if (await canLaunchUrl(url)) {
                                        await launchUrl(url, mode: LaunchMode.externalApplication);
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Could not open the document')),
                                        );
                                      }
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error: $e')),
                                      );
                                    }
                                  },
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    alignment: Alignment.centerLeft,
                                  ),
                                  child: const Text(
                                    "View Submission",
                                    style: TextStyle(
                                      color: Colors.blue,
                                      decoration: TextDecoration.underline,
                                      decorationColor: Colors.blue,
                                      fontSize: 16,
                                    ),
                                  ),
                                )
                              : const Text(
                                  "No submission",
                                  style: TextStyle(color: Colors.blueGrey, fontSize: 16),
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.timer, color: Colors.blue),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Submission Status:",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            submissionStatus,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Row(
                  children: [
                    Icon(
                      Icons.upload_file,
                      color: Colors.blue,
                    ),
                    SizedBox(width: 10),
                    Text(
                      "Upload Your File",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                ElevatedButton.icon(
                  onPressed: _pickAndUploadDocument,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                  icon: const Icon(Icons.upload, color: Colors.white),
                  label: const Text(
                    "Choose File",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
