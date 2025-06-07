import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert'; // untuk base64
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  String gender = 'Male';
  String? base64Image;

  final picker = ImagePicker();

  Future<void> pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await File(picked.path).readAsBytes();
      setState(() {
        base64Image = base64Encode(bytes);
      });
    }
  }

  void register() async {
    try {
      final authResult = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailCtrl.text.trim(),
            password: passCtrl.text.trim(),
          );

      final uid = authResult.user!.uid;

      await FirebaseFirestore.instance.collection('users').add({
        'full_name': nameCtrl.text.trim(),
        'gender': gender,
        'phone_number': phoneCtrl.text.trim(),
        'profile_picture': base64Image ?? '',
        'timestamp': FieldValue.serverTimestamp(),
      });

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Registrasi gagal: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Register")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey[300],
              backgroundImage:
                  base64Image != null
                      ? MemoryImage(base64Decode(base64Image!))
                      : null,
              child:
                  base64Image == null
                      ? Icon(Icons.person, size: 60, color: Colors.white)
                      : null,
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: pickImage,
              child: Text(base64Image == null ? "Pilih Foto" : "Ganti Foto"),
            ),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(labelText: "Full Name"),
            ),
            TextField(
              controller: phoneCtrl,
              decoration: InputDecoration(labelText: "Phone Number"),
            ),
            DropdownButtonFormField(
              value: gender,
              onChanged: (value) => setState(() => gender = value!),
              items:
                  ['Male', 'Female']
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
              decoration: InputDecoration(labelText: "Gender"),
            ),
            TextField(
              controller: emailCtrl,
              decoration: InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: passCtrl,
              obscureText: true,
              decoration: InputDecoration(labelText: "Password"),
            ),
            SizedBox(height: 10),
            SizedBox(height: 20),
            ElevatedButton(onPressed: register, child: Text("Register")),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
              child: Text("Login"),
            ),
          ],
        ),
      ),
    );
  }
}
