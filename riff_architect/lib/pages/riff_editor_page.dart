import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riff_architect/models/riff.dart';
import 'package:riff_architect/db/riff_dao.dart';
import 'package:riff_architect/db/category_dao.dart';
import 'package:audioplayers/audioplayers.dart';

class RiffEditorPage extends StatefulWidget {
  final Riff? existingRiff;
  const RiffEditorPage({super.key, this.existingRiff});

  @override
  State<RiffEditorPage> createState() => _RiffEditorPageState();
}

class _RiffEditorPageState extends State<RiffEditorPage> {
  final nameController = TextEditingController();
  String selectedCategory = 'Uncategorized';
  List<String> categories = ['Uncategorized'];
  String? filePath;
  bool isRecording = false;
  bool isPlaying = false;
  List<int> waveform = [];
  Timer? metronomeTimer;
  int bpm = 100;
  bool metronomeOn = false;
  bool blink = false;
  final player = AudioPlayer();
  DateTime? lastModified;
  int? fileSize;

  @override
  void initState() {
    super.initState();

    if (widget.existingRiff != null) {
      nameController.text = widget.existingRiff!.name;
      selectedCategory = widget.existingRiff!.category;
      filePath = widget.existingRiff!.filePath;
    }

    _loadCategories();

    if (filePath != null) _loadWaveform();
  }

  Future<void> _loadCategories() async {
    final fetched = await CategoryDao.getAllCategories();
    setState(() {
      categories = ['Uncategorized', ...fetched.where((c) => c != 'Uncategorized')];
      if (!categories.contains(selectedCategory)) {
        categories.add(selectedCategory);
      }
    });
  }


  Future<void> _loadWaveform() async {
    if (filePath == null) return;
    final file = File(filePath!);
    if (!await file.exists()) return;

    final bytes = await file.readAsBytes();
    final stats = await file.stat();
    lastModified = stats.modified;
    fileSize = stats.size;

    waveform = List.generate(300, (i) => bytes[i % bytes.length].abs() % 100);
    setState(() {});
  }

  Future<void> _startRecording() async {
    final dir = await getApplicationDocumentsDirectory();
    final outPath = p.join(dir.path, 'riff_${DateTime.now().millisecondsSinceEpoch}.wav');
    setState(() {
      filePath = outPath;
      isRecording = true;
    });
    await Process.start('arecord', ['-f', 'cd', '-t', 'wav', outPath]);
  }

  Future<void> _stopRecording() async {
    await Process.run('pkill', ['-f', 'arecord']);
    setState(() => isRecording = false);
    await _loadWaveform();
  }

  Future<void> _play() async {
    if (filePath == null) return;
    setState(() => isPlaying = true);
    try {
      await player.play(DeviceFileSource(filePath!));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Playback failed: $e')),
      );
    } finally {
      setState(() => isPlaying = false);
    }
  }


  Future<void> _save() async {
    final name = nameController.text.trim();
    if (name.isEmpty || filePath == null) return;

    final riff = Riff(
      id: widget.existingRiff?.id,
      name: name,
      category: selectedCategory,
      filePath: filePath!,
    );
    if (widget.existingRiff != null) {
      await RiffDao.deleteRiff(widget.existingRiff!.id!);
    }
    await RiffDao.insertRiff(riff);
    if (mounted) Navigator.pop(context);
  }

  void _toggleMetronome() {
    if (metronomeOn) {
      metronomeTimer?.cancel();
    } else {
      metronomeTimer = Timer.periodic(
        Duration(milliseconds: (60000 / bpm).round()),
        (_) => setState(() => blink = !blink),
      );
    }
    setState(() => metronomeOn = !metronomeOn);
  }

  @override
  void dispose() {
    nameController.dispose();
    player.dispose();
    metronomeTimer?.cancel();
    super.dispose();
  }

  Widget buildWaveform() {
    if (waveform.isEmpty) {
      return Container(
        height: 60,
        alignment: Alignment.center,
        child: const Text('No waveform loaded',
            style: TextStyle(color: Colors.white30, fontStyle: FontStyle.italic)),
      );
    }

    return CustomPaint(
      size: const Size(double.infinity, 60),
      painter: WaveformPainter(waveform),
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedCategory,
      decoration: const InputDecoration(
        labelText: 'Category',
        labelStyle: TextStyle(color: Colors.white70),
        border: OutlineInputBorder(),
      ),
      dropdownColor: Colors.grey[900],
      style: const TextStyle(color: Colors.white),
      items: categories
          .map((c) => DropdownMenuItem(
                value: c,
                child: Text(c, style: const TextStyle(color: Colors.white)),
              ))
          .toList(),
      onChanged: (value) => setState(() => selectedCategory = value ?? 'Uncategorized'),
    );
  }

  Widget _buildFileInfo() {
    if (filePath == null || fileSize == null) return const SizedBox();
    final sizeKb = (fileSize! / 1024).toStringAsFixed(1);
    final modifiedStr = lastModified != null
        ? '${lastModified!.toLocal()}'.split('.')[0]
        : 'Unknown';
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(
        '📄 $sizeKb KB — Modified: $modifiedStr',
        style: const TextStyle(color: Colors.white38, fontSize: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.existingRiff == null ? 'New Riff' : 'Edit Riff'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Riff Name',
                labelStyle: TextStyle(color: Colors.white70),
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            _buildCategoryDropdown(),
            const SizedBox(height: 24),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: isRecording ? _stopRecording : _startRecording,
                  icon: Icon(isRecording ? Icons.stop : Icons.fiber_manual_record),
                  label: Text(isRecording ? 'Stop' : 'Record'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isRecording ? Colors.grey : Colors.redAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: isPlaying || filePath == null ? null : _play,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Play'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            buildWaveform(),
            _buildFileInfo(),
            const SizedBox(height: 24),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _toggleMetronome,
                  icon: Icon(metronomeOn ? Icons.stop_circle : Icons.play_circle_fill),
                  label: Text(metronomeOn ? 'Stop Metronome' : 'Start Metronome'),
                ),
                const SizedBox(width: 12),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: metronomeOn && blink ? Colors.greenAccent : Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    min: 40,
                    max: 240,
                    value: bpm.toDouble(),
                    label: '$bpm BPM',
                    divisions: 200,
                    onChanged: (v) => setState(() => bpm = v.round()),
                  ),
                ),
                Text('$bpm BPM', style: const TextStyle(color: Colors.white70)),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('Save Riff'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WaveformPainter extends CustomPainter {
  final List<int> waveform;
  WaveformPainter(this.waveform);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.lightBlueAccent
      ..strokeWidth = 2;
    final midY = size.height / 2;
    final spacing = size.width / waveform.length;
    for (int i = 0; i < waveform.length; i++) {
      final x = i * spacing;
      final y = waveform[i] / 100 * midY;
      canvas.drawLine(Offset(x, midY - y), Offset(x, midY + y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
