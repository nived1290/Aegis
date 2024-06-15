import 'package:flutter/material.dart';
import 'package:safe_url_check/safe_url_check.dart';
import 'package:url_launcher/url_launcher.dart';

class LinkScreen extends StatefulWidget {
  @override
  _LinkScreenState createState() => _LinkScreenState();
}

class _LinkScreenState extends State<LinkScreen> {
  String _url = '';
  bool? _isSafe; // Initially null
  bool _openDirectly = false; // Initially false

  Future<void> _checkUrl() async {
    if (_url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a URL to check.'),
        ),
      );
      return;
    }

    // If the URL is not prefixed with 'https://', notify the user to add it
    if (!_url.startsWith('https://')) {
      _url = 'https://' + _url;
    }

    Uri parsedUrl;
    try {
      parsedUrl = Uri.parse(_url);
    } on FormatException catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid URL.'),
        ),
      );
      return;
    }

    final exists = await safeUrlCheck(parsedUrl);

    setState(() {
      _isSafe = exists;
    });

    if (_isSafe == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'The safety of this URL is uncertain. Consider rechecking or using a different security measure.'),
        ),
      );
    } else if (_isSafe!) {
      if (_openDirectly) {
        _launchURL(
            parsedUrl); // Open URL directly if safe and checkbox is toggled
      } else {
        // Show 'Link is safe' message and 'Open in Browser' button on the screen
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The URL is unsafe.'),
        ),
      );
    }

    // Show detailed report regardless of the safety status
  }

  Future<void> _launchURL(Uri url) async {
    if (await launchUrl(url)) {
      try {
        await launchUrl(url); // Use launchUrl with the parsed Uri
      } catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to launch the URL. Please try again later.'),
          ),
        );
      }
    } else {
      // Handle cases where launching fails based on `canLaunchUrl`
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Failed to launch the URL. Please check the URL and try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2A0343),
      appBar: AppBar(
        title: const Text(
          'Link Analysis',
          style: TextStyle(
            color: Color(0xFF69F0AE),
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'BebasNeue',
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white), // Add an arrow back icon
          onPressed: () {
            Navigator.of(context).pop(); // Navigate back when the icon is pressed
          },
        ),
        backgroundColor: const Color(0xFF2A0343),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32.0), // Increased spacing for cleaner look
            TextField(
              onChanged: (text) => _url = text,
              keyboardType: TextInputType.url,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF33373E), // Dark grey text field
                hintText: 'Enter URL',
                hintStyle: const TextStyle(color: Colors.white54),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  borderSide: const BorderSide(color: Colors.transparent),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 12.0),
                prefixIcon: const Icon(
                  Icons.link,
                  color: Colors.white54,
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _checkUrl,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF69F0AE), // Light green button
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
              ),
              child: const Text(
                'Scan Link',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 16.0),
            if (_isSafe != null && _isSafe!)
              Row(
                children: [
                  const Text(
                    'Link is safe. ',
                    style: TextStyle(color: Colors.green),
                  ),
                  TextButton(
                    onPressed: () => _launchURL(Uri.parse(_url)),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                    ),
                    child: const Text(
                      'Open in Browser',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16.0),
            if (_isSafe != null && !_isSafe!)
              const Text(
                'The URL is unsafe.',
                style: TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 24.0),
            Row(
              children: [
                Checkbox(
                  value: _openDirectly,
                  onChanged: (value) {
                    setState(() {
                      _openDirectly = value!;
                    });
                  },
                  activeColor: const Color(
                      0xFF69F0AE), // Light green for active checkbox
                ),
                const Text(
                  'Open directly if safe',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
