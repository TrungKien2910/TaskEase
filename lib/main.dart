import 'package:flutter/material.dart';
import 'package:buoi6/manhinh/login_screen.dart';
import 'package:buoi6/manhinh/register_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: "/",
      routes: {
        "/": (context) => const LoginScreen(),
        "/register": (context) => const RegisterScreen(),
      },
    );
  }
}