import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CompanyDetailPage extends StatefulWidget {
  final String companyId;

  const CompanyDetailPage({super.key, required this.companyId});

  @override
  CompanyDetailPageState createState() => CompanyDetailPageState();
}

class CompanyDetailPageState extends State<CompanyDetailPage> {
  late Future<Map<String, dynamic>> _companyData;

  @override
  void initState() {
    super.initState();
    _companyData = _getCompanyData(widget.companyId);
  }

  Future<Map<String, dynamic>> _getCompanyData(String companyId) async {
    try {
      DocumentSnapshot companySnapshot = await FirebaseFirestore.instance
          .collection('Company')
          .doc(companyId)
          .get();

      if (!companySnapshot.exists) throw 'Company not found';

      Map<String, dynamic> company = companySnapshot.data() as Map<String, dynamic>;

      return {
        'companyName': company['companyName'] ?? 'No Company Name',
        'companyDesc': company['companyDesc'] ?? 'No Description',
        'companyEmail': company['companyEmail'] ?? 'No Email',
        'companyEmpNo': company['companyEmpNo'] ?? 0,  // Default to 0 if null
        'companyIndustry': company['companyIndustry'] ?? 'No Industry',
        'companyRegNo': company['companyRegNo'] ?? 'No Registration Number',
        'companyYear': company['companyYear'] ?? 0,  // Default to 0 if null
        'companyAddress': company['companyAddress'] ?? 'No Address',
        'logoURL': company['logoURL'] ?? '',
      };
    } catch (e) {
      print('Error retrieving company data: $e');
      rethrow;
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Company Detail')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _companyData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('No data available.'));
          }

          var company = snapshot.data!;
          String logoURL = company['logoURL'];
          int companyEmpNo = company['companyEmpNo'];
          int companyYear = company['companyYear'];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Logo',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                    const Divider(),
                    if (logoURL.isNotEmpty)
                      Image.network(logoURL)
                    else
                      const Text('No logo available.'),
                    
                    const SizedBox(height: 20),

                    const Text(
                      'Company Info',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                    const Divider(),
                    _buildDetailRow('Company Name', company['companyName']),
                    _buildDetailRow('Description', company['companyDesc']),
                    _buildDetailRow('Email', company['companyEmail']),
                    _buildDetailRow('Employee Number', companyEmpNo.toString()),  // Display integer as string
                    _buildDetailRow('Industry', company['companyIndustry']),
                    _buildDetailRow('Registration Number', company['companyRegNo']),
                    _buildDetailRow('Year Established', companyYear.toString()),  // Display integer as string
                    _buildDetailRow('Address', company['companyAddress']),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
