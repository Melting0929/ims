// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'login_mobile.dart';
import 'assessment.dart';

// Display Welcome Slide
class WelcomeSlider extends StatefulWidget {
  final int? userId;

  const WelcomeSlider({super.key, this.userId});

  @override
  // ignore: library_private_types_in_public_api
  _WelcomeSliderState createState() => _WelcomeSliderState();
}

class _WelcomeSliderState extends State<WelcomeSlider> {
  final PageController _pageController = PageController(initialPage: 0);

  @override
  void initState() {
    super.initState();
    // Navigate to the login screen after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => LoginTab(userId: widget.userId),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: 1,
            itemBuilder: (context, index) {
              return const WelcomeSlide(imagePath: 'assets/images/login.png');
            },
          ),
        ],
      ),
    );
  }
}

class WelcomeSlide extends StatelessWidget {
  final String imagePath;

  const WelcomeSlide({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(imagePath),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class MainTab extends StatefulWidget {
  final int userId;

  const MainTab({super.key, required this.userId});

  @override
  // ignore: library_private_types_in_public_api
  _MainScreenState createState() => _MainScreenState();
}

// Display Bottom Navigation Bar
class _MainScreenState extends State<MainTab> {
  int _currentIndex = 0;
  late List<Widget> _tabs; 

  @override
  void initState() {
    super.initState();
    // Initialize _tabs after the widget is fully initialized
    _tabs = [
      AssessmentPage(userId: widget.userId),
      //CollectionTab(userId: widget.userId),
      //ProfileTab(userId: widget.userId),
    ];
  }

  // Method to handle bottom navigation bar tap events
  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IMS'),
      ),
      body: _tabs[_currentIndex],
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: const Color.fromARGB(255, 164, 205, 238),
          primaryColor: Colors.yellow,
          textTheme: Theme.of(context).textTheme.copyWith(
                // ignore: deprecated_member_use
                bodySmall: const TextStyle(color: Colors.white),
              ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: onTabTapped,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment),
              label: 'My Collection',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_circle_outlined),
              label: 'My Account',
            ),
          ],
        ),
      )
    );
  }
}

