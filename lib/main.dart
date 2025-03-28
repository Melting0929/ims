import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'mobile_start.dart';
import 'login_web.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if(kIsWeb){
    await Firebase.initializeApp(options: const FirebaseOptions(apiKey: "AIzaSyDeJUp3J8fo1PuPKOpWkLi3BcZstokF-sg",
      authDomain: "imsfyp2.firebaseapp.com",
      databaseURL: "https://imsfyp2-default-rtdb.asia-southeast1.firebasedatabase.app",
      projectId: "imsfyp2",
      storageBucket: "imsfyp2.firebasestorage.app",
      messagingSenderId: "618402886119",
      appId: "1:618402886119:web:b1ea7cf23b7f58fe2f4d42",
      measurementId: "G-JRB25PXD71"));
  } else {
    await Firebase.initializeApp();
  }

  runApp(const IMS());

  await addStudent(
    name: 'Chan MT',
    email: 'chan@gmail.com',
    contactNo: null,
    password: 'Password123',
    userType: 'Student',
    studID: '101',
    specialization: 'Software Engineering',
    resumeURL: 'https://example.com/resume.pdf',
    studProgram: 'Information Technology',
    dept: 'IT',
    companyID: null,
    supervisorID: null,
    intakePeriod: 'Jan-Apr 2025',
  );

  await addSupervisor(
    name: 'Chan TM',
    email: 'tm@gmail.com',
    supervisorID: '1001',
    dept: 'IT',
    contactNo: null,
    password: 'Password123',
    userType: 'Supervisor',
  );

  await addAdmin(
    name: 'Chan TM',
    email: 'admin@gmail.com',
    contactNo: '123456789',
    password: 'Password456',
    userType: 'Admin',
  );

  await addAdmin(
    name: 'Chan MM',
    email: 'admin2@gmail.com',
    contactNo: '123456789',
    password: 'Password456',
    userType: 'Admin',
  );

  await addGuideline(
    title: 'Welcome Slide',
    guidelineURL: 'https://testing.com',
    desc: 'testing 123',
    accessType: 'Supervisor',
  );

  await addExternal(
    compName: 'Tech Innovators',
    compEmail: 'info@techinnovators.com',
    compAddress: '123 Silicon Valley',
    compRegNo: 'TIN123456',
    compIndustry: 'E-Commerce',
    compYear: 2020,
    jobTitle: 'Software Developer Intern',
    jobDuration: 6,
    jobType: 'External',
    offerLetter: 'offer_letter_url',
    studID: '101',
    status: 'Pending',
    placementContactName: null,
    placementContactEmail: null,
    placementContactNo: null,
    placementJobTitle: null,
  );

  await addApplicant(
    studID: '101',
    jobID: 'vvb1mT01G6vgnNdbwgsi',
    applicationStatus: 'Pending',
    interviewStatus: 'None',
    dateApplied: '14 March 2025 at 00:00:00 UTC+8',
  );

  
  await addTemplate(
    templateID: '1',
    templateTitle: 'Offer Letter',
    templateDesc: 'The Offer Letter for the Internship. Student is only required to submit in PDF format.',
  );

  await addTemplate(
    templateID: '2',
    templateTitle: 'Log Report',
    templateDesc: 'Log Report. Please filled out the form and submit it by the end of the week.',
  );
  
  await addTemplate(
    templateID: '3',
    templateTitle: 'Final Report',
    templateDesc: 'Final Report. Please submit it by the end of the internship.',
  );

  await addTemplate(
    templateID: '4',
    templateTitle: 'Student Evaluation Form',
    templateDesc: 'Please fill out the form and submit it by the end of the internship.',
  );
}

Future<void> addStudent({
  required String name,
  required String email,
  String? contactNo,
  required String password,
  required String userType,
  required String studID,
  required String specialization,
  String? resumeURL,
  required String studProgram,
  required String dept,
  String? companyID,
  String? supervisorID,
  required String intakePeriod,
}) async {
  try {
    // Check if student with this studID already exists
    var studentDoc = await FirebaseFirestore.instance.collection('Student').doc(studID.toString()).get();
    
    if (studentDoc.exists) {
      debugPrint('Student with ID $studID already exists.');
      return; // Exit early if student already exists
    }

    // Add to Users collection first
    var userRef = await FirebaseFirestore.instance.collection('Users').add({
      'name': name,
      'email': email,
      'contactNo': contactNo,
      'password': password,
      'userType': userType,
    });

    String userID = userRef.id;
    debugPrint('User added successfully');

    // Add student document with studID as the document ID
    await FirebaseFirestore.instance.collection('Student').doc(studID.toString()).set({
      'studID': studID,
      'specialization': specialization,
      'resumeURL': resumeURL,
      'studProgram': studProgram,
      'userID': userID,
      'dept': dept,
      'companyID': companyID,
      'supervisorID': supervisorID,
      'intakePeriod': intakePeriod,
    });

    debugPrint('Student added successfully');
  } catch (e) {
    debugPrint('Error adding student: $e');
  }
}

Future<void> addAdmin({
  required String name,
  required String email,
  String? contactNo,
  required String password,
  required String userType,
}) async {
  try {
    // Check if admin with this email already exists
    var adminQuery = await FirebaseFirestore.instance.collection('Users')
        .where('email', isEqualTo: email)
        .where('userType', isEqualTo: 'Admin')
        .get();

    if (adminQuery.docs.isNotEmpty) {
      debugPrint('Admin with email $email already exists.');
      return; // Exit early if admin already exists
    }

    // Add to Users collection first
    var userRef = await FirebaseFirestore.instance.collection('Users').add({
      'name': name,
      'email': email,
      'contactNo': contactNo,
      'password': password,
      'userType': userType,
    });

    String userID = userRef.id;
    print('User added successfully');

    // Generate a new document ID for the admin document
    await FirebaseFirestore.instance.collection('Admin').add({
      'userID': userID,
    });

    print('Admin added successfully');
  } catch (e) {
    print('Error adding admin: $e');
  }
}

