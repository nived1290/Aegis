import 'package:flutter/material.dart';
import 'package:encrypt/encrypt.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:encrypt/encrypt_io.dart';
import 'dart:io';
import 'package:flutter/services.dart';

class CryptoScreen extends StatefulWidget {
  @override
  _CryptoScreenState createState() =>
      _CryptoScreenState();
}

class _CryptoScreenState extends State<CryptoScreen> {
  File? _selectedFile;
  String _encryptedText = '';
  RSAPublicKey? _publicKey;
  RSAPrivateKey? _privateKey;
  final TextEditingController _textController = TextEditingController();
  final _storage = FlutterSecureStorage();
  bool _isSelectingPublicKey = true;
  bool _isSelectingText = true; // Set default text selection to true
  bool _isEncryptMode = true;

  @override
  void initState() {
    super.initState();
    _retrievePublicKey();
    _retrievePrivateKey();
    // Set default selections
    _isSelectingPublicKey = true; // For encryption mode
    _isSelectingText = true; // For both encryption and decryption mode
  }

  Future<void> _retrievePublicKey() async {
    final publicKey = await _storage.read(key: 'public_key.pem');
    if (publicKey != null) {
      try {
        _publicKey = RSAKeyParser().parse(publicKey) as RSAPublicKey;
        setState(() {
          _isSelectingPublicKey = false;
        });
      } catch (e) {
        print('Error parsing public key: $e');
      }
    }
  }

