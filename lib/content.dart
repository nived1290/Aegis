import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
class ContentScreen extends StatefulWidget {
  @override
  _ContentScreenState createState() => _ContentScreenState();
}

class _ContentScreenState extends State<ContentScreen> {
  String? _selectedFile; // Make _selectedFile nullable
  String _scanResult = '';
  Map<String, String> _database = {};

  // Function to handle file selection
  Future<void> _selectFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null) {
        PlatformFile file = result.files.first;
        setState(() {
          _selectedFile = file.path; // Set _selectedFile to the actual path
        });
      } else {
        // User canceled the file picker
        setState(() {
          _selectedFile = 'File selection canceled.';
        });
      }
    } catch (e) {
      setState(() {
        _selectedFile = 'Error picking file: $e';
      });
    }
  }


  // Function to read and parse the database files
  Future<void> _readDatabaseFiles() async {
    try {
      String virusInfoContent =
      await rootBundle.loadString('assets/virusinfo.unibit');
      String virusHashContent =
      await rootBundle.loadString('assets/virusHash.unibit');

      List<String> virusInfoLines = LineSplitter.split(virusInfoContent).toList();
      List<String> virusHashLines = LineSplitter.split(virusHashContent).toList();

      // Ensure both files have the same number of lines
      if (virusInfoLines.length != virusHashLines.length) {
        throw Exception('Database files are not synchronized.');
      }

      // Create mapping between hash values and malware types
      for (int i = 0; i < virusInfoLines.length; i++) {
        String malwareType = virusInfoLines[i];
        String hashValue = virusHashLines[i];
        _database[hashValue] = malwareType;
      }
      print("Database entered");
    } catch (e) {
      print('Error reading database files: $e');
    }
  }

  // Function to scan a file
  Future<void> _scanFile() async {
    if (_selectedFile != null && _selectedFile!.isNotEmpty) { // Add null check
      File fileToScan = File(_selectedFile!); // Use ! to assert non-null
      if (fileToScan.existsSync()) {
        try {
          // Read the file as bytes
          List<int> bytes = await fileToScan.readAsBytes();

          // Compute SHA-256 hash
          Digest sha256Hash = sha256.convert(bytes);
          String fileHash = sha256Hash.toString();
          print(fileHash);
          // Check if the hash value exists in the database
          String? malwareType = _database[fileHash];
          if (malwareType != null) {
            setState(() {
              _scanResult = 'File is potentially malicious! Malware type: $malwareType';
            });
          } else {
            setState(() {
              _scanResult = 'File is safe.';
            });
          }
        } catch (e) {
          setState(() {
            _scanResult = 'Error scanning file: $e';
          });
        }
      } else {
        setState(() {
          _scanResult = 'File not found.';
        });
      }
    } else {
      setState(() {
        _scanResult = 'No file selected.';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _readDatabaseFiles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF2A0343),
        title: Text(
          'File Scanner',
          style: TextStyle(fontSize: 24, color: Colors.white),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white), // Add an arrow back icon
          onPressed: () {
            Navigator.of(context).pop(); // Navigate back when the icon is pressed
          },
        ),
      ),

      body: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2A0343), Color(0xFF01162A)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _selectFile,
              child: Text(
                'Select File',
                style: TextStyle(fontSize: 20),
              ),
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Color(0xFF69F0AE)),
                padding: MaterialStateProperty.all(
                  EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              _selectedFile ?? '', // Add null check
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: _scanFile,
              child: Text(
                'Start Scan',
                style: TextStyle(fontSize: 20),
              ),
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Color(0xFF69F0AE)),
                padding: MaterialStateProperty.all(
                  EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              _scanResult,
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
