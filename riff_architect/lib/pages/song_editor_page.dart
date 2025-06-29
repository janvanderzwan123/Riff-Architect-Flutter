import 'package:flutter/material.dart';

class SongEditorPage extends StatelessWidget {
  const SongEditorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Edit Songs'),
        backgroundColor: Colors.grey[900],
      ),
      body: const Center(
        child: Text(
          'Song builder coming soon...',
          style: TextStyle(color: Colors.white54),
        ),
      ),
    );
  }
}
