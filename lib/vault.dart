import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class VaultScreen extends StatefulWidget {
  @override
  _VaultScreenState createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  late DatabaseHelper _dbHelper;
  List<Map<String, dynamic>> _records = [];
  final _storage = FlutterSecureStorage();
  final _encryptionKeyKey = 'encryptionKey';
  final _ivKey = 'iv';

  @override
  void initState() {
    super.initState();
    _dbHelper = DatabaseHelper();
    _loadRecords();
    _generateAndStoreKeysIfNeeded();
  }
  void reloadRecords() {
    _loadRecords();
  }
  Future<void> _generateAndStoreKeysIfNeeded() async {
    final keyBase64 = await _storage.read(key: _encryptionKeyKey);
    final ivBase64 = await _storage.read(key: _ivKey);
    if (keyBase64 == null || ivBase64 == null) {
      final key = encrypt.Key.fromSecureRandom(16);
      final iv = encrypt.IV.fromSecureRandom(16);
      await _storage.write(key: _encryptionKeyKey, value: key.base64);
      await _storage.write(key: _ivKey, value: iv.base64);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Color(0xFF2A0343),
          title: Text(
            'Vault',
            style: TextStyle(color: Colors.white),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          bottom: TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.add, color: Color(0xFF69F0AE)),
                child: Text(
                  'Add',
                  style: TextStyle(color: Color(0xFF69F0AE)),
                ),
              ),
              Tab(
                icon: Icon(Icons.remove_red_eye, color: Color(0xFF69F0AE)),
                child: Text(
                  'View',
                  style: TextStyle(color: Color(0xFF69F0AE)),
                ),
              ),
              Tab(
                icon: Icon(Icons.delete, color: Color(0xFF69F0AE)),
                child: Text(
                  'Remove',
                  style: TextStyle(color: Color(0xFF69F0AE)),
                ),
              ),
              Tab(
                icon: Icon(Icons.list, color: Color(0xFF69F0AE)),
                child: Text(
                  'Record',
                  style: TextStyle(color: Color(0xFF69F0AE)),
                ),
              ),
            ],
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF2A0343), Color(0xFF01162A)],
            ),
          ),
          child: TabBarView(
            children: [
              AddSection(records: _records, updateRecords: _updateRecords),
              ViewSection(records: _records),
              RemoveSection(records: _records, updateRecords: _updateRecords),
              RecordSection(
                records: _records,
                storage: _storage, // Pass the FlutterSecureStorage instance
                dbHelper: _dbHelper,
                reloadRecords: reloadRecords,// Pass the DatabaseHelper instance
              ),

            ],
          ),
        ),
      ),
    );
  }

  void _updateRecords(Map<String, dynamic> record) async {
    await _dbHelper.insertRecord(record);
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final db = await _dbHelper.database;
    final records = await db.query(DatabaseHelper._tableName, where: 'deleted = ?', whereArgs: [0]);
    setState(() {
      _records = records.reversed.toList(); // Newest records appear at the top
    });
  }
}

class AddSection extends StatefulWidget {
  final List<Map<String, dynamic>> records;
  final Function updateRecords;

  AddSection({required this.records, required this.updateRecords});

  @override
  _AddSectionState createState() => _AddSectionState();
}

