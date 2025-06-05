import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:secrypt/screens/dashboard_screen.dart';
import 'package:secrypt/screens/register_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'firebase_options.dart'; // harus di-import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // pakai konfigurasi hasil flutterfire
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
      },
    );
  }
}
