import 'package:flutter/material.dart';
import 'package:riff_architect/db/riff_dao.dart';
import 'package:riff_architect/models/riff.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:riff_architect/pages/riff_editor_page.dart';
import 'package:riff_architect/pages/category_editor_page.dart';
import 'package:riff_architect/pages/song_editor_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<Riff> riffs = [];
  final AudioPlayer player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    loadRiffs();
  }

  Future<void> loadRiffs() async {
    final data = await RiffDao.getAllRiffs();
    setState(() => riffs = data);
  }

  Future<void> deleteRiff(int id) async {
    await RiffDao.deleteRiff(id);
    loadRiffs();
  }

  Widget buildPanelTitle(String title, VoidCallback onCreate) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        TextButton.icon(
          onPressed: onCreate,
          icon: const Icon(Icons.add, color: Colors.white70, size: 18),
          label: const Text('Create', style: TextStyle(color: Colors.white70)),
          style: TextButton.styleFrom(
            backgroundColor: Colors.grey[850],
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),
        )
      ],
    );
  }

  DataTable buildRiffsTable() {
    return DataTable(
      headingRowColor: MaterialStateColor.resolveWith((states) => Colors.grey.shade800),
      columnSpacing: 12,
      columns: const [
        DataColumn(label: Text('Name', style: TextStyle(color: Colors.white70))),
        DataColumn(label: Text('Category', style: TextStyle(color: Colors.white70))),
        DataColumn(label: Text('Path', style: TextStyle(color: Colors.white70))),
        DataColumn(label: Text('Actions', style: TextStyle(color: Colors.white70))),
      ],
      rows: riffs.map((riff) => DataRow(cells: [
        DataCell(Text(riff.name, style: const TextStyle(color: Colors.white))),
        DataCell(Text(riff.category, style: const TextStyle(color: Colors.white))),
        DataCell(Text(riff.filePath, style: const TextStyle(color: Colors.white), overflow: TextOverflow.ellipsis)),
        DataCell(Row(
          children: [
            IconButton(
              icon: const Icon(Icons.play_arrow, color: Colors.lightBlueAccent),
              onPressed: () => player.play(DeviceFileSource(riff.filePath)),
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.orangeAccent),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RiffEditorPage(existingRiff: riff))
                );
                loadRiffs();
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () => deleteRiff(riff.id!),
            )
          ],
        ))
      ])).toList(),
    );
  }

  Widget buildPanel(String title, VoidCallback onCreate, Widget content) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildPanelTitle(title, onCreate),
            const SizedBox(height: 12),
            Expanded(child: SingleChildScrollView(child: content))
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Riff Architect Dashboard'),
        backgroundColor: Colors.grey[900],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildPanel('Riffs', () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RiffEditorPage())
            );
            loadRiffs();
          }, buildRiffsTable()),
          buildPanel('Categories', () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CategoryEditorPage())
            );
          }, const Text('(Coming soon)', style: TextStyle(color: Colors.white54))),
          buildPanel('Songs', () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SongEditorPage())
            );
          }, const Text('(Coming soon)', style: TextStyle(color: Colors.white54))),
        ],
      ),
    );
  }
}