class _AddSectionState extends State<AddSection> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final _storage = FlutterSecureStorage();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: _addFilesToVault,
            icon: Icon(Icons.add),
            label: Text('Add Files'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Color(0xFF00ADB5),
            ),
          ),
          SizedBox(height: 20.0),
          Expanded(
            child: ListView.builder(
              itemCount: widget.records.length,
              itemBuilder: (context, index) {
                final record = widget.records[index];
                if (record['deleted'] == 1) {
                  // Skip rendering the item if it's marked as deleted
                  return SizedBox.shrink();
                }
                return ListTile(
                  title: Text(
                    record['originalName'],
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    record['timestamp'],
                    style: TextStyle(color: Colors.white),
                  ),
                  trailing: Text(
                    record['encryptedFileName'],
                    style: TextStyle(color: Colors.white),
                  ),
                );
              },
            ),

          ),
        ],
      ),
    );
  }

  Future<void> _addFilesToVault() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
    );

    if (result != null) {
      List<PlatformFile> files = result.files;
      final downloadPath = await _storage.read(key: 'downloadPath');

      final key = await _getEncryptionKey();
      final iv = await _getIV();
      final encrypter = encrypt.Encrypter(encrypt.AES(key));

      for (var file in files) {
        File pickedFile = File(file.path!);
        String timestamp = DateTime.now().toString();
        String encryptedFileName = '${DateTime.now().millisecondsSinceEpoch}.encrypted';

        // Read file as bytes
        List<int> fileBytes = pickedFile.readAsBytesSync();

        // Encrypt file data
        final encryptedData = encrypter.encryptBytes(fileBytes, iv: iv);

        // Create vault folder if not exists
        Directory vaultDirectory = Directory('$downloadPath/vault');
        if (!await vaultDirectory.exists()) {
          await vaultDirectory.create(recursive: true);
        }

        final encryptedFile = File('$downloadPath/vault/$encryptedFileName');
        await encryptedFile.writeAsBytes(encryptedData.bytes);

        // Add record
        await widget.updateRecords({
          'timestamp': timestamp,
          'fileType': file.extension,
          'originalName': file.name,
          'location': encryptedFile.path,
          'encryptedFileName': encryptedFileName,
        });
      }
    }
  }

  Future<encrypt.Key> _getEncryptionKey() async {
    final keyBase64 = await _storage.read(key: 'encryptionKey');
    print(keyBase64);
    return encrypt.Key.fromBase64(keyBase64!);
  }

  Future<encrypt.IV> _getIV() async {
    final ivBase64 = await _storage.read(key: 'iv');
    return encrypt.IV.fromBase64(ivBase64!);
  }
}

class ViewSection extends StatelessWidget {
  final List<Map<String, dynamic>> records;

  ViewSection({required this.records});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      child: ListView.builder(
        itemCount: records.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(
              records[index]['originalName'],
              style: TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              records[index]['fileType'],
              style: TextStyle(color: Colors.white),
            ),
          );
        },
      ),
    );
  }
}

class RemoveSection extends StatefulWidget {
  final List<Map<String, dynamic>> records; // Pass a copy
  final Function updateRecords;

  RemoveSection({required this.records, required this.updateRecords});

  @override
  _RemoveSectionState createState() => _RemoveSectionState();
}

