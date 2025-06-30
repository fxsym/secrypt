import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:typed_data';

class ImageDetailScreen extends StatefulWidget {
  final String docId;

  const ImageDetailScreen({Key? key, required this.docId}) : super(key: key);

  @override
  _ImageDetailScreenState createState() => _ImageDetailScreenState();
}

class _ImageDetailScreenState extends State<ImageDetailScreen> {
  late Future<DocumentSnapshot> _textData;
  final TextEditingController _keyController = TextEditingController();
  String? _encryptedImage;
  String? _decryptedImage;
  bool _isDecryptionError = false;

  Uint8List _generateKeyFromPassword(String password) {
    return sha256.convert(utf8.encode(password)).bytes as Uint8List;
  }

  void _decryptText() {
    final encryptedBase64 = _encryptedImage;
    final keyInput = _keyController.text;

    if (keyInput.isEmpty ||
        encryptedBase64 == null ||
        !encryptedBase64.contains(":")) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Key dan teks terenkripsi harus diisi!")),
      );
      return;
    }

    try {
      final keyBytes = _generateKeyFromPassword(keyInput);
      final key = encrypt.Key(keyBytes);

      final parts = encryptedBase64.split(":");
      final iv = encrypt.IV.fromBase64(parts[0]);
      final encrypted = encrypt.Encrypted.fromBase64(parts[1]);

      final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.cbc),
      );
      final decrypted = encrypter.decrypt(encrypted, iv: iv);

      setState(() {
        _decryptedImage = decrypted;
        _isDecryptionError = false;
      });
    } catch (e) {
      setState(() {
        _decryptedImage = "Gagal dekripsi: key salah atau data rusak.";
        _isDecryptionError = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _textData =
        FirebaseFirestore.instance.collection('images').doc(widget.docId).get();
  }

  String formatTimestamp(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    final formatter = DateFormat('dd MMM yyyy, HH:mm');
    return formatter.format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Detail Gambar Terenkripsi"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _textData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Data tidak ditemukan.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          _encryptedImage = data['encrypt_image'];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Judul",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(data['image_title'] ?? '-'),
                const SizedBox(height: 16),

                Text(
                  "Gambar Terenkripsi",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
                const SizedBox(height: 8),

                if (_decryptedImage != null && !_isDecryptionError)
                  Column(
                    children: [
                      const Text(
                        "Gambar berhasil di dekripsi",
                        style: TextStyle(color: Colors.green),
                      ),
                      const SizedBox(height: 8),
                      Image.memory(
                        base64Decode(_decryptedImage!),
                        fit: BoxFit.cover,
                      ),
                    ],
                  )
                else if (_isDecryptionError)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _decryptedImage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  Icon(Icons.image, size: 80, color: Colors.grey[600]),

                const SizedBox(height: 20),
                Text(
                  "Waktu Enkripsi",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data['timestamp'] != null
                      ? formatTimestamp(data['timestamp'])
                      : '-',
                ),
                const SizedBox(height: 24),

                Text(
                  "Masukkan Key untuk Dekripsi",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _keyController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Key Enkripsi',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.lock_open),
                    onPressed: _decryptText,
                    label: const Text("Dekripsi Gambar"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
