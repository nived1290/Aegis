import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart'; // For SHA-256 hashing
import 'dash.dart';

class UserDetailsScreen extends StatefulWidget {
  @override
  _UserDetailsScreenState createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController pinController = TextEditingController();
  final TextEditingController confirmPinController = TextEditingController();
  String? errorMessage;

  Future<void> _saveCred(String userName, String hashedPIN) async {
    final storage = FlutterSecureStorage();
    await storage.write(key: 'userName', value: userName);
    await storage.write(key: 'hashedPIN', value: hashedPIN);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF2A0343),
        automaticallyImplyLeading: false, // Remove back button
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2A0343), Color(0xFF01162A)],
          ),
        ),
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Your Name Field
            _buildInputField(
              controller: nameController,
              hintText: 'Your Name',
            ),
            SizedBox(height: 16),

            // PIN Field
            _buildInputField(
              controller: pinController,
              hintText: 'Enter 6-digit PIN',
              keyboardType: TextInputType.number,
              obscureText: true,
            ),
            SizedBox(height: 16),

            // Confirm PIN Field
            _buildInputField(
              controller: confirmPinController,
              hintText: 'Confirm 6-digit PIN',
              keyboardType: TextInputType.number,
              obscureText: true,
            ),
            SizedBox(height: 8),
            if (errorMessage != null) // Display error message if any
              Text(
                errorMessage!,
                style: TextStyle(color: Colors.red),
              ),
            SizedBox(height: 32),

            // Continue Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                // Add any other desired button styles here
              ),
              onPressed: () async {
                // Validate and process user input
                String name = nameController.text.trim();
                String pin = pinController.text.trim();
                String confirmPin = confirmPinController.text.trim();

                // Validate Name
                if (name.isEmpty || name.contains(RegExp(r'[0-9]'))) {
                  setState(() {
                    errorMessage = 'Please enter a valid name.';
                  });
                  return;
                }

                // Validate PIN
                if (pin.length != 6 || !pin.contains(RegExp(r'^[0-9]+$'))) {
                  setState(() {
                    errorMessage = 'Please enter a valid 6-digit PIN.';
                  });
                  return;
                }

                // Check if PINs match
                if (pin != confirmPin) {
                  setState(() {
                    errorMessage = 'PINs do not match. Please try again.';
                  });
                  return;
                }

                // Encrypt PIN using SHA-256 hashing
                String hashedPIN = sha256.convert(utf8.encode(pin)).toString();

                // Save hashed PIN to secure storage
                await _saveCred(name, hashedPIN);

                // Navigate to the Dashboard directly
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => DashScreen()),
                );
              },
              child: Text(
                'Continue',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: TextStyle(color: Colors.white),
      onChanged: (_) {
        // Clear error message when user modifies the PIN fields
        setState(() {
          errorMessage = null;
        });
      },
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.white),
        filled: true,
        fillColor: Color(0xFF01162A),
        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}