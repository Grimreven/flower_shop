import 'package:flutter/material.dart';

class EditProductScreen extends StatelessWidget {
  const EditProductScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Админ панель'),
      ),
      body: const Center(
        child: Text(
          'Ты в админке 🔥',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}