  Future<void> _retrievePrivateKey() async {
    final privateKey = await _storage.read(key: 'private_key.pem');
    if (privateKey != null) {
      try {
        _privateKey = RSAKeyParser().parse(privateKey) as RSAPrivateKey;
      } catch (e) {
        print('Error parsing private key: $e');
      }
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.any,
    );

    if (result != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _isSelectingText = false;
      });
    }
  }

  Future<void> _pickPublicKey() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.any,
    );

    if (result != null) {
      final filePath = result.files.single.path;
      try {
        _publicKey = await parseKeyFromFile<RSAPublicKey>(filePath!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Public key selected!')),
        );
      } catch (e) {
        print('Error parsing public key: $e');
      }
      setState(() {
        _isSelectingPublicKey = true;
      });
    }
  }

  Future<void> _encryptText() async {
    if (_publicKey == null ||
        (_selectedFile == null && _textController.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Please select a public key and file or enter some text!')),
      );
      return;
    }

    final fileContent =
    _selectedFile != null ? await _selectedFile!.readAsString() : '';
    final plainText = _textController.text;
    final dataToEncrypt = plainText.isNotEmpty ? plainText : fileContent;

    final encrypter = Encrypter(
      RSA(
        publicKey: _publicKey!,
        encoding: RSAEncoding.OAEP,
        digest: RSADigest.SHA256,
      ),
    );

    Encrypted encrypted = encrypter.encrypt(dataToEncrypt);
    String encryptedText = encrypted.base64;

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/encrypted_text.txt');
    await file.writeAsString(encryptedText);

    setState(() {
      _encryptedText = encryptedText;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Encryption done successfully!')),
    );
  }

  void _copyText() {
    Clipboard.setData(ClipboardData(text: _encryptedText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Encrypted text copied to clipboard!')),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              _isEncryptMode ? 'Encryption' : 'Decryption',
              style: TextStyle(
                color: Colors.white,
              ),
            ),

            SizedBox(width: 8),
            IconButton(
              onPressed: () {
                setState(() {
                  _isEncryptMode = !_isEncryptMode;
                  _clearText();
                });
              },
              icon: Icon(
                Icons.loop,
                color: Colors.white,
              ),
              tooltip: 'Switch Mode',
            ),
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        backgroundColor: Color(0xFF2A0343),
      ),

      backgroundColor: Color(0xFF2A0343),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isEncryptMode) ...[
                Text(
                  'Public Key',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 20.0),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: _pickPublicKey,
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(
                            _isSelectingPublicKey ? Color(0xFF69F0AE) : Color(0xFF2A0343)
                        ),
                        side: MaterialStateProperty.all(
                            BorderSide(
                              color: _isSelectingPublicKey ? Color(0xFF69F0AE) : Colors.white,
                              width: 1.5, // Adjust the border width as needed
                            )
                        ),
                      ),
                      child: Text(
                        'Select from Storage',
                        style: TextStyle(color: _isSelectingPublicKey ? Colors.white : Color(0xFF69F0AE)),
                      ),
                    ),

                    SizedBox(width: 10.0),
                    ElevatedButton(
                      onPressed: _retrievePublicKey,
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(
                            !_isSelectingPublicKey ? Color(0xFF69F0AE) : Color(0xFF2A0343)
                        ),
                        side: MaterialStateProperty.all(
                            BorderSide(
                              color: !_isSelectingPublicKey ? Color(0xFF69F0AE) : Colors.white,
                              width: 1.5, // Adjust the border width as needed
                            )
                        ),
                      ),
                      child: Text(
                        'Use Own Key',
                        style: TextStyle(color: !_isSelectingPublicKey ? Colors.white : Color(0xFF69F0AE)),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 20.0),
              ],
              Text(
                'Text',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 20.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: _pickFile,
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(
                        !_isSelectingText ? Color(0xFF69F0AE) : Color(0xFF2A0343),
                      ),
                      side: MaterialStateProperty.all(
                        BorderSide(
                          color: !_isSelectingText ? Color(0xFF69F0AE) : Colors.white,
                          width: 1.5, // Adjust the border width as needed
                        ),
                      ),
                    ),
                    child: Text(
                      'Select File',
                      style: TextStyle(color: !_isSelectingText ? Colors.white : Color(0xFF69F0AE)),
                    ),
                  ),
                  SizedBox(width: 10.0),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isSelectingText = !_isSelectingText;
                      });
                    },
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(
                        _isSelectingText ? Color(0xFF69F0AE) : Color(0xFF2A0343),
                      ),
                      side: MaterialStateProperty.all(
                        BorderSide(
                          color: _isSelectingText ? Color(0xFF69F0AE) : Colors.white,
                          width: 1.5, // Adjust the border width as needed
                        ),
                      ),
                    ),
                    child: Text(
                      'Enter Text',
                      style: TextStyle(color: _isSelectingText ? Colors.white : Color(0xFF69F0AE)),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20.0),
              if (_selectedFile != null)
                Text(
                  'Selected File: ${_selectedFile!.path}',
                  style: TextStyle(color: Colors.white),
                ),
              SizedBox(height: 20.0),
              if (_selectedFile == null && _isSelectingText)
                Container(
                  height: 200, // Adjust height as needed
                  child: TextField(
                    controller: _textController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Enter Text',
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                    maxLines: null, // Allow unlimited lines
                    expands: true, // Allow the text field to expand to fill available space
                  ),
                ),
              SizedBox(height: 20.0),
              ElevatedButton(
                onPressed: _isEncryptMode ? _encryptText : _decryptText,
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(
                      Color(0xFF69F0AE)),
                ),
                child: Text(
                  _isEncryptMode ? 'Encrypt' : 'Decrypt',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              SizedBox(height: 20.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: _downloadFile,
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(
                          Color(0xFF69F0AE)),
                    ),
                    child: Text(
                      'Download File',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _copyText,
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(
                          Color(0xFF69F0AE)),
                    ),
                    child: Text(
                      'Copy Text',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  if (_isSelectingText)
                    ElevatedButton(
                      onPressed: _pasteText,
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(
                            Color(0xFF69F0AE)),
                      ),
                      child: Text(
                        'Paste',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 20.0),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _downloadFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final downloadPath = await _storage.read(key: 'downloadPath');

    if (_selectedFile != null || _encryptedText.isNotEmpty) {
      String fileName;

      if (_selectedFile != null) {
        final originalFileName = _selectedFile!.path.split('/').last;
        final extensionIndex = originalFileName.lastIndexOf('.');
        final fileNameWithoutExtension = extensionIndex != -1
            ? originalFileName.substring(0, extensionIndex)
            : originalFileName;

        if (_isEncryptMode) {
          fileName = '$fileNameWithoutExtension' + '_Encrypt';
        } else {
          fileName = '$fileNameWithoutExtension' + '_Decrypt';
        }
      } else {
        final randomFileName = '${DateTime.now().millisecondsSinceEpoch}_';
        fileName = '${_isEncryptMode ? '$randomFileName' : '$_encryptedText'}_${_isEncryptMode ? 'Encrypt' : 'Decrypt'}';
      }

      final filePath = '$downloadPath/$fileName.txt';

      final file = File(filePath);

      if (_selectedFile != null) {
        await file.writeAsString(_encryptedText.isNotEmpty ? _encryptedText : await _selectedFile!.readAsString());
      } else {
        await file.writeAsString(_encryptedText);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Downloading file...')),
      );

      OpenFile.open(filePath);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No file or text to download!')),
      );
    }
  }

  void _decryptText() {
    if (_privateKey == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a private key!')),
      );
      return;
    }

    String textToDecrypt = _selectedFile != null
        ? _selectedFile!.readAsStringSync()
        : _textController.text;

    if (textToDecrypt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No text to decrypt!')),
      );
      return;
    }

    Encrypter decrypter = Encrypter(
      RSA(
        privateKey: _privateKey!,
        encoding: RSAEncoding.OAEP,
        digest: RSADigest.SHA256,
      ),
    );

    Encrypted encryptedData = Encrypted.fromBase64(textToDecrypt);
    String decrypted = decrypter.decrypt(encryptedData);
    setState(() {
      _encryptedText = decrypted;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Decryption successful!'),
      ),
    );
  }

  void _clearText() {
    _selectedFile = null;
    _textController.clear();
    _encryptedText = '';
  }

  void _pasteText() async {
    ClipboardData? clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData != null) {
      setState(() {
        _textController.text = clipboardData.text!;
      });
    }
  }
}
