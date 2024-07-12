import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rive/rive.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _showMadeByATalk = false;
  bool _showLoading = true;

  @override
  void initState() {
    super.initState();
    _startAnimationSequence();
    _checkAuthentication();
  }

  void _startAnimationSequence() async {
    await Future.delayed(const Duration(seconds: 3));
    setState(() {
      _showLoading = false;
      _showMadeByATalk = true;
    });

    await Future.delayed(const Duration(seconds: 3));
    _navigateToNextScreen();
  }

  void _checkAuthentication() async {
    // Simulate a delay for the splash screen
    await Future.delayed(const Duration(seconds: 6));

    // Check if the user is already signed in
    if (FirebaseAuth.instance.currentUser != null) {
      log('\nUser: ${FirebaseAuth.instance.currentUser}');
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const HomeScreen()));
    } else {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => const LoginScreen()));
    }
  }

  void _navigateToNextScreen() {
    if (FirebaseAuth.instance.currentUser != null) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const HomeScreen()));
    } else {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _showLoading
            ? RiveAnimation.asset(
                'Images/panda.riv',
                fit: BoxFit.cover,
              )
            : _showMadeByATalk
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('Images/chat.png',
                          width: MediaQuery.of(context).size.width * 0.5),
                      const SizedBox(height: 20),
                      const Text('Made by A Talk',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  )
                : Container(),
      ),
    );
  }
}
