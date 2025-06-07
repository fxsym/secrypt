import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:secrypt/screens/add_image_ecrypt.dart';
import 'package:secrypt/screens/add_text_encrypt.dart';
import 'package:secrypt/screens/dashboard_screen.dart';
import 'package:secrypt/screens/register_screen.dart';
import 'package:secrypt/screens/text_screen.dart';
import 'package:secrypt/screens/image_screen.dart';
import 'package:secrypt/screens/login_screen.dart';
import 'package:secrypt/screens/home_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Encrypt App',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      initialRoute: '/login',
      routes: {
        '/login': (_) => LoginScreen(),
        '/home': (_) => HomeScreen(),
        '/register': (_) => RegisterScreen(),
        '/dashboard': (_) => DashboardScreen(),
        '/add-text-encrypt': (_) => AddTextEncryptScreen(),
        '/add-image-encrypt': (_) => AddImageEncryptScreen(),
      },
      onGenerateRoute: (settings) {
        final uri = Uri.parse(settings.name!);

        // Route untuk detail teks terenkripsi
        if (uri.pathSegments.length == 2 && uri.pathSegments[0] == 'texts') {
          final docId = uri.pathSegments[1];
          return MaterialPageRoute(
            builder: (_) => TextDetailScreen(docId: docId),
          );
        }

        // Route untuk detail gambar terenkripsi
        if (uri.pathSegments.length == 2 && uri.pathSegments[0] == 'images') {
          final docId = uri.pathSegments[1];
          return MaterialPageRoute(
            builder: (_) => ImageDetailScreen(docId: docId),
          );
        }

        // Jika route tidak ditemukan
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('Route tidak ditemukan')),
          ),
        );
      },
    );
  }
}
