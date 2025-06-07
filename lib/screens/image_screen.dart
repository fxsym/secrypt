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
  String? base64Image;

  String? _encryptedImage;
  String? _decryptedImage;

  Uint8List _generateKeyFromPassword(String password) {
    return sha256.convert(utf8.encode(password)).bytes as Uint8List;
  }

  void _decryptText() {
    final encryptedBase64 = _encryptedImage;
    final keyInput = _keyController.text;

    if (keyInput.isEmpty ||
        encryptedBase64 == null ||
        !encryptedBase64.contains(":")) {
      setState(() {
        _decryptedImage = "Key dan teks terenkripsi harus diisi!";
      });
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
      });
    } catch (e) {
      setState(() {
        _decryptedImage = "Gagal dekripsi: key salah atau data rusak.";
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
    final formatter = DateFormat('MMMM d, y \'at\' h:mm:ss a zzz');
    return formatter.format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Detail Teks Terenkripsi")),
      body: FutureBuilder<DocumentSnapshot>(
        future: _textData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('Data tidak ditemukan.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          _encryptedImage = data['encrypt_image'];

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Judul:", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(data['image_title'] ?? '-'),
                  SizedBox(height: 10),
                  Text(
                    "Encrypt Image:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  _decryptedImage != null
                      ? Column(
                        children: [
                          Text(
                            "Gambar berhasil di dekripsi",
                            style: TextStyle(color: Colors.green),
                          ),
                          Image.memory(
                            base64Decode(_decryptedImage!),
                            fit: BoxFit.cover,
                          ),
                        ],
                      )
                      : Icon(Icons.image, size: 80, color: Colors.grey[600]),
                  SizedBox(height: 10),
                  Text(
                    "Timestamp:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    data['timestamp'] != null
                        ? formatTimestamp(data['timestamp'])
                        : '-',
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Masukkan key untuk dekripsi data",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextField(
                    controller: _keyController,
                    decoration: InputDecoration(
                      labelText: 'Key (bebas panjang)',
                    ),
                    obscureText: true,
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _decryptText,
                    child: Text('Dekripsi'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
