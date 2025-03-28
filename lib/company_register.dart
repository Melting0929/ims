import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'register_success.dart';
import 'color.dart';

class CompanySignUpPage extends StatefulWidget {
  const CompanySignUpPage({super.key});

  @override
  State<CompanySignUpPage> createState() => _CompanySignUpPageState();
}

class _CompanySignUpPageState extends State<CompanySignUpPage> {
  final formKey = GlobalKey<FormState>();
  final TextEditingController companyNameController = TextEditingController();
  final TextEditingController companyAddressController = TextEditingController();
  final TextEditingController companyRegNoController = TextEditingController();
  final TextEditingController companyYearController = TextEditingController();
  final TextEditingController companyDescController = TextEditingController();
  final TextEditingController companyIndustryController = TextEditingController();
  final TextEditingController companyEmpNoController = TextEditingController();
  final TextEditingController companyEmailController = TextEditingController();
  final TextEditingController companyContactNoController = TextEditingController();
  final TextEditingController placementContactNameController = TextEditingController();
  final TextEditingController placementContactJobTitleController = TextEditingController();
  final TextEditingController placementContactEmailController = TextEditingController();

  RegExp companyRegNoRegExp = RegExp(r'^[a-zA-Z0-9]+$');
  RegExp yearRegExp = RegExp(r'^(19|20)\d{2}$');
  RegExp empNoRegExp = RegExp(r'^[0-9]+$');
  RegExp emailRegExp = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  RegExp phoneRegExp = RegExp(r'^[0-9\s\-]+$');

  String companyIndustry = '';

  Uint8List? _selectedLogoBytes;

