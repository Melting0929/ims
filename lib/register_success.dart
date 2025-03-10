import 'package:flutter/material.dart';
import 'login_web.dart';

class RegistrationSuccessPage extends StatelessWidget {
  const RegistrationSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registration Successful'),
        backgroundColor: const Color(0xFFE6AA68),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Registration Successful!',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE9C46A),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'You will need to wait for admin approval.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, color: Colors.black54),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginWeb()),
                );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE6AA68),
                ),
                child: const Text('Go Back to Home', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
