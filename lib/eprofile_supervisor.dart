// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EprofileSupervisor extends StatefulWidget {
  final String userId;
  const EprofileSupervisor({super.key, required this.userId});

  @override
  EprofileSupervisorTab createState() => EprofileSupervisorTab();
}

class EprofileSupervisorTab extends State<EprofileSupervisor> {
  final formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;

  String supervisorEmail = "Loading...";
  String supervisorName = "Loading...";
  String? supervisorContactNo;
  String supervisorPassword = "Loading...";
  String supervisorDept = "Loading...";
  String supervisorID = "Loading...";

  // Text editing controllers
  final TextEditingController supervisorNameController = TextEditingController();
  final TextEditingController supervisorEmailController = TextEditingController();
  final TextEditingController supervisorContactNoController = TextEditingController();
  final TextEditingController supervisorPasswordController = TextEditingController();
  final TextEditingController supervisorDeptController = TextEditingController();
  final TextEditingController supervisorIDController = TextEditingController();

  RegExp emailRegExp = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  RegExp phoneRegExp = RegExp(r'^[0-9\s\-]+$');
  RegExp passwordRegExp = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$');

  @override
  void initState() {
    super.initState();
    fetchSupervisorDetails();
  }

  Future<void> fetchSupervisorDetails() async {
    try {
      var userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.userId)
          .get();
      var supervisorSnapshot = await FirebaseFirestore.instance
          .collection('Supervisor')
          .where('userID', isEqualTo: widget.userId)
          .get();

      if (userDoc.exists) {
        setState(() {
          supervisorEmail = userDoc.data()?['email'] ?? 'No Email';
          supervisorName = userDoc.data()?['name'] ?? 'No Name';
          supervisorContactNo = userDoc.data()?['contactNo'];
          supervisorPassword = userDoc.data()?['password'] ?? 'No Password';

          if (supervisorSnapshot.docs.isNotEmpty) {
          var supervisorDoc = supervisorSnapshot.docs.first.data();
          supervisorDept = supervisorDoc['dept'] ?? 'No department';
          supervisorID = supervisorDoc['supervisorID'] ?? 'No supervisor';
        } else {
          supervisorDept = 'No department';
          supervisorID = 'No supervisor';
        }

          // Set the values to the controllers
          supervisorNameController.text = supervisorName;
          supervisorEmailController.text = supervisorEmail;
          supervisorContactNoController.text = supervisorContactNo ?? '';
          supervisorPasswordController.text = supervisorPassword;
          supervisorDeptController.text = supervisorDept;
          supervisorIDController.text = supervisorID;
        });
      }
    } catch (e) {
      debugPrint("Error fetching supervisor details: $e");
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
                                    "Edit Profile",
                                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    "Enter the your information below",
                                    style: TextStyle(fontSize: 16, color: Colors.black),
                                  ),
                                  const SizedBox(height: 32),
                                  // Supervisor ID Field
                                  TextFormField(
                                    controller: supervisorIDController,
                                    enabled: false,
                                    decoration: InputDecoration(
                                      labelText: "Supervisor ID",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      prefixIcon: const Icon(Icons.group),
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  // Full Name Field
                                  TextFormField(
                                    controller: supervisorNameController,
                                    decoration: InputDecoration(
                                      labelText: "Full Name",
                                      hintText: "Enter the full name",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      prefixIcon: const Icon(Icons.people),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return "Please enter the full name.";
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  // Email Field
                                  TextFormField(
                                    controller: supervisorEmailController,
                                    decoration: InputDecoration(
                                      labelText: "Email",
                                      hintText: "Enter the email address",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      prefixIcon: const Icon(Icons.email),
                                    ),
                                    validator: (value) {
                                      if (value == null || !emailRegExp.hasMatch(value)) {
                                        return "Please enter a valid email address.";
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  // Contact Number Field
                                  TextFormField(
                                    controller: supervisorContactNoController,
                                    decoration: InputDecoration(
                                      labelText: "Contact Number",
                                      hintText: "Enter the contact number",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      prefixIcon: const Icon(Icons.call),
                                    ),
                                    validator: (value) {
                                      if (value != null && value.isNotEmpty && !phoneRegExp.hasMatch(value)) {
                                        return "Please enter a valid contact number.";
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  // Password Field
                                  TextFormField(
                                    controller: supervisorPasswordController,
                                    obscureText: !_isPasswordVisible,
                                    decoration: InputDecoration(
                                      labelText: "Password",
                                      hintText: "Enter the new password",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    prefixIcon: const Icon(Icons.lock),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _isPasswordVisible
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _isPasswordVisible = !_isPasswordVisible;
                                          });
                                        },
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || !passwordRegExp.hasMatch(value)) {
                                        return "Password must be at least 8 characters long with at least one capital letter and contain both letters and numbers.";
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  // Dept Field
                                  DropdownButtonFormField<String>(
                                    value: supervisorDeptController.text.isEmpty ? null : supervisorDeptController.text, 
                                    decoration: InputDecoration(
                                      labelText: "Department",
                                      hintText: "Select your department",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      prefixIcon: const Icon(Icons.apartment),
                                    ),
                                    items: <String>['Engineering', 'IT', 'Business', 'Marketing'] 
                                        .map<DropdownMenuItem<String>>((String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value),
                                      );
                                    }).toList(),
                                    onChanged: null,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return "Please select a valid department.";
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
                                              // Get values from form fields
                                              String updatedName = supervisorNameController.text;
                                              String updatedEmail = supervisorEmailController.text;
                                              String? updatedPhone = supervisorContactNoController.text.isEmpty ? null : supervisorContactNoController.text;
                                              String updatedPassword = supervisorPasswordController.text;

                                              // Update Firestore data
                                              try {
                                                var updatedUserData = {
                                                  'name': updatedName,
                                                  'email': updatedEmail,
                                                  'contactNo': updatedPhone,
                                                  'password': updatedPassword,
                                                };

                                                var updatedSupervisorData = {
                                                  'dept': supervisorDept,
                                                  'supervisorID': supervisorID,
                                                };

                                                await FirebaseFirestore.instance
                                                    .collection('Users')
                                                    .doc(widget.userId)
                                                    .update(updatedUserData);
                                                
                                                QuerySnapshot supervisorSnapshot = await FirebaseFirestore.instance
                                                    .collection('Supervisor')
                                                    .where('userID', isEqualTo: widget.userId)
                                                    .get();

                                                for (QueryDocumentSnapshot doc in supervisorSnapshot.docs) {
                                                  await doc.reference.update(updatedSupervisorData);
                                                }

                                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully')));
                                                Navigator.of(context).pop();
                                              } catch (e) {
                                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update profile')));
                                                debugPrint("Error updating profile: $e");
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