import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart'; // For SHA-256 hashing
import 'dash.dart';

class LockScreen extends StatefulWidget {
  @override
  _LockScreenState createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final TextEditingController pinController = TextEditingController();
  String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              Text(
                'Enter Your PIN',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF69F0AE), // Accent color
                ),
              ),
              SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (int i = 1; i <= 9; i++) ...[
                      _buildPinButton(
                        label: '$i',
                        onPressed: () {
                          _appendToPinField('$i');
                        },
                      ),
                    ],
                    SizedBox(width: 16),
                    _buildPinButton(
                      label: '0',
                      onPressed: () {
                        _appendToPinField('0');
                      },
                    ),
                    SizedBox(width: 16),
                    IconButton(
                      onPressed: _clearPinField,
                      icon: Icon(Icons.backspace),
                      color: Color(0xFF69F0AE), // Accent color
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              if (errorMessage != null)
                Text(
                  errorMessage!,
                  style: TextStyle(color: Colors.red),
                ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _unlock,
                child: Text(
                  'Unlock',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF69F0AE), // Accent color
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPinButton({required String label, required VoidCallback onPressed}) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(
        label,
        style: TextStyle(fontSize: 24),
      ),
      style: ElevatedButton.styleFrom(
        shape: CircleBorder(), backgroundColor: Color(0xFF69F0AE),
        padding: EdgeInsets.all(24), // Accent color
      ),
    );
  }

  void _appendToPinField(String digit) {
    setState(() {
      pinController.text += digit;
    });
  }

  void _clearPinField() {
    setState(() {
      pinController.text = '';
    });
  }

  void _unlock() async {
    String pin = pinController.text.trim();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedHashedPIN = prefs.getString('hashedPIN');

    if (storedHashedPIN == null) {
      setState(() {
        errorMessage = 'PIN not set. Please set your PIN first.';
      });
      return;
    }

    String enteredHashedPIN = sha256.convert(utf8.encode(pin)).toString();

    if (enteredHashedPIN == storedHashedPIN) {
      String? storedUserName = prefs.getString('userName');
      if (storedUserName != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DashScreen()),
        );
      } else {
        setState(() {
          errorMessage = 'User name not found.';
        });
      }
    } else {
      setState(() {
        errorMessage = 'Invalid PIN. Please try again.';
      });
    }
  }
}
