import 'package:flutter/material.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddImageEncryptScreen extends StatefulWidget {
  @override
  _AddImageEncryptScreenState createState() => _AddImageEncryptScreenState();
}

class _AddImageEncryptScreenState extends State<AddImageEncryptScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _keyController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  String? base64Image;

  final picker = ImagePicker();

  String? _encryptedImage;
  bool _isLoading = false;

  Uint8List _generateKeyFromPassword(String password) {
    return sha256.convert(utf8.encode(password)).bytes as Uint8List;
  }

  Future<void> pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final file = File(picked.path);
      final fileSize = await file.length();

      if (fileSize > 2 * 1024 * 1024) {
        // Jika lebih dari 2MB
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ukuran gambar maksimal 2MB')));
        return;
      }

      final bytes = await file.readAsBytes();
      setState(() {
        base64Image = base64Encode(bytes);
      });
    }
  }

  Future<void> _encryptText() async {
    final plainText = base64Image;
    final keyInput = _keyController.text;

    if (keyInput.isEmpty || plainText!.isEmpty) {
      setState(() {
        _encryptedImage = "Gambar dan Key harus diisi!";
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
        await firestore.collection('images').add({
          'user_id': user.uid,
          'image_title': _titleController.text,
          'key_bytes': base64Encode(keyBytes),
          'encrypt_image': combined,
          'timestamp': FieldValue.serverTimestamp(),
        });

        setState(() {
          _encryptedImage = combined;
        });
      } else {
        setState(() {
          _encryptedImage = "User belum login!";
        });
      }
    } catch (e) {
      setState(() {
        _encryptedImage = "Terjadi kesalahan saat enkripsi.";
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
      appBar: AppBar(title: Text('Enkripsi Gambar')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Judul teks enkripsi'),
            ),
            SizedBox(height: 20),
            Column(
              children: [
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey),
                  ),
                  child:
                      base64Image != null
                          ? Image.memory(
                            base64Decode(base64Image!),
                            fit: BoxFit.cover,
                          )
                          : Icon(
                            Icons.image,
                            size: 80,
                            color: Colors.grey[600],
                          ),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: pickImage,
                  child: Text(
                    base64Image == null ? "Pilih Gambar" : "Ganti Gambar",
                  ),
                ),
              ],
            ),
            TextField(
              controller: _keyController,
              decoration: InputDecoration(labelText: 'Key (bebas panjang)'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _encryptText,
              child:
                  _isLoading
                      ? CircularProgressIndicator()
                      : Text('Enkripsi dan Simpan'),
            ),
            SizedBox(height: 20),
            if (_encryptedImage != null) ...[
              Text(
                'Hasil Enkripsi:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SelectableText(_encryptedImage!),
            ],
          ],
        ),
      ),
    );
  }
}
