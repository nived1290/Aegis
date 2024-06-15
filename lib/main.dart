import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert'; // For UTF-8 encoding
import 'package:crypto/crypto.dart'; // For SHA-256 hashing
import 'welcome.dart';
import 'dash.dart';
import 'user.dart';



void main() {
  runApp(Muris());
}

class Muris extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FutureBuilder<bool>(
        future: checkFirstTime(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            bool isFirstTime = snapshot.data ?? true;

            if (isFirstTime) {
              return WelcomeScreen();
            } else {
              return LogoScreen();
            }
          } else {
            return CircularProgressIndicator();
          }
        },
      ),
      routes: {
        '/dashboard': (context) => DashScreen(),
        '/userDetails': (context) => UserDetailsScreen(),
        '/lock': (context) => PinEntryScreen(),
      },
    );
  }
  Future<bool> checkFirstTime() async {
    final storage = FlutterSecureStorage();
    String? storedHashedPIN = await storage.read(key: 'hashedPIN');
    bool isFirstTime = storedHashedPIN == null ? true : false;
    return isFirstTime;
  }

}

class LogoScreen extends StatefulWidget {
  @override
  _LogoScreenState createState() => _LogoScreenState();
}

class _LogoScreenState extends State<LogoScreen> {
  @override
  void initState() {
    super.initState();
    // Start the delay when the widget is first created
    Future.delayed(Duration(seconds: 2), () {
      // Navigate to the PinEntryScreen after the delay
      Navigator.pushReplacementNamed(context, '/lock');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A192F), Color(0xFF112240)], // Dark shade with Blue
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Your App Logo or Welcome Message
              Image.asset(
                'assets/Logo.png', // Replace with your futuristic logo asset
                width: 120,
                height: 120,
              ),
              SizedBox(height: 16),
              Text(
                'AEGIS',
                style: TextStyle(
                  color: Color(0xFF64FFDA),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Futura', // Use a futuristic font
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Securing Today, Shielding Tomorrow ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF64FFDA),
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PinEntryScreen extends StatefulWidget {
  @override
  _PinEntryScreenState createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends State<PinEntryScreen> {
  final TextEditingController pinController = TextEditingController();
  String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2A0343), Color(0xFF01162A)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Enter Your PIN',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF69F0AE), // Accent color
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              style: TextStyle(color: Colors.white), // Text color
              decoration: InputDecoration(
                hintText: 'PIN',
                hintStyle: TextStyle(color: Colors.white70), // Hint text color
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white), // Border color
                ),
              ),
            ),
            SizedBox(height: 8),
            if (errorMessage != null)
              Text(
                errorMessage!,
                style: TextStyle(color: Colors.red),
              ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                String pin = pinController.text.trim();

                final storage = FlutterSecureStorage();
                String? storedHashedPIN = await storage.read(key: 'hashedPIN');

                if (storedHashedPIN == null) {
                  setState(() {
                    errorMessage = 'PIN not set. Please set your PIN first.';
                  });
                  return;
                }

                String enteredHashedPIN = sha256.convert(utf8.encode(pin)).toString();

                if (enteredHashedPIN == storedHashedPIN) {
                  Navigator.pushReplacementNamed(context, '/dashboard');
                } else {
                  setState(() {
                    errorMessage = 'Invalid PIN. Please try again.';
                  });
                }
              },
              child: Text('Unlock'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF69F0AE), // Accent color
              ),
            ),
          ],
        ),
      ),
    );
  }
}
