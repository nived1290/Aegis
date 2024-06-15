import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class WelcomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: Key('welcome_screen'), // Named parameter for the key
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2A0343), Color(0xFF01162A)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo with Cyberpunk Twist
              Container(
                margin: EdgeInsets.symmetric(vertical: 20),
                child: Image.asset(
                  'assets/Logo.png', // Replace with your cyberpunk logo asset
                  width: 120,
                  height: 120,
                ),
              ),

              // Your Welcome Message
              Text(
                'Welcome to Aegis',
                style: TextStyle(
                  color: Color(0xFF69F0AE),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),

              // Brief Description with Edgy Styling
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'Your personal security companion.\nDefending against cyber threats in the future.',
                  style: const TextStyle(
                    // Use const with TextStyle
                    color: Colors.white,
                    fontSize: 18,
                    letterSpacing: 1.2, // Adjust for edgy styling
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // Get Started Button
              ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(
                      Color(0xFF69F0AE)), // Set the background color
                ),
                onPressed: () async {
                  // Request storage permission
                  var status = await Permission.storage.request();
                  if (status.isGranted) {
                    // Permission is granted, proceed to UserDetailsScreen
                    Navigator.pushReplacementNamed(context, '/userDetails');
                  } else {
                    // Permission is denied, handle accordingly
                    print('Storage permission is denied');
                    // You can show a dialog or snackbar to inform the user about the permission denial
                  }
                },
                child: Text(
                  'Get Started',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