class _RemoveSectionState extends State<RemoveSection> {
  late List<Map<String, dynamic>> _recordsCopy; // Define a copy
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<bool> _selectedFiles = [];
  final _storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _recordsCopy = List.from(widget.records); // Initialize the copy
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: () {
              _selectedFiles.asMap().forEach((index, isSelected) {
                if (isSelected) {
                  _removeFile(index);
                }
              });
            },
            icon: Icon(Icons.delete),
            label: Text('Remove Selected Files'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white, backgroundColor: Color(0xFF00ADB5),
            ),
          ),
          SizedBox(height: 20.0),
          Expanded(
            child: ListView.builder(
              itemCount: _recordsCopy.length, // Use the copy here
              itemBuilder: (context, index) {
                _selectedFiles.add(false);
                return CheckboxListTile(
                  title: Text(
                    _recordsCopy[index]['originalName'], // Use the copy here
                    style: TextStyle(color: Colors.white),
                  ),
                  value: _selectedFiles[index],
                  onChanged: (isSelected) {
                    setState(() {
                      _selectedFiles[index] = isSelected!;
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _removeFile(int index) async {
    final record = widget.records[index];

    // Decrypt the file and move it to the download path
    final downloadPath = await _storage.read(key: 'downloadPath');
    final encryptedFilePath = '$downloadPath/vault/${record['encryptedFileName']}';
    final decryptedFilePath = '$downloadPath/${record['originalName']}';

    // Retrieve the encryption key and IV from storage
    final keyBase64 = await _storage.read(key: 'encryptionKey');
    final ivBase64 = await _storage.read(key: 'iv');

    // Convert the base64 strings to Key and IV objects
    final key = encrypt.Key.fromBase64(keyBase64!);
    final iv = encrypt.IV.fromBase64(ivBase64!);

    // Create an Encrypter instance with the key
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    // Read encrypted file bytes
    final encryptedFileBytes = await File(encryptedFilePath).readAsBytes();

    // Decrypt file bytes
    final decryptedFileBytes = encrypter.decryptBytes(
      encrypt.Encrypted(encryptedFileBytes),
      iv: iv,
    );

    // Write decrypted bytes to the download path
    await File(decryptedFilePath).writeAsBytes(decryptedFileBytes);

    // Delete the encrypted file
    await File(encryptedFilePath).delete();

    // Delete the record from the database
    await _dbHelper.removeRecord(record['id']);

    // Create a copy of the list
    List<Map<String, dynamic>> updatedRecords = List.from(widget.records);

    // Remove the record from the copied list
    updatedRecords.removeAt(index);

    // Update UI
    setState(() {
      _recordsCopy = updatedRecords; // Update the copy
      _selectedFiles.removeAt(index);
    });
  }


}

class RecordSection extends StatelessWidget {
  final List<Map<String, dynamic>> records;
  final FlutterSecureStorage storage;
  final DatabaseHelper dbHelper;
  final Function reloadRecords; // Callback function to reload records

  RecordSection({
    required this.records,
    required this.storage,
    required this.dbHelper,
    required this.reloadRecords, // Accept the callback function
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            onPressed: () {
              _confirmClearDatabase(context);
            },
            child: Text('Clear Database'),
          ),
          SizedBox(height: 20.0),
          Expanded(
            child: ListView.builder(
              itemCount: records.length,
              itemBuilder: (context, index) {
                final record = records[index];
                return ListTile(
                  title: Text(
                    record['originalName'],
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Timestamp: ${record['timestamp']}',
                        style: TextStyle(color: Colors.white),
                      ),
                      Text(
                        'File Type: ${record['fileType']}',
                        style: TextStyle(color: Colors.white),
                      ),
                      Text(
                        'Location: ${record['location']}',
                        style: TextStyle(color: Colors.white),
                      ),
                      Text(
                        'Encrypted File Name: ${record['encryptedFileName']}',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClearDatabase(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Clear Database'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to clear all records?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Confirm'),
              onPressed: () async {
                await dbHelper.clearDatabase();
                Navigator.of(context).pop();
                // Call the callback function to reload records
                reloadRecords();
              },
            ),
          ],
        );
      },
    );
  }

  Future<bool> _checkEncryptedFileExists(Map<String, dynamic> record) async {
    final downloadPath = await storage.read(key: 'downloadPath');
    final encryptedFilePath =
        '$downloadPath/vault/${record['encryptedFileName']}';
    return File(encryptedFilePath).exists();
  }
}



class DatabaseHelper {
  static Database? _database;
  static final _tableName = 'file_records';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }
  Future<void> clearDatabase() async {
    // Delete database records
    final db = await database;
    await db.delete(_tableName);
    final _storage = FlutterSecureStorage();
    // Delete vault folder
    final downloadPath = await _storage.read(key: 'downloadPath');
    final vaultDirectory = Directory('$downloadPath/vault');
    if (await vaultDirectory.exists()) {
      await vaultDirectory.delete(recursive: true);
    }

  }


  Future<Database> initDatabase() async {
    final path = join(await getDatabasesPath(), 'files.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
        CREATE TABLE $_tableName(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          timestamp TEXT,
          fileType TEXT,
          originalName TEXT,
          location TEXT,
          encryptedFileName TEXT,
          deleted INTEGER DEFAULT 0
        )
      ''');
      },
    );
  }


  Future<int> insertRecord(Map<String, dynamic> record) async {
    final db = await database;
    return await db.insert(_tableName, record);
  }

  Future<List<Map<String, dynamic>>> getRecords() async {
    final db = await database;
    return await db.query(_tableName, where: 'deleted = ?', whereArgs: [0]);
  }

  Future<void> removeRecord(int id) async {
    final db = await database;
    await db.update(_tableName, {'deleted': 1}, where: 'id = ?', whereArgs: [id]);
  }
}