Future<void> addSupervisor({
  required String name,
  required String email,
  String? contactNo,
  required String password,
  required String userType,
  required String supervisorID,
  required String dept,
}) async {
  try {
    // Check if supervisor with this supervisorID already exists
    var supervisorDoc = await FirebaseFirestore.instance.collection('Supervisor').doc(supervisorID.toString()).get();
    
    if (supervisorDoc.exists) {
      debugPrint('Supervisor with ID $supervisorID already exists.');
      return; // Exit early if supervisor already exists
    }

    // Add to Users collection first
    var userRef = await FirebaseFirestore.instance.collection('Users').add({
      'name': name,
      'email': email,
      'contactNo': contactNo,
      'password': password,
      'userType': userType,
    });

    String userID = userRef.id;
    debugPrint('User added successfully');

    // Add supervisor document with supervisorID as the document ID
    await FirebaseFirestore.instance.collection('Supervisor').doc(supervisorID.toString()).set({
      'supervisorID': supervisorID,
      'userID': userID,
      'dept': dept,
    });

    debugPrint('Supervisor added successfully');
  } catch (e) {
    debugPrint('Error adding supervisor: $e');
  }
}

Future<void> addGuideline({
  required String title,
  required String guidelineURL,
  required String desc,
  required String accessType,
}) async {
  try {
    // Check if data already exists
    var guidelineDoc = await FirebaseFirestore.instance.collection('Guideline')
        .where('title', isEqualTo: title)
        .where('accessType', isEqualTo: accessType)
        .get();
    
    if (guidelineDoc.docs.isNotEmpty) {
      debugPrint('Guideline with Title: $title already exists.');
      return; // Exit early if guideline already exists
    }

    // Add to Guideline collection
    await FirebaseFirestore.instance.collection('Guideline').add({
      'title': title,
      'guidelineURL': guidelineURL,
      'desc': desc,
      'accessType': accessType,
    });
    debugPrint('Guideline added successfully');
  } catch (e) {
    debugPrint('Error adding guideline: $e');
  }
}

Future<void> addExternal({
  required String compName,
  required String compEmail,
  required String compAddress,
  required String compRegNo,
  required String compIndustry,
  required int compYear,
  required String jobTitle,
  required int jobDuration,
  required String jobType,
  required String offerLetter,
  required String studID,
  required String status,
  String? placementContactName,
  String? placementContactEmail,
  String? placementContactNo,
  String? placementJobTitle,

}) async {
  try {
    // Check if data already exists
    var externalDoc = await FirebaseFirestore.instance.collection('External')
        .where('exCompName', isEqualTo: compName)
        .where('exJobTitle', isEqualTo: jobTitle)
        .get();
    
    if (externalDoc.docs.isNotEmpty) {
      debugPrint('User: $compName already exists.');
      return;
    }

    await FirebaseFirestore.instance.collection('External').add({
          'exCompName': compName,
          'exCompEmail': compEmail,
          'exCompAddress': compAddress,
          'exCompRegNo': compRegNo,
          'exCompYear': compYear,
          'exJobTitle': jobTitle,
          'exJobDuration': jobDuration,
          'offerLetter': offerLetter,
          'studID': studID,
          'exComIndustry': compIndustry,
          'exJobType': jobType,
          'externalStatus': status,
          'placementContactName': placementContactName,
          'placementContactEmail': placementContactEmail,
          'placementContactNo': placementContactNo,
          'placementJobTitle': placementJobTitle,
    });
    debugPrint('External Application added successfully');
  } catch (e) {
    debugPrint('Error adding external: $e');
  }
}

Future<void> addApplicant({
  required String studID,
  required String jobID,
  required String interviewStatus,
  required String applicationStatus,
  required String dateApplied,

}) async {
  try {
    // Check if data already exists
    var externalDoc = await FirebaseFirestore.instance.collection('Application')
        .where('studID', isEqualTo: studID)
        .where('jobID', isEqualTo: jobID)
        .get();
    
    if (externalDoc.docs.isNotEmpty) {
      debugPrint('Application already exists.');
      return;
    }

    await FirebaseFirestore.instance.collection('Application').add({
          'jobID': jobID,
          'interviewStatus': interviewStatus,
          'applicationStatus': applicationStatus,
          'studID': studID,
          'dateApplied': dateApplied,
    });
    debugPrint('Application added successfully');
  } catch (e) {
    debugPrint('Error adding application: $e');
  }
}

Future<void> addTemplate({
  required String templateID,
  required String templateTitle,
  required String templateDesc,

}) async {
  try {
    // Check if data already exists
    var externalDoc = await FirebaseFirestore.instance.collection('Template')
        .where('templateTitle', isEqualTo: templateTitle)
        .where('templateDesc', isEqualTo: templateDesc)
        .get();
    
    if (externalDoc.docs.isNotEmpty) {
      debugPrint('Template already exists.');
      return;
    }

    await FirebaseFirestore.instance.collection('Template').doc(templateID.toString()).set({
          'templateTitle': templateTitle,
          'templateDesc': templateDesc,
    });
    debugPrint('Template added successfully');
  } catch (e) {
    debugPrint('Error adding Template: $e');
  }
}

class IMS extends StatelessWidget {
  const IMS({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IMS',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Jost',
      ),
      home: kIsWeb ?  const LoginWeb() : const WelcomeSlider(),
    );
  }
}