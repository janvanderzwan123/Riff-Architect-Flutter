import 'package:flutter/material.dart';
import 'package:riff_architect/models/riff.dart';
import 'package:riff_architect/db/riff_dao.dart';
import 'package:riff_architect/db/category_dao.dart';

class CategoryEditorPage extends StatefulWidget {
  const CategoryEditorPage({super.key});

  @override
  State<CategoryEditorPage> createState() => _CategoryEditorPageState();
}

class _CategoryEditorPageState extends State<CategoryEditorPage> {
  List<String> categories = [];
  Map<String, List<Riff>> categorizedRiffs = {};

  @override
  void initState() {
    super.initState();
    _loadCategoriesAndRiffs();
  }

  Future<void> _loadCategoriesAndRiffs() async {
    final allCategories = await CategoryDao.getAllCategories();
    final riffs = await RiffDao.getAllRiffs();

    final Map<String, List<Riff>> map = {};
    for (var riff in riffs) {
      map.putIfAbsent(riff.category, () => []).add(riff);
    }

    setState(() {
      categories = ['Uncategorized', ...allCategories.where((c) => c != 'Uncategorized')];
      categorizedRiffs = map;
    });
  }

  void _showCreateCategoryOverlay() {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Create New Category',
                style: TextStyle(fontSize: 18, color: Colors.white)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Category Name',
                labelStyle: TextStyle(color: Colors.white70),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isNotEmpty &&
                    !categories.contains(name) &&
                    name.toLowerCase() != 'uncategorized') {
                  await CategoryDao.insertCategory(name);
                  await _loadCategoriesAndRiffs();
                }
                Navigator.pop(context);
              },
              icon: const Icon(Icons.check),
              label: const Text('Add Category'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _renameCategory(String oldName) {
    if (oldName == 'Uncategorized') return;
    final controller = TextEditingController(text: oldName);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Rename Category', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'New Name',
            labelStyle: TextStyle(color: Colors.white70),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          TextButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty &&
                  newName != oldName &&
                  !categories.contains(newName)) {
                await CategoryDao.renameCategory(oldName, newName);

                final riffsToUpdate = categorizedRiffs.remove(oldName) ?? [];
                for (var riff in riffsToUpdate) {
                  final updated = Riff(
                    id: riff.id,
                    name: riff.name,
                    category: newName,
                    filePath: riff.filePath,
                  );
                  await RiffDao.insertRiff(updated);
                  await RiffDao.deleteRiff(riff.id!);
                }

                await _loadCategoriesAndRiffs();
              }
              Navigator.pop(context);
            },
            child: const Text('Rename', style: TextStyle(color: Colors.greenAccent)),
          )
        ],
      ),
    );
  }

  void _deleteCategory(String name) {
    if (name == 'Uncategorized') return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text('Delete "$name"?', style: const TextStyle(color: Colors.white)),
        content: const Text(
          'This will move all riffs in this category to "Uncategorized".',
          style: TextStyle(color: Colors.white60),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          TextButton(
            onPressed: () async {
              final movedRiffs = categorizedRiffs.remove(name) ?? [];

              for (var riff in movedRiffs) {
                final updated = Riff(
                  id: riff.id,
                  name: riff.name,
                  category: 'Uncategorized',
                  filePath: riff.filePath,
                );
                await RiffDao.insertRiff(updated);
                await RiffDao.deleteRiff(riff.id!);
              }

              await CategoryDao.deleteCategory(name);
              await _loadCategoriesAndRiffs();
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(String category) {
    final riffs = categorizedRiffs[category] ?? [];
    return Card(
      color: Colors.grey[850],
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        collapsedIconColor: Colors.white60,
        iconColor: Colors.greenAccent,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        title: Text(category, style: const TextStyle(color: Colors.white, fontSize: 16)),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        children: [
          if (riffs.isEmpty)
            const ListTile(
              title: Text('No riffs in this category',
                  style: TextStyle(color: Colors.white38, fontStyle: FontStyle.italic)),
            )
          else
            ...riffs.map((r) => ListTile(
                  title: Text(r.name, style: const TextStyle(color: Colors.white70)),
                )),
          const Divider(color: Colors.white12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (category != 'Uncategorized')
                TextButton(
                  onPressed: () => _renameCategory(category),
                  child: const Text('Rename', style: TextStyle(color: Colors.greenAccent)),
                ),
              if (category != 'Uncategorized')
                TextButton(
                  onPressed: () => _deleteCategory(category),
                  child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: const Text('Edit Categories'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateCategoryOverlay,
        backgroundColor: Colors.greenAccent,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('Create Category'),
      ),
      body: categories.isEmpty
          ? const Center(
              child: Text('No categories available',
                  style: TextStyle(color: Colors.white38)),
            )
          : ListView.builder(
              itemCount: categories.length,
              itemBuilder: (_, i) => _buildCategoryTile(categories[i]),
            ),
    );
  }
}
