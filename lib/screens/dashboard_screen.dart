import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  String? fullName;
  String? base64Image;
  String? uid;
  bool showOptions = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    loadUserData();
  }

  Future<void> _deleteImage(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Konfirmasi'),
            content: const Text(
              'Apakah Anda yakin ingin menghapus gambar ini?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Hapus', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('images')
            .doc(docId)
            .delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gambar berhasil dihapus')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Terjadi kesalahan saat menghapus gambar'),
          ),
        );
      }
    }
  }

  Future<void> _deleteText(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Konfirmasi'),
            content: const Text(
              'Apakah Anda yakin ingin menghapus text ini?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Hapus', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('texts')
            .doc(docId)
            .delete();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Text berhasil dihapus')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Terjadi kesalahan saat menghapus text'),
          ),
        );
      }
    }
  }

  Future<void> loadUserData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final userId = currentUser.uid;
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          uid = userId; // Set UID hanya jika user ada
          fullName = data['full_name'] ?? '';
          base64Image = data['profile_picture'] ?? '';
        });
      }
    }
  }

  String formatTimestamp(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    final formatter = DateFormat('dd MMM yyyy, HH:mm');
    return formatter.format(dateTime);
  }

  Widget buildTextList() {
    if (uid == null) {
      return Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('texts')
              .where('user_id', isEqualTo: uid)
              .orderBy('timestamp', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Terjadi kesalahan.'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Center(child: Text('Belum ada data teks terenkripsi.'));
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final docId = docs[index].id;

            return ListTile(
              title: Text(data['text_title'] ?? 'Tanpa Judul'),
              subtitle: Text(formatTimestamp(data['timestamp'])),
              onTap: () {
                Navigator.pushNamed(context, '/texts/$docId');
              },
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed:
                    () => _deleteText(docId), // ganti dengan fungsi penghapusmu
              ),
            );
          },
        );
      },
    );
  }

  Widget buildImageList() {
    if (uid == null) {
      return Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('images')
              .where('user_id', isEqualTo: uid)
              .orderBy('timestamp', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Terjadi kesalahan.'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Center(child: Text('Belum ada data gambar terenkripsi.'));
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final docId = docs[index].id;

            return ListTile(
              title: Text(data['image_title'] ?? 'Tanpa Judul'),
              subtitle: Text(formatTimestamp(data['timestamp'])),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/images/$docId',
                  arguments: {'docId': docId},
                );
              },
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed:
                    () => _deleteImage(
                      docId,
                    ), // pastikan _deleteOrder menerima docId
              ),
            );
          },
        );
      },
    );
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
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Text Terenkripsi'),
            Tab(text: 'Gambar Terenkripsi'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [buildTextList(), buildImageList()],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
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
