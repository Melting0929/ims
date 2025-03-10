// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EprofileAdmin extends StatefulWidget {
  final String userId;
  const EprofileAdmin({super.key, required this.userId});

  @override
  EprofileAdminTab createState() => EprofileAdminTab();
}

class EprofileAdminTab extends State<EprofileAdmin> {
  final formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;

  // Declare variables for user data
  String adminEmail = "Loading...";
  String adminName = "Loading...";
  String? adminContactNo;
  String adminPassword = "Loading...";

  // Text editing controllers
  final TextEditingController adminNameController = TextEditingController();
  final TextEditingController adminEmailController = TextEditingController();
  final TextEditingController adminContactNoController = TextEditingController();
  final TextEditingController adminPasswordController = TextEditingController();

  RegExp emailRegExp = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  RegExp phoneRegExp = RegExp(r'^[0-9\s\-]+$');
  RegExp passwordRegExp = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$');

  @override
  void initState() {
    super.initState();
    fetchAdminDetails();
  }

  Future<void> fetchAdminDetails() async {
    try {
      var adminDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.userId)
          .get();

      if (adminDoc.exists) {
        setState(() {
          adminEmail = adminDoc.data()?['email'] ?? 'No Email';
          adminName = adminDoc.data()?['name'] ?? 'No Name';
          adminContactNo = adminDoc.data()?['contactNo'];
          adminPassword = adminDoc.data()?['password'] ?? 'No Password';

          // Set the values to the controllers
          adminNameController.text = adminName;
          adminEmailController.text = adminEmail;
          adminContactNoController.text = adminContactNo ?? '';
          adminPasswordController.text = adminPassword;
        });
      }
    } catch (e) {
      debugPrint("Error fetching admin details: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile Page"),
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
                                  "Edit Profile",
                                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  "Enter the your information below",
                                  style: TextStyle(fontSize: 16, color: Colors.black),
                                ),
                                const SizedBox(height: 32),
                                // Full Name Field
                                TextFormField(
                                  controller: adminNameController,
                                  decoration: InputDecoration(
                                    labelText: "Full Name",
                                    hintText: "Enter your full name",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: const Icon(Icons.people),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Please enter your full name.";
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                // Email Field
                                TextFormField(
                                  controller: adminEmailController,
                                  decoration: InputDecoration(
                                    labelText: "Email",
                                    hintText: "Enter your email address",
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
                                  controller: adminContactNoController,
                                  decoration: InputDecoration(
                                    labelText: "Contact Number",
                                    hintText: "Enter your contact number",
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
                                  controller: adminPasswordController,
                                  obscureText: !_isPasswordVisible,
                                  decoration: InputDecoration(
                                    labelText: "Password",
                                    hintText: "Enter your new password",
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
                                            String updatedName = adminNameController.text;
                                            String updatedEmail = adminEmailController.text;
                                            String? updatedPhone = adminContactNoController.text.isEmpty ? null : adminContactNoController.text;
                                            String updatedPassword = adminPasswordController.text;

                                            // Update Firestore data
                                            try {
                                              var updatedData = {
                                                'name': updatedName,
                                                'email': updatedEmail,
                                                'contactNo': updatedPhone,
                                                'password': updatedPassword,
                                              };

                                              await FirebaseFirestore.instance
                                                  .collection('Users')
                                                  .doc(widget.userId)
                                                  .update(updatedData);
                                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully')));
                                              Navigator.pop(context, true);
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