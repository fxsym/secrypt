import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? fullName;
  String? base64Image;
  bool showOptions = false;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          fullName = data['full_name'] ?? '';
          base64Image = data['profile_picture'] ?? '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (base64Image != null && base64Image!.isNotEmpty)
              CircleAvatar(
                backgroundImage: MemoryImage(base64Decode(base64Image!)),
              )
            else
              CircleAvatar(child: Icon(Icons.person)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                fullName != null ? "Halo, $fullName" : "Memuat...",
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Center(child: Text("Selamat datang di dashboard")),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end, // rata kanan
        children: [
          AnimatedSwitcher(
            duration: Duration(milliseconds: 300),
            child:
                showOptions
                    ? Column(
                      key: ValueKey(true),
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        FloatingActionButton.extended(
                          heroTag: 'textEncrypt',
                          onPressed: () {
                            Navigator.pushNamed(context, '/add-text-encrypt');
                          },
                          icon: Icon(Icons.text_fields),
                          label: Text("Tambah text enkripsi"),
                        ),
                        SizedBox(height: 10),
                        FloatingActionButton.extended(
                          heroTag: 'imageEncrypt',
                          onPressed: () {
                            Navigator.pushNamed(context, '/add-image-encrypt');
                          },
                          icon: Icon(Icons.image),
                          label: Text("Tambah gambar enkripsi"),
                        ),
                        SizedBox(height: 10),
                      ],
                    )
                    : SizedBox.shrink(key: ValueKey(false)),
          ),
          FloatingActionButton(
            heroTag: 'mainFab',
            onPressed: () {
              setState(() {
                showOptions = !showOptions;
              });
            },
            child: Icon(showOptions ? Icons.close : Icons.add),
          ),
        ],
      ),
    );
  }
}
