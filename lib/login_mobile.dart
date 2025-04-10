// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'student_dashboard.dart';
import 'color.dart';

class LoginTab extends StatefulWidget {
  final int? userId;
  const LoginTab({super.key, this.userId});

  @override
  _LoginTabState createState() => _LoginTabState();
}

class _LoginTabState extends State<LoginTab> {
  final formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false; // Track password visibility

  // Declare the TextEditingController outside of build method
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    // Dispose of the controllers when the widget is disposed
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Regular expression for username and password
    RegExp userEmailRegExp = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    RegExp passwordRegExp = RegExp(r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9]).{8,}$');

    // Function to show error message
    void showErrorMessage(String message) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }

    Future<void> loginWithFirestore(String email, String password) async {
      try {
        // Query the 'Users' collection to find a matching email
        QuerySnapshot userQuerySnapshot = await FirebaseFirestore.instance
            .collection('Users')
            .where('email', isEqualTo: email)
            .where('password', isEqualTo: password)
            .get();

        // Check if a user was found
        if (userQuerySnapshot.docs.isNotEmpty) {
          var userDoc = userQuerySnapshot.docs.first;

          // Check if the widget is still mounted before navigating
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => StudentDashboard(userId: userDoc.id), // Replace with your next screen
              ),
            );
          }
        } else {
          showErrorMessage('Invalid email or password.');
        }
      } catch (e) {
        showErrorMessage('An error occurred: $e');
      }
    }

    return Scaffold(
      body: Container(
        color: AppColors.backgroundCream,
        child: Center(
          child: SingleChildScrollView( // <-- Wrap in scroll view
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Form(
                key: formKey,
                child: SizedBox(
                  width: 500,
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 10,
                    child: Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Icon(
                            Icons.account_circle,
                            size: 100.0,
                          ),
                          const SizedBox(height: 20.0),
                          TextFormField(
                            controller: usernameController,
                            decoration: InputDecoration(
                              labelText: 'Student Email',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.email),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your student email';
                              }
                              if (!userEmailRegExp.hasMatch(value)) {
                                return 'Please enter a valid student email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10.0),
                          TextFormField(
                            controller: passwordController,
                            obscureText: !_isPasswordVisible,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
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
                              if (value == null || value.isEmpty) {
                                return 'Please enter a password';
                              }
                              if (!passwordRegExp.hasMatch(value)) {
                                return 'Password must contain at least 8 characters including uppercase, lowercase, and numbers';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20.0),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: Colors.black,
                            ),
                            onPressed: () async {
                              if (formKey.currentState!.validate()) {
                                String email = usernameController.text;
                                String password = passwordController.text;
                                await loginWithFirestore(email, password);
                              }
                            },
                            child: const Text(
                              'Login',
                              style: TextStyle(fontSize: 18, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

