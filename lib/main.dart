import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:secrypt/screens/add_image_ecrypt.dart';
import 'package:secrypt/screens/add_text_encrypt.dart';
import 'package:secrypt/screens/dashboard_screen.dart';
import 'package:secrypt/screens/register_screen.dart';
import 'package:secrypt/screens/text_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'firebase_options.dart'; // harus di-import

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
        if (settings.name != null && settings.name!.startsWith('/texts/')) {
          final docId = settings.name!.replaceFirst('/texts/', '');
          return MaterialPageRoute(
            builder: (_) => TextDetailScreen(docId: docId),
          );
        }

        return null; // fallback jika route tidak ditemukan
      },
    );
  }
}
