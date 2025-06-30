import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:typed_data';

class TextDetailScreen extends StatefulWidget {
  final String docId;

  const TextDetailScreen({Key? key, required this.docId}) : super(key: key);

  @override
  _TextDetailScreenState createState() => _TextDetailScreenState();
}

class _TextDetailScreenState extends State<TextDetailScreen> {
  late Future<DocumentSnapshot> _textData;
  final TextEditingController _keyController = TextEditingController();

  String? _encryptedText;
  String? _decryptedText;

  Uint8List _generateKeyFromPassword(String password) {
    return sha256.convert(utf8.encode(password)).bytes as Uint8List;
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
  void initState() {
    super.initState();
    _textData =
        FirebaseFirestore.instance.collection('texts').doc(widget.docId).get();
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
        title: Text("Detail Teks Terenkripsi"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
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
          _encryptedText = data['encrypt_text'];

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
                SizedBox(height: 4),
                Text(data['text_title'] ?? '-'),
                SizedBox(height: 16),

                Text(
                  "Teks Terenkripsi",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
                SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(_encryptedText ?? '-'),
                ),
                SizedBox(height: 16),

                Text(
                  "Waktu Enkripsi",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  data['timestamp'] != null
                      ? formatTimestamp(data['timestamp'])
                      : '-',
                ),
                SizedBox(height: 24),

                Text(
                  "Masukkan Key untuk Dekripsi",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: _keyController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Key Enkripsi',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),

                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.lock_open),
                    onPressed: _decryptText,
                    label: Text("Dekripsi"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24),

                if (_decryptedText != null) ...[
                  Text(
                    'Hasil Dekripsi',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(_decryptedText!),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
