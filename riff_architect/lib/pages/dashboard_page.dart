import 'package:flutter/material.dart';
import 'package:riff_architect/db/riff_dao.dart';
import 'package:riff_architect/models/riff.dart';
import 'package:riff_architect/db/category_dao.dart';
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
  List<String> categories = [];
  final AudioPlayer player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final riffData = await RiffDao.getAllRiffs();
    final categoryData = await CategoryDao.getAllCategories();
    setState(() {
      riffs = riffData;
      categories = ['Uncategorized', ...categoryData.where((c) => c != 'Uncategorized')];
    });
  }

  Future<void> deleteRiff(int id) async {
    await RiffDao.deleteRiff(id);
    loadData();
  }

  Widget buildPanelTitle(String title, VoidCallback onCreate) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        TextButton.icon(
          onPressed: onCreate,
          icon: const Icon(Icons.add, size: 18, color: Colors.white70),
          label: const Text('Create', style: TextStyle(color: Colors.white70)),
          style: TextButton.styleFrom(
            backgroundColor: Colors.grey[850],
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),
        )
      ],
    );
  }

  Widget buildRiffsTable() {
    return SizedBox(
      width: double.infinity,
      child: DataTable(
        headingRowColor: MaterialStateColor.resolveWith((_) => Colors.grey.shade800),
        columnSpacing: 16,
        dataRowMinHeight: 40,
        dataRowMaxHeight: 60,
        columns: const [
          DataColumn(label: Text('Name', style: TextStyle(color: Colors.white70))),
          DataColumn(label: Text('Category', style: TextStyle(color: Colors.white70))),
          DataColumn(label: Text('Path', style: TextStyle(color: Colors.white70))),
          DataColumn(label: Text('Actions', style: TextStyle(color: Colors.white70))),
        ],
        rows: riffs.map((riff) {
          return DataRow(cells: [
            DataCell(Text(riff.name, style: const TextStyle(color: Colors.white))),
            DataCell(Text(riff.category, style: const TextStyle(color: Colors.white))),
            DataCell(SizedBox(
              width: 200,
              child: Text(riff.filePath,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white54)),
            )),
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
                      MaterialPageRoute(builder: (_) => RiffEditorPage(existingRiff: riff)),
                    );
                    loadData();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () => deleteRiff(riff.id!),
                ),
              ],
            )),
          ]);
        }).toList(),
      ),
    );
  }

  Widget buildCategoryTable() {
    final riffCount = <String, int>{};
    for (final riff in riffs) {
      riffCount[riff.category] = (riffCount[riff.category] ?? 0) + 1;
    }

    return SizedBox(
      width: double.infinity,
      child: DataTable(
        headingRowColor: MaterialStateColor.resolveWith((_) => Colors.grey.shade800),
        columnSpacing: 16,
        dataRowMinHeight: 40,
        dataRowMaxHeight: 60,
        columns: const [
          DataColumn(label: Text('Category', style: TextStyle(color: Colors.white70))),
          DataColumn(label: Text('Riff Count', style: TextStyle(color: Colors.white70))),
          DataColumn(label: Text('Actions', style: TextStyle(color: Colors.white70))),
        ],
        rows: categories.map((category) {
          final count = riffCount[category] ?? 0;
          return DataRow(cells: [
            DataCell(Text(category, style: const TextStyle(color: Colors.white))),
            DataCell(Text('$count', style: const TextStyle(color: Colors.white54))),
            DataCell(Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.orangeAccent),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CategoryEditorPage()),
                    );
                    loadData();
                  },
                ),
                if (category != 'Uncategorized')
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () async {
                      await CategoryDao.deleteCategory(category);
                      loadData();
                    },
                  ),
              ],
            )),
          ]);
        }).toList(),
      ),
    );
  }

  Widget buildPanel(String title, VoidCallback onCreate, Widget child) {
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
            Expanded(child: SingleChildScrollView(child: child)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Riff Architect Dashboard'),
        backgroundColor: Colors.grey[900],
      ),
      body: isMobile
          ? ListView(
              children: [
                buildPanel('Riffs', () async {
                  await Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const RiffEditorPage()));
                  loadData();
                }, buildRiffsTable()),
                buildPanel('Categories', () async {
                  await Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const CategoryEditorPage()));
                  loadData();
                }, buildCategoryTable()),
                buildPanel('Songs', () async {
                  await Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const SongEditorPage()));
                }, const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('Compose and manage songs',
                      style: TextStyle(color: Colors.white54)),
                )),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildPanel('Riffs', () async {
                  await Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const RiffEditorPage()));
                  loadData();
                }, buildRiffsTable()),
                buildPanel('Categories', () async {
                  await Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const CategoryEditorPage()));
                  loadData();
                }, buildCategoryTable()),
                buildPanel('Songs', () async {
                  await Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const SongEditorPage()));
                }, const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('Compose and manage songs',
                      style: TextStyle(color: Colors.white54)),
                )),
              ],
            ),
    );
  }
}
