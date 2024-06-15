import 'dart:convert';
import 'dart:io';
import 'dart:math' show Random;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart'; // Import url_launcher package

class PasswordData {
  String username;
  String password;
  String site;
  String note;

  PasswordData({
    required this.username,
    required this.password,
    required this.site,
    required this.note,
  });
}

class PasswordUtils {
  static Future<List<PasswordData>> loadPasswords() async {
    try {
      final storage = FlutterSecureStorage();
      String? contents = await storage.read(key: 'passwords');
      if (contents != null) {
        final List<dynamic> data = jsonDecode(contents);

        List<PasswordData> passwords = [];
        for (var item in data) {
          passwords.add(PasswordData(
            username: item['username'],
            password: item['password'],
            site: item['site'],
            note: item['note'],
          ));
        }

        return passwords;
      }
    } catch (e) {
      print('Error loading passwords: $e');
    }

    // Return an empty list if there's an error
    return [];
  }
}

class PassScreen extends StatefulWidget {
  @override
  _PassScreenState createState() => _PassScreenState();
}

class _PassScreenState extends State<PassScreen> {
  String generatedPassword = '';
  bool showPasswordOptions = false;
  List<PasswordData> passwords = [];

  String generatePassword({int length = 12}) {
    const String uppercaseLetters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const String lowercaseLetters = 'abcdefghijklmnopqrstuvwxyz';
    const String numbers = '0123456789';
    const String symbols = '!@#\$%^&*()-=_+[]{}|;:\'",.<>?/';

    final String allCharacters =
        '$uppercaseLetters$lowercaseLetters$numbers$symbols';
    final Random random = Random();

    String password = '';

    for (int i = 0; i < length; i++) {
      password += allCharacters[random.nextInt(allCharacters.length)];
    }

    return password;
  }

  Future<void> savePassword(PasswordData passwordData) async {
    passwords.add(passwordData);

    final file = File('passwords.json');
    await file.writeAsString(jsonEncode(passwords));
  }

  Future<void> loadPasswords() async {
    List<PasswordData> loadedPasswords = await PasswordUtils.loadPasswords();
    setState(() {
      passwords = loadedPasswords;
    });
  }

  @override
  void initState() {
    super.initState();
    loadPasswords();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            SizedBox(width: 8),
            Text(
              'Cred Hub',
              style: TextStyle(
                color: Color(0xFF69F0AE),
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'BebasNeue',
              ),
            ),
          ],
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2A0343), Color(0xFF01162A)],
          ),
        ),
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    generatedPassword = generatePassword();
                    showPasswordOptions = true;
                  });
                },
                style: ButtonStyle(
                  backgroundColor:
                  MaterialStateProperty.all(Colors.transparent),
                  // Add other button styles as needed
                  textStyle: MaterialStateProperty.all(TextStyle(
                    fontSize: 16,
                    fontFamily: 'BebasNeue',
                    color: Colors.white,
                  )),
                  // Add more styles here...
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.lock,
                        size: 32,
                        color: Colors.white,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Generate Password',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'BebasNeue',
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              if (showPasswordOptions)
                Column(
                  children: [
                    Text(
                      'Generated Password:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      generatedPassword,
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 18,
                        fontFamily: 'BebasNeue',
                      ),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        Clipboard.setData(
                            ClipboardData(text: generatedPassword));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Password copied to clipboard'),
                          ),
                        );
                      },
                      style: ButtonStyle(
                        backgroundColor:
                        MaterialStateProperty.all(Colors.transparent),
                        // Add other button styles as needed
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.copy,
                              size: 32,
                              color: Colors.white,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Copy Password',
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: 'BebasNeue',
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                SavePasswordScreen(generatedPassword),
                          ),
                        );
                      },
                      style: ButtonStyle(
                        backgroundColor:
                        MaterialStateProperty.all(Colors.transparent),
                        foregroundColor: MaterialStateProperty.all(Colors
                            .white), // Renamed 'onPrimary' to 'foregroundColor'
                        shape: MaterialStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.save,
                              size: 32,
                              color: Colors.white,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Save Password',
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: 'BebasNeue',
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ManagePasswordScreen(passwords),
                    ),
                  );
                },
                style: ButtonStyle(
                  backgroundColor:
                  MaterialStateProperty.all(Colors.transparent),
                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.visibility,
                        size: 32,
                        color: Colors.white,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Manage Passwords',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'BebasNeue',
                          color: Colors.white,
                        ),
                      ),
                    ],
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

class SavePasswordScreen extends StatelessWidget {
  final String generatedPassword;

  SavePasswordScreen(this.generatedPassword);

