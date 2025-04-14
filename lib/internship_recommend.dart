import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'download_guideline.dart';
import 'manage_external.dart';
import 'assessment.dart';
import 'student_dashboard.dart';
import 'jobdetail.dart';
import 'eprofile_student.dart';
import 'login_web.dart';
import 'login_mobile.dart';
import 'color.dart';

class InternshipRecommend extends StatefulWidget {
  final String userId;
  const InternshipRecommend({super.key, required this.userId});

  @override
  InternshipRecommendState createState() => InternshipRecommendState();
}

class InternshipRecommendState extends State<InternshipRecommend> {
  String studID = '';
  String resumeURL = '';
  String studentEmail = "Loading...";
  String studentName = "Loading...";
  String selectedMenu = "Internship Recommendation Page";
  String extractedText = "Extracted text will appear here...";
  List<String> recommendedJobs = [];
  int currentPage = 0;
  final int jobsPerPage = 5;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchStudentDetails().then((_) {
      processResume();
    });
  }

  bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  Future<void> fetchStudentDetails() async {
    try {
      var userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists) {
        setState(() {
          studentEmail = userDoc.data()?['email'] ?? 'No Email';
          studentName = userDoc.data()?['name'] ?? 'No Name';
        });

        var studentDoc = await FirebaseFirestore.instance
            .collection('Student')
            .where('userID', isEqualTo: widget.userId)
            .get();

        if (studentDoc.docs.isNotEmpty) {
          var studentData = studentDoc.docs.first.data();
          setState(() {
            studID = studentData['studID'] ?? 'No ID';
            resumeURL = studentData['resumeURL'] ?? '';
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching student details: $e");
    }
  }

  Future<void> logout() async {
    bool confirmLogout = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text("Logout"),
          ],
        ),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Logout", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmLogout) {
      await FirebaseAuth.instance.signOut();

      // Redirect based on platform
      if (isMobile(context)) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginTab()),
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginWeb()),
          (Route<dynamic> route) => false, // removes all previous routes
        );
      }
    }
  }

  Widget buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    bool isSelected = selectedMenu == title;
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.black : AppColors.deepYellow),
      title: Text(title, style: TextStyle(color: isSelected ? Colors.black : AppColors.deepYellow)),
      tileColor: isSelected ? AppColors.secondaryYellow : Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: () {
        setState(() {
          selectedMenu = title;
        });
        onTap();
      },
    );
  }
      
  Future<String> extractTextFromPDF(String pdfUrl) async {
    try {
      // Fetch the PDF bytes using HTTP
      var response = await http.get(Uri.parse(pdfUrl));
      if (response.statusCode == 200) {
        Uint8List pdfBytes = response.bodyBytes;

        // Extract text using Syncfusion Flutter PDF
        final PdfDocument document = PdfDocument(inputBytes: pdfBytes);
        String text = PdfTextExtractor(document).extractText();
        document.dispose(); 

        return text;
      } else {
        throw Exception("Failed to fetch PDF: HTTP ${response.statusCode}");
      }
    } catch (e) {
      print("Error: $e");
      throw Exception("Failed to extract text from PDF: $e");
    }
  }
  
  // Plan A: AI Recommendation Model
  Future<void> processResume() async {
    try {
      // 1. Get resume URL from Firestore
      DocumentSnapshot studentDoc = await FirebaseFirestore.instance.collection('Student').doc(studID).get();
      String? resumeURL = studentDoc["resumeURL"];
      if (resumeURL == null) {
        localMatchJobs();
        throw Exception("Resume URL not found.");
      }

      // 2. Extract text from PDF
      extractedText = await extractTextFromPDF(resumeURL);
      setState(() {});

      // 3. Send extracted text to AI Cloud Function
      await fetchRecommendedJobs(extractedText);
    } catch (e) {
      print("Error: $e");
    }
  }
  
  Future<void> fetchRecommendedJobs(String resumeText) async {
    try {
      final response = await http.post(
        Uri.parse("https://recommendjobs-ayekkctrbq-uc.a.run.app"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"resume_text": resumeText}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        List<String> recommendedIDs = List<String>.from(data["recommended_job_ids"]);

        // Fetch all other jobs not in the recommendation list
        QuerySnapshot allJobsSnapshot = await FirebaseFirestore.instance
            .collection('Job')
            .where('jobType', isEqualTo: 'Registered')
            .get();

        List<String> otherJobs = allJobsSnapshot.docs
            .map((doc) => doc.id)
            .where((id) => !recommendedIDs.contains(id))
            .toList();

        // Combine and update state
        setState(() {
          recommendedJobs = [...recommendedIDs, ...otherJobs];
          isLoading = false;
        });
      } else {
        await localMatchJobs();
        throw Exception("AI recommendation failed with status ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("AI recommendation error: $e");
    }
  }

  Future<void> localMatchJobs() async {
    try {
      Set<String> matchedJobIds = {};

      // Step 1: Match jobs based on resume text
      if (resumeURL.isNotEmpty) {
        String extractedText = await extractTextFromPDF(resumeURL);

        // Tokenize the extracted text
        List<String> resumeWords = extractedText
            .toLowerCase()
            .split(RegExp(r'\s+')) // Split by whitespace
            .map((word) => word.replaceAll(RegExp(r'[^\w]'), ''))
            .toList();

        // Fetch jobs from Firestore
        var jobsQuery = await FirebaseFirestore.instance
            .collection('Job')
            .where('jobType', isEqualTo: 'Registered')
            .get();

        for (var job in jobsQuery.docs) {
          var jobData = job.data();
          List<String> jobTags = List<String>.from(jobData['tags'] ?? []);

          // Check if any job tag matches the resume words
          bool hasMatch = jobTags.any((tag) => resumeWords.contains(tag.toLowerCase()));

          if (hasMatch) {
            matchedJobIds.add(job.id); // Add to the Set
          }
        }
      }

      // Step 2: Match jobs based on student skills
      var studentDoc = await FirebaseFirestore.instance.collection('Student').doc(studID).get();

      if (studentDoc.exists) {
        var studentData = studentDoc.data();
        List<String> studentSkills = List<String>.from(studentData?['skill'] ?? []);

        var jobsQuery = await FirebaseFirestore.instance
            .collection('Job')
            .where('jobType', isEqualTo: 'Registered')
            .get();

        for (var job in jobsQuery.docs) {
          var jobData = job.data();
          List<String> jobTags = List<String>.from(jobData['tags'] ?? []);

          // Check if any student skill matches the job tags
          bool skillMatch = studentSkills.any((skill) => jobTags.contains(skill));

          if (skillMatch) {
            matchedJobIds.add(job.id); // Add to the Set
          }
        }
      }

      // Step 3: Match jobs based on student details
      if (studentDoc.exists) {
        var studentData = studentDoc.data();
        String dept = studentData?['dept'] ?? '';
        String specialization = studentData?['specialization'] ?? '';
        String studProgram = studentData?['studProgram'] ?? '';

        var jobsQuery = await FirebaseFirestore.instance
            .collection('Job')
            .where('jobType', isEqualTo: 'Registered')
            .get();

        for (var job in jobsQuery.docs) {
          var jobData = job.data();
          List<String> jobTags = List<String>.from(jobData['tags'] ?? []);

          // Check if any job tag matches the student's details
          bool hasMatch = jobTags.any((tag) =>
              tag.toLowerCase() == dept.toLowerCase() ||
              tag.toLowerCase() == specialization.toLowerCase() ||
              tag.toLowerCase() == studProgram.toLowerCase());

          if (hasMatch) {
            matchedJobIds.add(job.id); // Add to the Set
          }
        }
      }

      // Step 4: Match jobs based on student program
      if (studentDoc.exists) {
        var studentData = studentDoc.data();
        String studProgram = studentData?['studProgram'] ?? '';

        var jobsQuery = await FirebaseFirestore.instance
            .collection('Job')
            .where('jobType', isEqualTo: 'Registered')
            .get();

        for (var job in jobsQuery.docs) {
          var jobData = job.data();
          String jobProgram = jobData['program'] ?? '';

          // Check if the student's program matches the job's program
          if (studProgram.toLowerCase() == jobProgram.toLowerCase()) {
            matchedJobIds.add(job.id); // Add to the Set
          }
        }
      }

      // Step 5: Match jobs based on student dept
      if (studentDoc.exists) {
        var studentData = studentDoc.data();
        String studProgram = studentData?['dept'] ?? '';

        var jobsQuery = await FirebaseFirestore.instance
            .collection('Job')
            .where('jobType', isEqualTo: 'Registered')
            .get();

        for (var job in jobsQuery.docs) {
          var jobData = job.data();
          String jobProgram = jobData['program'] ?? '';

          // Check if the student's program matches the job's program
          if (studProgram.toLowerCase() == jobProgram.toLowerCase()) {
            matchedJobIds.add(job.id); // Add to the Set
          }
        }
      }

      // Step 6: Add remaining jobs not in matchedJobIds
      QuerySnapshot allJobsSnapshot = await FirebaseFirestore.instance
          .collection('Job')
          .where('jobType', isEqualTo: 'Registered')
          .get();

      List<String> otherJobs = allJobsSnapshot.docs
          .map((doc) => doc.id)
          .where((id) => !matchedJobIds.contains(id))
          .toList();

      // Step 7: Update the state with unique matched jobs
      setState(() {
        recommendedJobs = [...matchedJobIds, ...otherJobs];
        isLoading = false;
      });

      if (matchedJobIds.isEmpty) {
        debugPrint("No matching jobs found.");
      } else {
        debugPrint("Matched Job IDs: $matchedJobIds");
      }
    } catch (e) {
      debugPrint("Error matching resume and skills with jobs: $e");
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.backgroundCream, AppColors.secondaryYellow],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.6, 1.0],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        drawer: Drawer(
          child: Column(
            children: [
              // User Info Section
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.backgroundCream, AppColors.secondaryYellow],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.account_circle, size: 40, color: AppColors.deepYellow),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            studentName,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            studentEmail,
                            style: const TextStyle(
                              color: Color.fromARGB(255, 42, 42, 42),
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => EprofileStudent(userId: widget.userId)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),
              const Divider(height: 1, thickness: 1, color: AppColors.secondaryYellow),

              // Menu Items
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(10),
                  children: [
                    buildDrawerItem(
                      icon: Icons.dashboard,
                      title: "Dashboard",
                      onTap: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => StudentDashboard(userId: widget.userId)),
                      ),
                    ),
                    buildDrawerItem(
                      icon: Icons.upload_file,
                      title: "Internship Recommendation Page",
                      onTap: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => InternshipRecommend(userId: widget.userId)),
                      ),
                    ),
                    buildDrawerItem(
                      icon: Icons.upload_file,
                      title: "Assessment Page",
                      onTap: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => Assessment(userId: widget.userId)),
                      ),
                    ),
                    buildDrawerItem(
                      icon: Icons.upload_file,
                      title: "Apply External Company Page",
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ManageExternal(userId: widget.userId)),
                      ),
                    ),
                    buildDrawerItem(
                      icon: Icons.upload_file,
                      title: "Download Document Page",
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => DownloadGuideline(userId: widget.userId)),
                      ),
                    ),
                  ],
                ),
              ),

              // Logout Button
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: ElevatedButton.icon(
                  onPressed: logout,
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text("Logout", style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    minimumSize: const Size(double.infinity, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),

              // Footer Text
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Student Panel v1.0",
                  style: TextStyle(color: Colors.blueGrey[600], fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(left: MediaQuery.of(context).size.width * 0.15),
                child: const Text(
                  "Job Recommendations",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 30),
              Expanded(
                child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : recommendedJobs.isEmpty
                          ? const Center(child: Text("No job recommendations available. Kindly upload your Resume."))
                    : ListView.builder(
                        itemCount: ((currentPage + 1) * jobsPerPage > recommendedJobs.length)
                          ? recommendedJobs.length - currentPage * jobsPerPage
                          : jobsPerPage,
                        itemBuilder: (context, index) {
                          String jobId = recommendedJobs[currentPage * jobsPerPage + index];
                          return FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance.collection('Job').doc(jobId).get(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              var jobData = snapshot.data!.data() as Map<String, dynamic>?;
                              if (jobData == null) return const SizedBox();

                              return Center(
                                child: SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.55, 
                                  child: Card(
                                    color: Colors.white,
                                    margin: const EdgeInsets.symmetric(vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child : Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            jobData['jobTitle'] ?? 'Unknown Job',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          FutureBuilder<QuerySnapshot>(
                                            future: FirebaseFirestore.instance
                                                .collection('Company')
                                                .where('userID', isEqualTo: jobData['userID'])
                                                .limit(1) 
                                                .get(),
                                            builder: (context, companySnapshot) {
                                              if (companySnapshot.connectionState == ConnectionState.waiting) {
                                                return const Text(
                                                  'Loading...',
                                                  style: TextStyle(fontSize: 16, color: Colors.black),
                                                );
                                              }

                                              if (companySnapshot.hasError) {
                                                return const Text(
                                                  'Error fetching company',
                                                  style: TextStyle(fontSize: 16, color: Colors.red),
                                                );
                                              }

                                              if (!companySnapshot.hasData || companySnapshot.data!.docs.isEmpty) {
                                                return const Text(
                                                  'Error: No matching company found',
                                                  style: TextStyle(fontSize: 16, color: Colors.black),
                                                );
                                              }

                                              var companyData = companySnapshot.data!.docs.first.data() as Map<String, dynamic>?;
                                              print("Fetched Company Data: $companyData"); 

                                              String companyName = companyData?['companyName'] ?? 'Unknown Company';

                                              return Text(
                                                companyName,
                                                style: const TextStyle(fontSize: 16, color: Colors.black),
                                              );
                                            },
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            jobData['location'] ?? 'Malaysia',
                                            style: const TextStyle(
                                              fontSize: 15,
                                              color: Colors.black
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Row(
                                            children: [
                                              const Text(
                                                'Skills:',
                                                style: TextStyle(fontSize: 14, color: Colors.blueGrey, fontWeight: FontWeight.bold),
                                              ),
                                              const SizedBox(width: 5),
                                              Expanded(
                                                child: Text(
                                                  (jobData['tags'] is List)
                                                      ? (jobData['tags'] as List).join(', ') // Convert list to comma-separated string
                                                      : (jobData['tags'] ?? 'Unknown Job Tags'),
                                                  style: const TextStyle(fontSize: 14, color: Colors.blueGrey),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: ElevatedButton(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(builder: (context) => JobDetail(studID: studID, jobID: jobId)),
                                                );
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.black,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                              ),
                                              child: const Text("View Details", style: TextStyle(color: Colors.white)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: currentPage > 0
                        ? () {
                            setState(() {
                              currentPage--;
                            });
                          }
                        : null,
                    tooltip: 'Previous Page',
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward, color: Colors.black),
                    onPressed: (currentPage + 1) * jobsPerPage < recommendedJobs.length
                        ? () {
                            setState(() {
                              currentPage++;
                            });
                          }
                        : null,
                    tooltip: 'Next Page',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}