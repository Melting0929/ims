import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_dashboard.dart';
import 'company_dashboard.dart';
import 'student_dashboard.dart';
import 'supervisor_dashboard.dart';
import 'company_register.dart';
import 'color.dart';

class LoginWeb extends StatefulWidget {
  const LoginWeb({super.key});

  @override
  LoginWebState createState() => LoginWebState();
}

class LoginWebState extends State<LoginWeb> {
  final formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  late TextEditingController usernameController;
  late TextEditingController passwordController;
  String selectedRole = "Student";

  @override
  void initState() {
    super.initState();
    usernameController = TextEditingController();
    passwordController = TextEditingController();
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // Regular expressions for validation
  RegExp userEmailRegExp = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  RegExp passwordRegExp = RegExp(r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9]).{8,}$');

  // Show error message
  void showErrorMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // Login and navigation logic
  Future<void> loginWithFirestore(String email, String password) async {
  try {
      QuerySnapshot userQuerySnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .where('email', isEqualTo: email)
          .where('password', isEqualTo: password)
          .get();

      if (userQuerySnapshot.docs.isNotEmpty) {
        var userDoc = userQuerySnapshot.docs.first;
        String userType = userDoc['userType'];

        if (userType == selectedRole) {
          // Check if the user is a company and if the approval status is "Approve"
          if (userType == 'Company') {
            // Fetch the company document using the userID stored in the user document
            var companyDoc = await FirebaseFirestore.instance
                .collection('Company')
                .where('userID', isEqualTo: userDoc.id)
                .get();

            if (companyDoc.docs.isNotEmpty) {
              var companyData = companyDoc.docs.first;
              String approvalStatus = companyData['approvalStatus'] ?? '';
              if (approvalStatus != 'Approve') {
                showErrorMessage(context, 'Your company is not approved yet.');
                return;
              }
            } else {
              showErrorMessage(context, 'Company document not found.');
              return;
            }
          }

          // Navigate to specific dashboard based on role
          switch (userType) {
            case 'Student':
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => StudentDashboard(userId: userDoc.id)),
              );
              break;
            case 'Company':
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => CompanyDashboard(userId: userDoc.id)),
              );
              break;
            case 'Supervisor':
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => SupervisorDashboard(userId: userDoc.id)),
              );
              break;
            case 'Admin':
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => AdminDashboard(userId: userDoc.id)),
              );
              break;
            default:
              showErrorMessage(context, 'Invalid user type.');
          }
        } else {
          showErrorMessage(context, 'User type does not match the selected role.');
        }
      } else {
        showErrorMessage(context, 'Invalid email or password.');
      }
    } catch (e) {
      showErrorMessage(context, 'An error occurred: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: AppColors.backgroundCream,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: formKey,
              child: SingleChildScrollView( // Makes the form scrollable
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.9,
                    maxWidth: MediaQuery.of(context).size.width * 0.5,
                  ),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 10,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Icon(Icons.account_circle, size: 150.0),
                          const SizedBox(height: 20.0),
                          DropdownButtonFormField<String>(
                            value: selectedRole,
                            items: ['Student', 'Company', 'Supervisor', 'Admin']
                                .map((role) => DropdownMenuItem(
                                      value: role,
                                      child: Text(role),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedRole = value!;
                              });
                            },
                            decoration: InputDecoration(
                              labelText: 'Select Role',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10.0),
                          TextFormField(
                            controller: usernameController,
                            decoration: InputDecoration(
                              labelText: '$selectedRole Email',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.email),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your $selectedRole email';
                              }
                              if (!userEmailRegExp.hasMatch(value)) {
                                return 'Please enter a valid email';
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
                            child: const Text('Login', style: TextStyle(fontSize: 18, color: Colors.white)),
                          ),
                          const SizedBox(height: 10.0),
                          if (selectedRole == 'Company')
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 50),
                                backgroundColor: Colors.teal,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => const CompanySignUpPage()),
                                );
                              },
                              child: const Text('Sign-Up as Our Industry Partner', style: TextStyle(fontSize: 16, color: Colors.white)),
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