// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import 'color.dart';

class EditCompany extends StatefulWidget {
  final String userId;
  final VoidCallback refreshCallback;
  const EditCompany({super.key, required this.userId, required this.refreshCallback});

  @override
  EditCompanyTab createState() => EditCompanyTab();
}

class EditCompanyTab extends State<EditCompany> {
  final formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;

  String pContactEmail = "Loading...";
  String pContactName = "Loading...";
  String? companyContactNo;
  String companyPassword = "Loading...";

  String pContactJobTitle = "Loading...";

  String companyEmail = "Loading...";
  String companyName = "Loading...";
  String companyAddress = "Loading...";
  String companyRegNo = "Loading...";
  int companyYear = 0;
  String companyDesc = "Loading...";
  String companyIndustry = '';
  String approvalStatus = '';
  int companyEmpNo = 0;
  String? logoURL;
  String companyID = "Loading...";

  List<String> companyIndustries = [
    'Information Technology',
    'Software Development',
    'Healthcare',
    'Finance',
    'Education',
    'Manufacturing',
    'Construction',
    'Real Estate',
    'Telecommunications',
    'Marketing & Advertising',
    'Automotive',
    'E-commerce',
    'Energy & Utilities',
    'Hospitality',
    'Transportation & Logistics',
    'Media & Entertainment',
    'Insurance',
    'Pharmaceuticals',
    'Food & Beverage',
    'Retail Store',
    'Tourism',
    'Non-Profit',
    'Government & Public Sector',
    'Legal Services',
    'Consulting',
    'Research & Development',
    'Architecture',
    'Agriculture',
    'Electronics',
    'Fashion & Apparel',
    'Sports & Recreation',
    'Financial Services',
    'Aerospace & Defense',
    'Biotechnology',
    'Chemicals',
    'Marine & Shipping',
    'Wholesale & Distribution',
    'Human Resources',
    'Security Services',
    'Art & Design',
    'Environmental Services',
    'Healthcare Services',
    'IT Services',
    'Logistics & Supply Chain',
    'Media Production',
    'Event Management',
  ];

  // Text editing controllers
  final TextEditingController companyNameController = TextEditingController();
  final TextEditingController companyAddressController = TextEditingController();
  final TextEditingController companyRegNoController = TextEditingController();
  final TextEditingController companyYearController = TextEditingController();
  final TextEditingController companyDescController = TextEditingController();
  final TextEditingController companyIndustryController = TextEditingController();
  final TextEditingController approvalStatusController = TextEditingController();
  final TextEditingController companyEmpNoController = TextEditingController();
  final TextEditingController companyEmailController = TextEditingController();
  final TextEditingController companyIDController = TextEditingController();
  //final TextEditingController logoURLController = TextEditingController();
  
  final TextEditingController placementContactNameController = TextEditingController();
  final TextEditingController companyContactNoController = TextEditingController();
  final TextEditingController placementContactEmailController = TextEditingController();
  final TextEditingController companyPasswordController = TextEditingController();
  final TextEditingController placementContactJobTitleController = TextEditingController();

  RegExp yearRegExp = RegExp(r'^(1|2)\d{3}$');
  RegExp empNoRegExp = RegExp(r'^[0-9]+$');
  RegExp emailRegExp = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  RegExp phoneRegExp = RegExp(r'^[0-9\s\-]+$');
  RegExp passwordRegExp = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$');

  @override
  void initState() {
    super.initState();
    fetchCompanyDetails();
  }

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
      var companySnapshot = await FirebaseFirestore.instance
          .collection('Company')
          .where('userID', isEqualTo: widget.userId)
          .get();

      if (companySnapshot.docs.isNotEmpty) {
        String? oldLogoUrl = companySnapshot.docs.first.data()['logoURL'];

        if (oldLogoUrl != null && oldLogoUrl.isNotEmpty) {
          try {
            await FirebaseStorage.instance.refFromURL(oldLogoUrl).delete();
          } catch (e) {
            debugPrint("Failed to delete old logo: $e");
          }
        }
      }

      // Upload new logo
      final fileName = 'logos/${DateTime.now().millisecondsSinceEpoch}.png';
      final storageRef = FirebaseStorage.instance.ref().child(fileName);
      
      final uploadTask = storageRef.putData(_selectedLogoBytes!);
      final snapshot = await uploadTask;
      final newLogoUrl = await snapshot.ref.getDownloadURL();

