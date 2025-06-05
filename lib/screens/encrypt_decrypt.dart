import 'package:flutter/material.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:typed_data';

class AddTextEncryptScreen extends StatefulWidget {
  @override
  _AddTextEncryptScreenState createState() => _AddTextEncryptScreenState();
}

class _AddTextEncryptScreenState extends State<AddTextEncryptScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _keyController = TextEditingController();

  String? _encryptedText;
  String? _decryptedText;

  Uint8List _generateKeyFromPassword(String password) {
    // Hash password dengan SHA-256 -> hasil 32 byte (AES-256)
    return sha256.convert(utf8.encode(password)).bytes as Uint8List;
  }

  void _encryptText() {
    final plainText = _textController.text;
    final keyInput = _keyController.text;

    if (keyInput.isEmpty || plainText.isEmpty) {
      setState(() {
        _encryptedText = "Teks dan Key harus diisi!";
        _decryptedText = null;
      });
      return;
    }

    final keyBytes = _generateKeyFromPassword(keyInput);
    final key = encrypt.Key(keyBytes);

    final encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.cbc),
    );

    final iv = encrypt.IV.fromSecureRandom(16); // IV random
    final encrypted = encrypter.encrypt(plainText, iv: iv);

    // Gabungkan iv + encrypted data (base64)
    final combined = iv.base64 + ":" + encrypted.base64;

    setState(() {
      _encryptedText = combined;
      _decryptedText = null;
    });
  }

  void _decryptText() {
    final encryptedBase64 = _encryptedText;
    final keyInput = _keyController.text;

    if (keyInput.isEmpty ||
        encryptedBase64 == null ||
        !encryptedBase64.contains(":")) {
      setState(() {
        _decryptedText = "Key dan teks terenkripsi harus diisi!";
      });
      return;
    }

    try {
      final keyBytes = _generateKeyFromPassword(keyInput);
      final key = encrypt.Key(keyBytes);

      // Pisahkan IV dan data terenkripsi
      final parts = encryptedBase64.split(":");
      final iv = encrypt.IV.fromBase64(parts[0]);
      final encrypted = encrypt.Encrypted.fromBase64(parts[1]);

      final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.cbc),
      );
      final decrypted = encrypter.decrypt(encrypted, iv: iv);

      setState(() {
        _decryptedText = decrypted;
      });
    } catch (e) {
      setState(() {
        _decryptedText = "Gagal dekripsi: key salah atau data rusak.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Enkripsi & Dekripsi Teks')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _textController,
              decoration: InputDecoration(labelText: 'Teks asli'),
            ),
            TextField(
              controller: _keyController,
              decoration: InputDecoration(labelText: 'Key (bebas panjang)'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _encryptText,
                    child: Text('Enkripsi'),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _decryptText,
                    child: Text('Dekripsi'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            if (_encryptedText != null) ...[
              Text(
                'Hasil Enkripsi:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SelectableText(_encryptedText!),
            ],
            SizedBox(height: 20),
            if (_decryptedText != null) ...[
              Text(
                'Hasil Dekripsi:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SelectableText(_decryptedText!),
            ],
          ],
        ),
      ),
    );
  }
}
