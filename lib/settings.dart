import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? selectedDownloadPath;
  bool privateKeyAdded = false;
  bool publicKeyAdded = false;
  final TextEditingController oldPinController = TextEditingController();
  final TextEditingController newPinController = TextEditingController();
  final TextEditingController confirmPinController = TextEditingController();
  String? errorMessage;
  bool pathSelected = false; // Flag to track if a path is selected

  @override
  void initState() {
    super.initState();
    _checkDownloadPath();
    _checkKeyPairs();
  }

  Future<void> _checkDownloadPath() async {
    final storage = FlutterSecureStorage();
    selectedDownloadPath = await storage.read(key: 'downloadPath');
    if (selectedDownloadPath != null) {
      setState(() {
        pathSelected = true;
      });
    }
  }

  Future<void> _checkKeyPairs() async {
    final storage = FlutterSecureStorage();
    final privateKeyExists = await storage.containsKey(key: 'private_key.pem');
    final publicKeyExists = await storage.containsKey(key: 'public_key.pem');
    if (privateKeyExists && publicKeyExists) {
      setState(() {
        privateKeyAdded = true;
        publicKeyAdded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white), // Add an arrow back icon
          onPressed: () {
            Navigator.of(context).pop(); // Navigate back when the icon is pressed
          },
        ),
        backgroundColor: Color(0xFF2A0343),
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2A0343), Color(0xFF01162A)],
          ),
        ),
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Change Password',
                style: TextStyle(
                  color: Color(0xFF69F0AE),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              // TextFields for entering old, new, and confirm passwords
              TextField(
                controller: oldPinController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Old Pin',
                  labelStyle: TextStyle(color: Colors.white),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                keyboardType: TextInputType.number, // Set keyboard type to numerical
              ),
              SizedBox(height: 8),
              TextField(
                controller: newPinController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'New Pin',
                  labelStyle: TextStyle(color: Colors.white),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                keyboardType: TextInputType.number, // Set keyboard type to numerical
              ),


              SizedBox(height: 8),
              TextField(
                controller: confirmPinController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Confirm Pin',
                  labelStyle: TextStyle(color: Colors.white),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                keyboardType: TextInputType.number, // Set keyboard type to numerical
              ),

              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _changePassword,
                child: Text('Change Password'),
              ),
              SizedBox(height: 24),
              Text(
                'Download Path',
                style: TextStyle(
                  color: Color(0xFF69F0AE),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: () async {
                  selectedDownloadPath = await _selectDownloadPath(context);
                  if (selectedDownloadPath != null) {
                    setState(() {
                      pathSelected = true; // Update the flag
                    });
                    await _saveDownloadPath(selectedDownloadPath!);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Download path selected: $selectedDownloadPath')),
                    );
                  }
                },
                child: Text(pathSelected ? 'Change Download Path' : 'Select Download Path'), // Change button text dynamically
              ),
              if (pathSelected && selectedDownloadPath != null) // Display selected path
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Selected Path: $selectedDownloadPath',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              SizedBox(height: 24),
              Visibility(
                visible: !privateKeyAdded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Private Key',
                      style: TextStyle(
                        color: Color(0xFF69F0AE),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        _importPrivateKey(context);
                      },
                      child: Text('Import Private Key File'),
                    ),
                    SizedBox(height: 24),
                  ],
                ),
              ),
              Visibility(
                visible: !publicKeyAdded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Public Key',
                      style: TextStyle(
                        color: Color(0xFF69F0AE),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        _importPublicKey(context);
                      },
                      child: Text('Import Public Key File'),
                    ),
                    SizedBox(height: 24),
                  ],
                ),
              ),
              Visibility(
                visible: privateKeyAdded && publicKeyAdded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Key Pair',
                      style: TextStyle(
                        color: Color(0xFF69F0AE),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        _changeKeys(context);
                      },
                      child: Text('Change Keys'),
                    ),
                    SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _selectDownloadPath(BuildContext context) async {
    String? selectedPath = await FilePicker.platform.getDirectoryPath();
    return selectedPath;
  }

  Future<void> _saveDownloadPath(String selectedPath) async {
    final storage = FlutterSecureStorage();
    await storage.write(key: 'downloadPath', value: selectedPath);
  }

  Future<void> _importPrivateKey(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pem'],
    );
    if (result != null) {
      File file = File(result.files.single.path!);
      await _saveKeyToStorage(context, file, 'private_key.pem'); // Pass the context here
      setState(() {
        privateKeyAdded = true;
      });
    }
  }

  Future<void> _importPublicKey(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pem'],
    );
    if (result != null) {
      File file = File(result.files.single.path!);
      await _saveKeyToStorage(context, file, 'public_key.pem'); // Pass the context here
      setState(() {
        publicKeyAdded = true;
      });
    }
  }

  Future<void> _changeKeys(BuildContext context) async {
    // Logic to change keys goes here
    setState(() {
      privateKeyAdded = false;
      publicKeyAdded = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Keys changed successfully!')),
    );
  }

  Future<void> _saveKeyToStorage(BuildContext context, File file, String fileName) async {
    try {
      // Read the content of the file
      List<int> fileBytes = await file.readAsBytes();
      String fileContent = String.fromCharCodes(fileBytes);

      // Store the file content in secure storage
      final storage = FlutterSecureStorage();
      await storage.write(key: fileName, value: fileContent);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$fileName saved successfully!')),
      );
    } catch (e) {
      print('Error saving $fileName: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save $fileName. Please try again later.')),
      );
    }
  }

  void _changePassword() async {
    // Validate and process user input
    String oldPin = oldPinController.text.trim();
    String newPin = newPinController.text.trim();
    String confirmPin = confirmPinController.text.trim();

    // Retrieve old hashed PIN from secure storage
    final storage = FlutterSecureStorage();
    String? storedHashedPIN = await storage.read(key: 'hashedPIN');

    // Validate Old Password
    if (sha256.convert(utf8.encode(oldPin)).toString() != storedHashedPIN) {
      setState(() {
        errorMessage = 'Old Password is incorrect.';
      });
      return;
    }

    // Validate New Password and Confirm Password
    if (newPin.length != 6 || !newPin.contains(RegExp(r'^[0-9]+$'))) {
      setState(() {
        errorMessage = 'Please enter a valid 6-digit New Password.';
      });
      return;
    }
    if (newPin != confirmPin) {
      setState(() {
        errorMessage = 'New Passwords do not match. Please try again.';
      });
      return;
    }

    // Encrypt New PIN using SHA-256 hashing
    String hashedNewPIN = sha256.convert(utf8.encode(newPin)).toString();

    // Save new hashed PIN to secure storage
    await _savePIN(hashedNewPIN);

    // Clear text fields and show success message
    oldPinController.clear();
    newPinController.clear();
    confirmPinController.clear();
    setState(() {
      errorMessage = 'Password changed successfully!';
    });
  }

  Future<void> _savePIN(String hashedPIN) async {
    final storage = FlutterSecureStorage();
    await storage.write(key: 'hashedPIN', value: hashedPIN);
  }
}
