// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddAdminPage extends StatefulWidget {
  final String userType;
  final VoidCallback refreshCallback;
  const AddAdminPage({super.key, required this.userType, required this.refreshCallback});

  @override
  State<AddAdminPage> createState() => _AddAdminPageState();
}

class _AddAdminPageState extends State<AddAdminPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController adminNameController = TextEditingController();
  final TextEditingController adminEmailController = TextEditingController();
  final TextEditingController adminContactNoController = TextEditingController();

  RegExp emailRegExp = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  RegExp phoneRegExp = RegExp(r'^[0-9\s\-]+$');

  Future<void> saveUser() async {
    if (_formKey.currentState!.validate()) {
      Map<String, dynamic> userData = {
        'name': adminNameController.text.trim(),
        'email': adminEmailController.text.trim(),
        'contactNo': adminContactNoController.text.trim().isEmpty ? null : adminContactNoController.text.trim(),
        'password': 'Password456',
        'userType': widget.userType,
      };

      try {
        await FirebaseFirestore.instance.collection('Users').add(userData);

        adminNameController.clear();
        adminEmailController.clear();
        adminContactNoController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User added successfully!')),
        );
        widget.refreshCallback();
        Navigator.of(context).pop(true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding admin: $e')),
        );
      }
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
                padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
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
                                  "Add New Admin",
                                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  "Insert the user information below",
                                  style: TextStyle(fontSize: 16, color: Colors.black),
                                ),
                                const SizedBox(height: 20),
                                // Full Name Field
                                TextFormField(
                                  controller: adminNameController,
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
                                  controller: adminEmailController,
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
                                  controller: adminContactNoController,
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
                                const SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    _buildButton("Add User", Colors.black, saveUser),
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
