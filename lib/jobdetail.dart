import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ims/color.dart';
import 'company_detail.dart';

class JobDetail extends StatefulWidget {
  final String jobID;
  final String studID;
  const JobDetail({super.key, required this.jobID, required this.studID});

  @override
  JobDetailState createState() => JobDetailState();
}

class JobDetailState extends State<JobDetail> {
  String userID = "Loading...";
  String jobTitle = "Loading...";
  String jobDesc = "Loading...";
  String jobAllowance = "Loading...";
  String jobDuration = "Loading...";
  String jobStatus = "Loading...";
  String location = "Loading...";
  String companyName = 'Loading';
  String companyAddress = "Loading";
  String logo = "";
  List<String> tags = [];

  bool hasApplied = false;
  String companyID = "Loading...";

  @override
  void initState() {
    super.initState();
    fetchJobDetails().then((_) {
      fetchApplications();
    });
  }

  Future<void> fetchJobDetails() async {
    try {
      var jobDoc = await FirebaseFirestore.instance
          .collection('Job')
          .doc(widget.jobID)
          .get();

      if (jobDoc.exists) {
        setState(() {
          jobTitle = jobDoc.data()?['jobTitle'] ?? 'No jobTitle';
          jobDesc = jobDoc.data()?['jobDesc'] ?? 'No jobDesc';
          jobAllowance = jobDoc.data()?['jobAllowance']?.toString() ?? 'N/A';
          jobDuration = jobDoc.data()?['jobDuration']?.toString() ?? 'N/A';
          jobStatus = jobDoc.data()?['jobStatus'] ?? 'No jobStatus';
          location = jobDoc.data()?['location'] ?? 'Malaysia';
          userID = jobDoc.data()?['userID'] ?? 'No userID';
          tags = List<String>.from(jobDoc.data()?['tags'] ?? []);
        });

        // Fetch company details using the userID
        var companyDoc = await FirebaseFirestore.instance
            .collection('Company')
            .where('userID', isEqualTo: userID)
            .get();

        if (companyDoc.docs.isNotEmpty) {
          var companyData = companyDoc.docs.first.data();
          setState(() {
            companyName = companyData['companyName'] ?? 'No Company Name';
            companyAddress = companyData['companyAddress'] ?? 'No Company Address';
            logo = (companyData['logoURL'] == null || companyData['logoURL'].toString().isEmpty)
                ? 'https://firebasestorage.googleapis.com/v0/b/imsfyp2.firebasestorage.app/o/logos%2FcomanyLogo.jpg?alt=media&token=9eeccbe4-fcde-4b36-b6e8-cec7eece49de'
                : companyData['logoURL'];
            companyID = companyData['companyID'] ?? 'No Company ID';  // Assign companyID
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching job details: $e");
    }
  }

  Future<void> fetchApplications() async {
    try {
      var querySnapshot = await FirebaseFirestore.instance
          .collection('Application')
          .where('studID', isEqualTo: widget.studID)
          .where('jobID', isEqualTo: widget.jobID)
          .get();

      // Check if the user has applied for the job
      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          hasApplied = true;  // User has applied
        });
      } else {
        setState(() {
          hasApplied = false;  // User hasn't applied
        });
      }
    } catch (e) {
      debugPrint("Error fetching applications: $e");
    }
  }

  Future<void> applyForJob() async {
    try {
      // Add application to Firestore
      await FirebaseFirestore.instance.collection('Application').add({
        'studID': widget.studID,
        'jobID': widget.jobID,
        'dateApplied': DateTime.now(),
        'interviewStatus': 'None',
        'applicationStatus': 'Pending',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application submitted successfully!')),
      );
    } catch (e) {
      debugPrint("Error applying for job: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to apply for the job. Please try again.')),
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
            constraints: const BoxConstraints(maxWidth: 600), // Set a max width for centering
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // Align children to the start
              children: [
                Center(
                  child: Image.network(logo, height: 150),
                ),
                const SizedBox(height: 16),
                Text(
                  jobTitle,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CompanyDetailPage(companyId: companyID),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.business, color: Colors.blueAccent),
                      const SizedBox(width: 8),
                      Text(
                        companyName,
                        style: const TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildInfoRow(Icons.location_on, companyAddress),
                _buildInfoRow(Icons.attach_money, "Allowance: RM $jobAllowance"),
                _buildInfoRow(Icons.timer, "Duration: $jobDuration months"),
                _buildInfoRow(Icons.group, "Location: $location"),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8.0,
                  children: tags.map((tag) => Chip(label: Text(tag))).toList(),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Job Description:",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(jobDesc, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 20),
                // Add the button at the bottom
                Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!hasApplied) {
                        // Logic for applying to the job
                        await applyForJob();
                        await fetchApplications(); // Refresh application status
                      } else {
                        // Logic for already applied (optional)
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('You have already applied for this job.')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hasApplied ? Colors.grey : Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      hasApplied ? "Already Applied" : "Apply Now",
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueAccent),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}
