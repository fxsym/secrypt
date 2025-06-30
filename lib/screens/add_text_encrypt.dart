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
  final TextEditingController _titleController = TextEditingController();

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
        await firestore.collection('texts').add({
          'user_id': user.uid,
          'text_title': _titleController.text,
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
      appBar: AppBar(
        title: Text('Enkripsi Teks'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Masukkan Informasi",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Judul Teks Enkripsi',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _textController,
              decoration: InputDecoration(
                labelText: 'Teks Asli',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              minLines: 5,
              maxLines: null,
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _keyController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Kunci Enkripsi',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                icon: Icon(Icons.lock),
                onPressed: _isLoading ? null : _encryptText,
                label: _isLoading
                    ? CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : Text('Enkripsi & Simpan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_encryptedText != null) ...[
              Text(
                'Hasil Enkripsi:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  _encryptedText!,
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
