import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Дээд талын хэсэг (AppBar)
      appBar: AppBar(
        title: const Text('Home Page'),
        backgroundColor: Colors.blue, // Өнгийг нь өөрчилж болно
      ),
      // Гол цагаан хэсэг
      body: Container(
        color: Colors.white,
        child: const Center(
          child: Text(
            'Та амжилттай нэвтэрлээ!',
            style: TextStyle(fontSize: 20, color: Colors.grey),
          ),
        ),
      ),
    );
  }
}