  Future<void> savePassword(PasswordData passwordData) async {
    final storage = FlutterSecureStorage();
    try {
      String? contents = await storage.read(key: 'passwords');
      if (contents != null) {
        final List<dynamic> data = jsonDecode(contents);
        data.add({
          'username': passwordData.username,
          'password': passwordData.password,
          'site': passwordData.site,
          'note': passwordData.note,
        });
        await storage.write(key: 'passwords', value: jsonEncode(data));
      } else {
        await storage.write(
          key: 'passwords',
          value: jsonEncode([
            {
              'username': passwordData.username,
              'password': passwordData.password,
              'site': passwordData.site,
              'note': passwordData.note,
            }
          ]),
        );
      }
    } catch (e) {
      print('Error saving password: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    String username = '';
    String site = '';
    String note = '';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Save Password',
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
        backgroundColor: Color(0xFF2A0343),
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              TextField(
                onChanged: (value) => username = value,
                decoration: InputDecoration(
                  labelText: 'Username',
                  labelStyle: TextStyle(color: Colors.white),
                ),
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 16),
              TextField(
                onChanged: (value) => site = value,
                decoration: InputDecoration(
                  labelText: 'Site',
                  labelStyle: TextStyle(color: Colors.white),
                ),
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 16),
              TextField(
                onChanged: (value) => note = value,
                decoration: InputDecoration(
                  labelText: 'Note (Optional)',
                  labelStyle: TextStyle(color: Colors.white),
                ),
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 16),
              Text(
                'Generated Password:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 8),
              Text(
                generatedPassword,
                style: TextStyle(
                  color: Color(0xFF69F0AE),
                  fontSize: 18,
                  fontFamily: 'BebasNeue',
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  PasswordData passwordData = PasswordData(
                    username: username,
                    password: generatedPassword,
                    site: site,
                    note: note,
                  );

                  // Save the password
                  await savePassword(passwordData);

                  // Retrieve the updated list of passwords
                  List<PasswordData> updatedPasswords =
                  await PasswordUtils.loadPasswords();

                  // Navigate to the "Manage Passwords" screen with the updated list
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ManagePasswordScreen(updatedPasswords),
                    ),
                  );
                },
                style: ButtonStyle(
                  backgroundColor:
                  MaterialStateProperty.all(Colors.transparent),
                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
                child: Text(
                  'Save Password',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontFamily: 'BebasNeue',
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
class ManagePasswordScreen extends StatefulWidget {
  final List<PasswordData> passwords;

  ManagePasswordScreen(this.passwords);

  @override
  _ManagePasswordScreenState createState() => _ManagePasswordScreenState();
}

class _ManagePasswordScreenState extends State<ManagePasswordScreen> {
  late List<bool> isPasswordVisibleList;

  @override
  void initState() {
    super.initState();
    // Initialize the list with false values (passwords initially hidden)
    isPasswordVisibleList = List.generate(widget.passwords.length, (index) => false);
  }

  void deletePassword(int index) async {
    final storage = FlutterSecureStorage();
    try {
      String? contents = await storage.read(key: 'passwords');
      if (contents != null) {
        final List<dynamic> data = jsonDecode(contents);
        data.removeAt(index); // Remove the password at the specified index
        await storage.write(key: 'passwords', value: jsonEncode(data));
        setState(() {
          widget.passwords.removeAt(index); // Remove from the passwords list
          isPasswordVisibleList.removeAt(index); // Remove visibility status
        });
      }
    } catch (e) {
      print('Error deleting password: $e');
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Manage Passwords',
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
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
      ),
        backgroundColor: Color(0xFF2A0343),
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
        child: ListView.builder(
          itemCount: widget.passwords.length,
          itemBuilder: (BuildContext context, int index) {
            return PasswordItem(
              passwordData: widget.passwords[index],
              isPasswordVisible: isPasswordVisibleList[index],
              togglePasswordVisibility: () {
                setState(() {
                  isPasswordVisibleList[index] =
                  !isPasswordVisibleList[index];
                });
              },
              onDelete: () {
                deletePassword(index);
              },
            );
          },
        ),
      ),
    );
  }
}
class PasswordItem extends StatefulWidget {
  final PasswordData passwordData;
  final bool isPasswordVisible;
  final VoidCallback togglePasswordVisibility;
  final VoidCallback onDelete;

  PasswordItem({
    required this.passwordData,
    required this.isPasswordVisible,
    required this.togglePasswordVisibility,
    required this.onDelete,
  });

  @override
  _PasswordItemState createState() => _PasswordItemState();
}

class _PasswordItemState extends State<PasswordItem> {
  Future<void> _launchURL(Uri url) async {
    if (!url.toString().startsWith('https://')) {
      url = Uri.parse('https://${url.toString()}');
    }

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
    return Card(
      color: Color(0xFF01162A),
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Username: ${widget.passwordData.username}',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                Row(
                  children: [
                    if (widget.passwordData.site.isNotEmpty)
                      IconButton(
                        icon: Icon(
                          Icons.link,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          Uri url = Uri.parse(widget.passwordData.site);
                          _launchURL(url);
                        },
                      ),
                    IconButton(
                      icon: Icon(
                        widget.isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        // Toggle the password visibility
                        widget.togglePasswordVisibility();
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        // Confirm deletion
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('Confirm Deletion'),
                              content: Text(
                                  'Are you sure you want to delete this password?'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    widget.onDelete();
                                    Navigator.of(context).pop();
                                  },
                                  child: Text('Delete'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
            Text(
              'Site: ${widget.passwordData.site}',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            Text(
              'Note: ${widget.passwordData.note}',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            if (widget.isPasswordVisible)
              Text(
                'Password: ${widget.passwordData.password}',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
          ],
        ),
      ),
    );
  }
}
