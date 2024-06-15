import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'pass.dart'; // Import your password manager file
import 'link.dart'; // Import your link analysis file
import 'vault.dart';
import 'eh.dart'; // Import Encryption Helper
import 'content.dart';
import 'settings.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dashboard Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: DashScreen(),
    );
  }
}

class DashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _getUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }
          // Retrieve the user name
          String userName = snapshot.data.toString();
          return _buildDashboard(context, userName); // Pass the context and userName
        } else {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
      },
    );
  }

  // Function to retrieve user data from storage
  Future<String> _getUserData() async {
    final storage = FlutterSecureStorage();
    String? userName = await storage.read(key: 'userName');
    return userName ?? ''; // Return empty string if user name is null
  }

  Widget _buildDashboard(BuildContext context, String userName) { // Add context parameter
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Image.asset(
                  'assets/Logo.png',
                  width: 32,
                  height: 32,
                ),
                SizedBox(width: 8),
                Text(
                  'AEGIS',
                  style: TextStyle(
                    color: Color(0xFF69F0AE),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'BebasNeue',
                  ),
                ),
              ],
            ),
            IconButton(
              icon: Icon(Icons.settings, color: Colors.white),
              onPressed: () => navigateTo(context, SettingsScreen()),
            ),
          ],
        ),
        backgroundColor: Color(0xFF2A0343),
      ),
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2A0343), Color(0xFF01162A)],
            ),
          ),
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Welcome $userName',
                  style: TextStyle(
                    color: Color(0xFF69F0AE),
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'BebasNeue',
                  ),
                ),
              ),
              const Text(
                'Dashboard',
                style: TextStyle(
                  color: Color(0xFF69F0AE),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'BebasNeue',
                ),
              ),
              SizedBox(height: 16),

              // Password Generator Function
              buildDashboardFunction(
                context: context, // Pass the context
                icon: Icons.vpn_key, // Changed icon
                title: 'Cred Hub',
                description: 'Generate and manage passwords',
                onPressed: () => navigateTo(context, PassScreen()),
              ),

              buildDashboardFunction(
                context: context, // Pass the context
                icon: Icons.link, // Changed icon
                title: 'Link Analysis',
                description: 'Analyze links for safety',
                onPressed: () => navigateTo(context, LinkScreen()),
              ),

              buildDashboardFunction(
                context: context, // Pass the context
                icon: Icons.lock,
                title: 'E/D Tool',
                description: 'Encrypt/Decrypt',
                onPressed: () => navigateTo(context, CryptoScreen()),
              ),

              buildDashboardFunction(
                context: context, // Pass the context
                icon: Icons.folder,
                title: 'Vault',
                description: 'Securely store and manage files',
                onPressed: () => navigateTo(context, VaultScreen()),
              ),

              buildDashboardFunction(
                context: context, // Pass the context
                icon: Icons.file_copy, // Changed icon
                title: 'File Scanning',
                description: 'Scan Files',
                onPressed: () => navigateTo(context, ContentScreen()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Reusable function to navigate to a different screen
  void navigateTo(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  // Reusable function to build DashboardFunction widget
  Widget buildDashboardFunction({
    required BuildContext context, // Add BuildContext parameter
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        margin: EdgeInsets.only(bottom: 16.0),
        decoration: BoxDecoration(
          color: Colors.transparent, // Use transparent color
          borderRadius: BorderRadius.circular(10.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: Colors.white), // Use white color for icon
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // Use white color for title
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(color: Colors.white), // Use white color for description
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
