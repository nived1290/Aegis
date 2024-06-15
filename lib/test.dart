import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TestScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Test VirusTotal Report',
          style: TextStyle(
            color: Color(0xFF69F0AE),
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'BebasNeue',
          ),
        ),
        backgroundColor: Color(0xFF2A0343),
      ),
      body: Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 16.0),
            TextField(
              decoration: InputDecoration(
                hintText: 'Enter a URL',
              ),
              onSubmitted: (url) => _fetchVirusTotalReport(url, context), // Pass context
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () => _fetchVirusTotalReport('https://flutter.dev', context), // Pass context for default URL
              child: Text(
                'Get VirusTotal Report',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF69F0AE),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchVirusTotalReport(String url, BuildContext context) async {
    final apiKey = '3e62d9ec9a37467528c901a3653af00ae4dc9b622ad676d21190bd81e1bedbda'; // Replace with your VirusTotal API key
    final virusTotalUrl = Uri.parse('https://www.virustotal.com/api/v3/urls/$url');

    final headers = {'Authorization': 'Bearer $apiKey'};

    final response = await http.get(virusTotalUrl, headers: headers);

    if (response.statusCode == 200) {
      final virusTotalData = jsonDecode(response.body) as Map<String, dynamic>;

      // Process the virusTotalData to display relevant information
      // (e.g., detection status, detection rate)
      final scanResults = virusTotalData['data']['attributes']['last_analysis_results'];
      final detected = scanResults['malicious'] ? 'detected' : 'not detected';
      final detectionRate = scanResults['positives'] / scanResults['total'];

      final report = 'VirusTotal Scan Results:\n'
          '  - Detected: $detected\n'
          '  - Detection Rate: $detectionRate';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(report),
        ),
      );
    } else {
      // Handle error scenarios (e.g., invalid API key, rate limits)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching VirusTotal data: ${response.statusCode}'),
        ),
      );
    }
  }
}
