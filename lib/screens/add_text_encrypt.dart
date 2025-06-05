import 'package:flutter/material.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddTextEncryptScreen extends StatefulWidget {
  @override
  _AddTextEncryptScreenState createState() => _AddTextEncryptScreenState();
}

class _AddTextEncryptScreenState extends State<AddTextEncryptScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _keyController = TextEditingController();

  String? _encryptedText;
  bool _isLoading = false;

  Uint8List _generateKeyFromPassword(String password) {
    return sha256.convert(utf8.encode(password)).bytes as Uint8List;
  }

  Future<void> _encryptText() async {
    final plainText = _textController.text;
    final keyInput = _keyController.text;

    if (keyInput.isEmpty || plainText.isEmpty) {
      setState(() {
        _encryptedText = "Teks dan Key harus diisi!";
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final keyBytes = _generateKeyFromPassword(keyInput);
      final key = encrypt.Key(keyBytes);
      final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.cbc),
      );

      final iv = encrypt.IV.fromSecureRandom(16);
      final encrypted = encrypter.encrypt(plainText, iv: iv);
      final combined = iv.base64 + ":" + encrypted.base64;

      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        final firestore = FirebaseFirestore.instance;
        await firestore.collection('texts').doc(user.uid).set({
          'user_id': user.uid,
          'key_bytes': base64Encode(keyBytes),
          'encrypt_text': combined,
          'timestamp': FieldValue.serverTimestamp(),
        });

        setState(() {
          _encryptedText = combined;
        });
      } else {
        setState(() {
          _encryptedText = "User belum login!";
        });
      }
    } catch (e) {
      setState(() {
        _encryptedText = "Terjadi kesalahan saat enkripsi.";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Enkripsi Teks')),
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
            ElevatedButton(
              onPressed: _isLoading ? null : _encryptText,
              child: _isLoading
                  ? CircularProgressIndicator()
                  : Text('Enkripsi dan Simpan'),
            ),
            SizedBox(height: 20),
            if (_encryptedText != null) ...[
              Text(
                'Hasil Enkripsi:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SelectableText(_encryptedText!),
            ],
          ],
        ),
      ),
    );
  }
}
