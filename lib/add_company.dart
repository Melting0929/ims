// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddCompanyPage extends StatefulWidget {
  final String userType;
  const AddCompanyPage({super.key, required this.userType});

  @override
  State<AddCompanyPage> createState() => _AddCompanyPageState();
} 

class _AddCompanyPageState extends State<AddCompanyPage> {
  final _formKey = GlobalKey<FormState>();
  String companyIndustry = '';

  // Text editing controllers
  final TextEditingController companyNameController = TextEditingController();
  final TextEditingController companyAddressController = TextEditingController();
  final TextEditingController companyRegNoController = TextEditingController();
  final TextEditingController companyYearController = TextEditingController();
  final TextEditingController companyDescController = TextEditingController();
  final TextEditingController companyIndustryController = TextEditingController();
  final TextEditingController companyEmpNoController = TextEditingController();
  final TextEditingController companyEmailController = TextEditingController();
  
  final TextEditingController placementContactNameController = TextEditingController();
  final TextEditingController companyContactNoController = TextEditingController();
  final TextEditingController placementContactEmailController = TextEditingController();
  final TextEditingController companyPasswordController = TextEditingController();
  final TextEditingController placementContactJobTitleController = TextEditingController();

  RegExp emailRegExp = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  RegExp phoneRegExp = RegExp(r'^[0-9\s\-]+$');
  RegExp companyRegNoRegExp = RegExp(r'^[a-zA-Z0-9]+$');
  RegExp yearRegExp = RegExp(r'^(19|20)\d{2}$');
  RegExp empNoRegExp = RegExp(r'^[0-9]+$');

  // Save user to Firestore
  Future<void> saveUser() async {
    if (_formKey.currentState!.validate()) {
      Map<String, dynamic> userData = {
        'name': placementContactNameController.text.trim(),
        'email': placementContactEmailController.text.trim(),
        'contactNo': companyContactNoController.text.trim(),
        'password': 'Password123',
        'userType': widget.userType,
      };

      try {
        var userRef =  await FirebaseFirestore.instance.collection('Users').add(userData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User added successfully!')),
        );

        String userID = userRef.id;

        // Generate a new document ID for the admin document
        await FirebaseFirestore.instance.collection('Company').add({
          'userID': userID,
          'companyName': companyNameController.text.trim(),
          'companyIndustry': companyIndustry,
          'companyAddress': companyAddressController.text.trim(),
          'companyEmail': companyEmailController.text.trim(),
          'companyRegNo': companyRegNoController.text.trim(),
          'companyDesc': companyDescController.text.trim(),
          'companyYear': int.tryParse(companyYearController.text.trim()) ?? 0,
          'companyEmpNo': int.tryParse(companyEmpNoController.text.trim()) ?? 0,
          'approvalStatus': 'Approve',
          'pContactJobTitle': placementContactJobTitleController.text.trim(),
          'companyType': 'External',
        });

        // Clear fields
        companyNameController.clear();
        companyAddressController.clear();
        companyRegNoController.clear();
        companyYearController.clear();
        companyDescController.clear();
        companyIndustryController.clear();
        companyEmpNoController.clear();
        companyEmailController.clear();
        
        placementContactNameController.clear();
        companyContactNoController.clear();
        placementContactEmailController.clear();
        placementContactJobTitleController.clear();

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding company: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add External Company Page"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      //extendBodyBehindAppBar: true,
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
                                  "Add New External Company",
                                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  "Enter the user information below",
                                  style: TextStyle(fontSize: 16, color: Colors.black),
                                ),
                                const SizedBox(height: 20),
                                _buildTextField(companyNameController, "Company Name", Icons.apartment_outlined),
                                const SizedBox(height: 16),
                                _buildTextField(placementContactNameController, "Placement Contact Full Name", Icons.people),
                                const SizedBox(height: 16),
                                _buildTextField(placementContactEmailController, "Placement Contact Email", Icons.email, isEmail: true),
                                const SizedBox(height: 16),
                                _buildTextField(placementContactJobTitleController, "Placement Contact Job Title", Icons.work),
                                const SizedBox(height: 16),
                                _buildTextField(companyEmailController, "Company Email", Icons.email, isEmail: true),
                                const SizedBox(height: 16),
                                _buildTextField(companyContactNoController, "Contact Number", Icons.call, isPhone: true),
                                const SizedBox(height: 16),
                                _buildTextField(companyAddressController, "Company Address", Icons.home, isMultiline: true),
                                const SizedBox(height: 16),
                                _buildTextField(companyDescController, "Company Description", Icons.description, isMultiline: true, minLength: 20),
                                const SizedBox(height: 16),
                                _buildTextField(companyRegNoController, "Company Registration No", Icons.pin),
                                const SizedBox(height: 16),
                                _buildTextField(companyYearController, "Company Establish Year", Icons.calendar_month, isNumeric: true),
                                const SizedBox(height: 16),
                                _buildTextField(companyEmpNoController, "Number of Employees", Icons.badge, isNumeric: true),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  decoration: InputDecoration(
                                    labelText: "Company Industry",
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    prefixIcon: const Icon(Icons.villa),
                                  ),
                                  items: <String>["Software Technology", "Manufacturing", "Retail Store", "E-Commerce"]
                                      .map((String value) => DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(value),
                                          ))
                                      .toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      companyIndustry = newValue ?? '';
                                    });
                                  },
                                  validator: (value) => value == null || value.isEmpty ? "Please select an industry." : null,
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

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {bool isMultiline = false, bool isEmail = false, bool isPhone = false, bool isNumeric = false, int minLength = 0, String? hintText}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        prefixIcon: Icon(icon, color: Colors.black),
        filled: true,
        fillColor: Colors.white.withOpacity(0.2),
      ),
      maxLines: isMultiline ? 5 : 1,
      keyboardType: isMultiline
          ? TextInputType.multiline
          : isNumeric
              ? TextInputType.number
              : TextInputType.text,
      style: const TextStyle(color: Colors.black),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Please enter $label.";
        }
        if (isEmail && !emailRegExp.hasMatch(value)) {
          return "Please enter a valid email.";
        }
        if (isPhone && !phoneRegExp.hasMatch(value)) {
          return "Please enter a valid contact number.";
        }
        if (isNumeric && !RegExp(r'^[0-9]+\$').hasMatch(value)) {
          return "Please enter a valid number.";
        }
        if (minLength > 0 && value.length < minLength) {
          return "$label should be at least $minLength characters long.";
        }
        return null;
      },
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