  // Pick Logo Function (Image)
  Future<void> pickLogo() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _selectedLogoBytes = bytes;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No logo selected.')),
      );
    }
  }

  // Upload Logo Function
  Future<String?> _uploadLogo() async {
    if (_selectedLogoBytes == null) return null;

    try {
      final fileName = 'logos/${DateTime.now().millisecondsSinceEpoch}.png';
      final storageRef = FirebaseStorage.instance.ref().child(fileName);

      final uploadTask = storageRef.putData(_selectedLogoBytes!);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload logo: $e')),
      );
      return null;
    }
  }

  Future<bool> isCompanyRegistered(String regNo, String email) async {
    try {
      // Check if a company with the same registration number exists
      final regNoSnapshot = await FirebaseFirestore.instance.collection('Company')
          .where('companyRegNo', isEqualTo: regNo)
          .get();

      if (regNoSnapshot.docs.isNotEmpty) {
        return true; // Company with the same registration number exists
      }

      // Check if a company with the same email exists
      final emailSnapshot = await FirebaseFirestore.instance.collection('Company')
          .where('companyEmail', isEqualTo: email)
          .get();

      if (emailSnapshot.docs.isNotEmpty) {
        return true; // Company with the same email exists
      }
    } catch (e) {
      debugPrint('Error checking company registration: $e');
    }
    return false;
  }

  Future<void> addCompany() async {
    try {
      final regNo = companyRegNoController.text.trim();
      final email = companyEmailController.text.trim();
      final logoUrl = await _uploadLogo();

      // Check if the company is already registered
      bool isRegistered = await isCompanyRegistered(regNo, email);
      if (isRegistered) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This company is already registered!')));
        return; // Do not proceed with registration if company already exists
      }

      final userData = {
        'name': placementContactNameController.text.trim(),
        'email': placementContactEmailController.text.trim(),
        'contactNo': companyContactNoController.text.trim(),
        'password': 'Password123',
        'userType': 'Company',
      };

      final userRef = FirebaseFirestore.instance.collection('Users').doc();
      await userRef.set(userData);

      final companyRef = FirebaseFirestore.instance.collection('Company').doc();

      final companyData = {
        'companyName': companyNameController.text.trim(),
        'companyAddress': companyAddressController.text.trim(),
        'companyRegNo': regNo,
        'companyYear': int.tryParse(companyYearController.text.trim()) ?? 0,
        'companyDesc': companyDescController.text.trim(),
        'companyIndustry': companyIndustry,
        'companyEmpNo': int.tryParse(companyEmpNoController.text.trim()) ?? 0,
        'companyEmail': email,
        'pContactJobTitle': placementContactJobTitleController.text.trim(),
        'companyID': companyRef.id,
        'logoURL': logoUrl ?? '',
        'approvalStatus': 'Pending',
        'companyType': 'Registered',
        'userID': userRef.id,
      };

      
      await companyRef.set(companyData);

      // Show success message and navigate to the success page
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Company registered successfully!')));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const RegistrationSuccessPage()),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  InputDecoration customInputDecoration(String labelText, String hintText) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("New Company Registration"),
        centerTitle: true,
        backgroundColor: AppColors.backgroundGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.home, color: Colors.black),
          onPressed: () {
            Navigator.pop(context); 
          },
        ),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          color: AppColors.backgroundGreen,
          child: Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.4,
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text(
                          "Sign Up as Our Industry Partner",
                          style: TextStyle(
                            fontSize: 34.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Center(
                        child: Text(
                          "Enter details to apply",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 20.0),
                      TextFormField(
                        controller: companyNameController,
                        decoration: InputDecoration(
                          labelText: "Company Name",
                          hintText: "Enter the company name",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.apartment_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter the company name.";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10.0),
                      TextFormField(
                        controller: companyAddressController,
                        decoration: InputDecoration(
                          labelText: "Company Address",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.home),
                        ),
                        maxLines: 5, // Allows up to 5 lines for longer text input
                        keyboardType: TextInputType.multiline, // Enables multiline input
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter a valid company address.";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10.0),
                      TextFormField(
                        controller: companyRegNoController,
                        decoration: InputDecoration(
                          labelText: "Company Registration No",
                          hintText: "Enter the registration number",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.pin),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Company registration number cannot be empty.";
                          }
                          if (!companyRegNoRegExp.hasMatch(value)) {
                            return "Please enter a valid company registration number.";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10.0),
                      TextFormField(
                        controller: companyYearController,
                        decoration: InputDecoration(
                          labelText: "Company Establish Year",
                          hintText: "Enter the year the company was established",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.calendar_month),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Company established year cannot be empty.";
                          }
                          if (!yearRegExp.hasMatch(value)) {
                            return "Please enter a valid company established year (e.g. 2025).";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10.0),
                      TextFormField(
                        controller: companyDescController,
                        decoration: InputDecoration(
                          labelText: "Company Description",
                          hintText: "Provide a brief description of the company",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.description),
                        ),
                        maxLines: 5, // Allows up to 5 lines for longer text input
                        keyboardType: TextInputType.multiline, // Enables multiline input
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter a valid company description.";
                          } else if (value.length < 20) {
                            return "The description should be at least 20 characters long.";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Company Industry Field
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: "Company Industry",
                          hintText: "Select the main company industry",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.villa),
                        ),
                        items: <String>['Software Technology', 'Manufacturing', 'Retail Store', 'E-Commerce'] 
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            companyIndustry = newValue ?? '';
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please select a industry.";
                          }
                          return null;
                        },
                      ),  
                      const SizedBox(height: 10.0),
                      TextFormField(
                        controller: companyEmpNoController,
                        decoration: InputDecoration(
                          labelText: "Number of Employee of the Company",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.badge),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter a valid employee numbers (e.g. 130).";
                          }
                          if (!empNoRegExp.hasMatch(value)) {
                            return "Please enter a valid employee numbers (e.g. 130).";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10.0),
                      TextFormField(
                        controller: companyEmailController,
                        decoration: InputDecoration(
                          labelText: "Company Email",
                          hintText: "Enter the company email address",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.email),
                        ),
                        validator: (value) {
                          if (value == null || !emailRegExp.hasMatch(value)) {
                            return "Please enter a valid company email address.";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10.0),
                      TextFormField(
                        controller: companyContactNoController,
                        decoration: InputDecoration(
                          labelText: "Contact Number",
                          hintText: "Enter the company contact number",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.call),
                        ),
                        validator: (value) {
                          if (value != null && value.isNotEmpty && !phoneRegExp.hasMatch(value)) {
                            return "Please enter a valid company contact number.";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10.0),
                      TextFormField(
                        controller: placementContactNameController,
                        decoration: InputDecoration(
                          labelText: "Placement Contact Full Name",
                          hintText: "Enter the placement contact full name",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.people),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter the placement contact full name.";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10.0),
                      TextFormField(
                        controller: placementContactJobTitleController,
                        decoration: InputDecoration(
                          labelText: "Placement Contact Job Title",
                          hintText: "Enter the placement contact job title",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.work),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter a valid placement contact job title.";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10.0),
                      TextFormField(
                        controller: placementContactEmailController,
                        decoration: InputDecoration(
                          labelText: "Placement Contact Email",
                          hintText: "Enter the placement contact email address",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.email),
                        ),
                        validator: (value) {
                          if (value == null || !emailRegExp.hasMatch(value)) {
                            return "Please enter a valid placement contact email address.";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10.0),
                      const Text("Company Logo:"),
                      const SizedBox(height: 5.0),
                      ElevatedButton.icon(
                        onPressed: pickLogo,
                        icon: const Icon(Icons.upload_file),
                        label: Text(_selectedLogoBytes == null ? 'Upload Logo' : 'Change Logo'),
                      ),
                      const SizedBox(height: 10.0),
                      if (_selectedLogoBytes != null) 
                      Image.memory(_selectedLogoBytes!, height: 100),
                      const SizedBox(height: 20.0),
                      Center(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE9C46A),
                            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              addCompany();
                            }
                          },
                          child: const Text(
                            "Sign Up",
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
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
    );
  }
}
