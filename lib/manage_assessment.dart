// ignore_for_file: use_build_context_synchronously

import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class ManageAssessment extends StatefulWidget {
  final String userId;
  const ManageAssessment({super.key, required this.userId});

  @override
  ManageAssessmentTab createState() => ManageAssessmentTab();
}

class ManageAssessmentTab extends State<ManageAssessment> {
  @override
  Widget build(BuildContext context) {
    throw UnimplementedError();
  }

}