      return newLogoUrl;
    } catch (e) {
      debugPrint("Failed to upload logo: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload logo: $e')),
      );
      return null;
    }
  }

  Future<void> fetchCompanyDetails() async {
    try {
      var userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.userId)
          .get();
      var companySnapshot = await FirebaseFirestore.instance
          .collection('Company')
          .where('userID', isEqualTo: widget.userId)
          .get();

      if (userDoc.exists) {
        setState(() {
          pContactEmail = userDoc.data()?['email'] ?? 'No Email';
          pContactName = userDoc.data()?['name'] ?? 'No Name';
          companyContactNo = userDoc.data()?['contactNo'];
          companyPassword = userDoc.data()?['password']  ?? 'No Password';

          if (companySnapshot.docs.isNotEmpty) {
          var companyDoc = companySnapshot.docs.first.data();

          companyID =  companySnapshot.docs.first.id;
          companyEmail = companyDoc['companyEmail'] ?? 'No Company Email';
          companyName = companyDoc['companyName'] ?? 'No Company Name';
          companyAddress = companyDoc['companyAddress'] ?? 'No Company Address';
          companyRegNo = companyDoc['companyRegNo'] ?? 'No Company RegNo';
          companyYear = int.tryParse(companyDoc['companyYear'].toString()) ?? 0;
          companyDesc = companyDoc['companyDesc'] ?? 'No Company Desc';
          companyIndustry = companyDoc['companyIndustry'] ?? 'No Company Industry';
          approvalStatus = companyDoc['approvalStatus'] ?? 'No Approval Status';
          companyEmpNo = int.tryParse(companyDoc['companyEmpNo'].toString()) ?? 0;
          logoURL = companyDoc['logoURL'] ?? '';
          pContactJobTitle = companyDoc['pContactJobTitle'] ?? 'No Placement contact job title';

        } else {
          companyID = 'No working company';
          companyEmail = 'No company email';
          companyName = 'No company name';
          companyAddress = 'No company address';
          companyRegNo = 'No company registration no';
          companyYear = 0;
          companyDesc = 'No company description';
          companyIndustry = 'No company industry';
          approvalStatus = 'No Approval Status';
          companyEmpNo = 0;
          logoURL = 'No company logo';
          pContactJobTitle = 'No placement contact job title';
        }

          // Set the values to the controllers
          companyNameController.text = companyName;
          companyAddressController.text = companyAddress;
          companyRegNoController.text = companyRegNo ;
          companyYearController.text = companyYear.toString();
          companyDescController.text = companyDesc;
          companyIndustryController.text = companyIndustry;
          approvalStatusController.text = approvalStatus;
          companyEmpNoController.text = companyEmpNo.toString();
          companyEmailController.text = companyEmail;
          //logoURLController.text = logoURL ?? '';
          companyIDController.text = companyID;

          placementContactNameController.text = pContactName;
          companyContactNoController.text = companyContactNo ?? '';
          placementContactEmailController.text = pContactEmail;
          companyPasswordController.text = companyPassword;
          placementContactJobTitleController.text = pContactJobTitle;
        });
      }
    } catch (e) {
      debugPrint("Error fetching company details: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Company Profile Page"),
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
                                "Edit Company",
                                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "Enter the company information below",
                                style: TextStyle(fontSize: 16, color: Colors.black),
                              ),
                              const SizedBox(height: 32),
                              // Company ID Field
                              TextFormField(
                                controller: companyIDController,
                                enabled: false,
                                decoration: InputDecoration(
                                  labelText: "Company ID",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  prefixIcon: const Icon(Icons.group),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Company Name Field
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
                              const SizedBox(height: 16),
                              // Placement Contact Full Name Field
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
                              const SizedBox(height: 16),
                              // Placement Contact Email Field
                              TextFormField(
                                controller: placementContactEmailController,
                                decoration: InputDecoration(
                                  labelText: "Email",
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
                              const SizedBox(height: 16),
                              // Placement Contact Job Title Field
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
                              const SizedBox(height: 16),
                              // Password Field
                              TextFormField(
                                controller: companyPasswordController,
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
                              // Company Email Field
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
                              const SizedBox(height: 16),
                              // Contact Number Field
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
                              const SizedBox(height: 16),
                              // Company Address Field
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
                              const SizedBox(height: 16),
                              // Company Description Field
                              TextFormField(
                                controller: companyDescController,
                                decoration: InputDecoration(
                                  labelText: "Company Description",
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
                              // Company Registration No Field
                              TextFormField(
                                controller: companyRegNoController,
                                decoration: InputDecoration(
                                  labelText: "Company Registration No",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  prefixIcon: const Icon(Icons.pin),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "Company registration number cannot be empty.";
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              // Company Year Field
                              TextFormField(
                                controller: companyYearController,
                                decoration: InputDecoration(
                                  labelText: "Company Establish Year",
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
                              const SizedBox(height: 16),
                              // Company Emp No Field
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
                              const SizedBox(height: 16),
                              // Company Industry Field
                              DropdownButtonFormField<String>(
                                value: companyIndustry.isEmpty ? null : companyIndustry,
                                decoration: InputDecoration(
                                  labelText: "Company Industry",
                                  hintText: "Select the main company industry",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  prefixIcon: const Icon(Icons.villa),
                                ),
                                items: companyIndustries
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
                              const Text("Company Logo:"),
                              const SizedBox(height: 5.0),
                              ElevatedButton.icon(
                                onPressed: pickLogo,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                                  backgroundColor: AppColors.backgroundCream,
                                  foregroundColor: Colors.white,
                                  elevation: 2,
                                ),
                                icon: const Icon(Icons.upload_file, color: Colors.black),
                                label: Text(_selectedLogoBytes == null ? 'Upload Logo' : 'Change Logo', style: const TextStyle(color: Colors.black)),
                              ), 
                              const SizedBox(height: 10.0),
                              if (_selectedLogoBytes != null) 
                              Image.memory(_selectedLogoBytes!, height: 100),
                              const SizedBox(height: 16),
                              // Company Industry Field
                              DropdownButtonFormField<String>(
                                value: approvalStatus.isEmpty ? null : approvalStatus,
                                decoration: InputDecoration(
                                  labelText: "Approval Status",
                                  hintText: "Select the approval status of company",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  prefixIcon: const Icon(Icons.date_range),
                                ),
                                items: <String>['Approve', 'Pending'] 
                                    .map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    approvalStatus = newValue ?? '';
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "Please select a status.";
                                  }
                                  return null;
                                },
                              ),                 
                              const SizedBox(height: 32),
                              // Save Button
                              Center(
                                child: Row (
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () async {
                                        if (formKey.currentState?.validate() ?? false) {
                                          final logoUrl = await _uploadLogo();
                                          // Get values from form fields
                                          String updatedName = placementContactNameController.text;
                                          String updatedEmail = placementContactEmailController.text;
                                          String? updatedPhone = companyContactNoController.text.isEmpty ? null : companyContactNoController.text;
                                          String updatedPassword = companyPasswordController.text;

                                          String updatedCompanyName = companyNameController.text;
                                          String updatedCompanyAddress = companyAddressController.text;
                                          String updatedCompanyEmail = companyEmailController.text;
                                          String updatedRegNo = companyRegNoController.text;
                                          String updatedCompanyDesc = companyDescController.text;
                                          int updatedCompanyYear = int.tryParse(companyYearController.text.trim()) ?? 0;
                                          int updatedCompanyEmpNo = int.tryParse(companyEmpNoController.text.trim()) ?? 0;
                                          //String? updatedLogoURL =  logoURLController.text.isEmpty ? null : logoURLController.text;

                                          String updatedPlacementJobTitle = placementContactJobTitleController.text;


                                          // Update Firestore data
                                          try {
                                            var updatedUserData = {
                                              'name': updatedName,
                                              'email': updatedEmail,
                                              'contactNo': updatedPhone,
                                              'password': updatedPassword,
                                            };

                                            var updatedCompanyData = {
                                              'companyID': companyID,
                                              'companyName': updatedCompanyName,
                                              'companyIndustry': companyIndustry,
                                              'approvalStatus': approvalStatus,
                                              'companyAddress': updatedCompanyAddress,
                                              'companyEmail': updatedCompanyEmail,
                                              'companyRegNo': updatedRegNo,
                                              'companyDesc': updatedCompanyDesc,
                                              'companyYear': updatedCompanyYear,
                                              'companyEmpNo': updatedCompanyEmpNo,
                                              'pContactJobTitle': updatedPlacementJobTitle,
                                              'logoURL': logoUrl ?? logoURL,
                                            };

                                            await FirebaseFirestore.instance
                                                .collection('Users')
                                                .doc(widget.userId)
                                                .update(updatedUserData);
                                            
                                            QuerySnapshot companySnapshot = await FirebaseFirestore.instance
                                                .collection('Company')
                                                .where('userID', isEqualTo: widget.userId)
                                                .get();

                                            for (QueryDocumentSnapshot doc in companySnapshot.docs) {
                                              await doc.reference.update(updatedCompanyData);
                                            }

                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully')));
                                            widget.refreshCallback();
                                            Navigator.of(context).pop(true);
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