import 'package:flutter/material.dart';
import 'screens/signup_screen/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://soahzqyhefhnshpthtip.supabase.co',
    anonKey: 'sb_publishable_sx83IZ7f1p-cF1XsQISRqQ_Vn6EK7El',
  );
  runApp(const CareMeApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: LoginScreen());
  }
}
