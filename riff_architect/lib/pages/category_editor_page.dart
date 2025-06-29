import 'package:flutter/material.dart';

class CategoryEditorPage extends StatelessWidget {
  const CategoryEditorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Edit Categories'),
        backgroundColor: Colors.grey[900],
      ),
      body: const Center(
        child: Text(
          'Category editor coming soon...',
          style: TextStyle(color: Colors.white54),
        ),
      ),
    );
  }
}
