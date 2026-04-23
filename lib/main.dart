import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'login.dart';

void main() async {
  // Flutter-ийн суурь тохиргоог баталгаажуулах
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase-ийг эхлүүлэхfl (Өөрийн URL болон Key-г энд оруулна)
  await Supabase.initialize(
    url: 'https://zjabynsrpuxzxoozlrca.supabase.co',
    anonKey: 'sb_publishable_3OMOwb-s99wL3SDjior3kg_LA4NqkV6',
  );

  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => const MyApp(),
    ),
  );
}

// Supabase Client-ийг глобал байдлаар тодорхойлох
final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Баруун дээд талын туузыг арилгах
      title: 'Hospital App',
      locale:
          DevicePreview.locale(context), // DevicePreview-ийн хэлний тохиргоо
      builder: DevicePreview.appBuilder, // DevicePreview-тэй холбох
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(), // Үндсэн нүүр хуудас
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Дэлгэцийн бүх талбайг дүүргэх
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          // Градиент дэвсгэр өнгө
          gradient: LinearGradient(
            colors: [
              Color(0xFF2196F3), // Цэнхэр
              Color(0xFF21CBF3), // Цайвар цэнхэр
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Hospital App-д тавтай морил',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue[900],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Орох',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
