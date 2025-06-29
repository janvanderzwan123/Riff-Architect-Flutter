// Full-featured riff editor page with:
// - Recording using arecord
// - Playback
// - Waveform visualization (custom painted)
// - Metronome with blinking light
// - Dark minimalistic UI
// - File saving, riff naming, category, and preview

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riff_architect/models/riff.dart';
import 'package:riff_architect/db/riff_dao.dart';
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
  String? filePath;
  bool isRecording = false;
  bool isPlaying = false;
  List<int> waveform = [];
  Timer? metronomeTimer;
  int bpm = 100;
  bool metronomeOn = false;
  bool blink = false;
  final player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    if (widget.existingRiff != null) {
      nameController.text = widget.existingRiff!.name;
      selectedCategory = widget.existingRiff!.category;
      filePath = widget.existingRiff!.filePath;
    }
    if (filePath != null) {
      _loadWaveform();
    }
  }

  Future<void> _loadWaveform() async {
    if (filePath == null) return;
    final file = File(filePath!);
    if (!await file.exists()) return;
    final bytes = await file.readAsBytes();
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
    Process.run('arecord', ['-f', 'cd', '-t', 'wav', outPath]);
  }

  Future<void> _stopRecording() async {
    await Process.run('pkill', ['-f', 'arecord']);
    setState(() {
      isRecording = false;
    });
    _loadWaveform();
  }

  Future<void> _play() async {
    if (filePath == null) return;
    setState(() => isPlaying = true);
    await player.play(DeviceFileSource(filePath!));
    setState(() => isPlaying = false);
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
    if (widget.existingRiff == null) {
      await RiffDao.insertRiff(riff);
    } else {
      await RiffDao.deleteRiff(widget.existingRiff!.id!);
      await RiffDao.insertRiff(riff);
    }
    Navigator.pop(context);
  }

  void _toggleMetronome() {
    setState(() => metronomeOn = !metronomeOn);
    metronomeTimer?.cancel();
    if (metronomeOn) {
      metronomeTimer = Timer.periodic(
        Duration(milliseconds: (60000 / bpm).round()),
        (_) => setState(() => blink = !blink),
      );
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    player.dispose();
    metronomeTimer?.cancel();
    super.dispose();
  }

  Widget buildWaveform() {
    if (waveform.isEmpty) return const SizedBox(height: 60);
    return CustomPaint(
      size: const Size(double.infinity, 60),
      painter: WaveformPainter(waveform),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: Text(widget.existingRiff == null ? 'Create Riff' : 'Edit Riff'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              DropdownButtonFormField<String>(
                value: selectedCategory,
                dropdownColor: Colors.grey[900],
                decoration: const InputDecoration(
                  labelText: 'Category',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                ),
                items: ['Uncategorized', 'Lead', 'Rhythm', 'Bass']
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c, style: const TextStyle(color: Colors.white)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => selectedCategory = v!),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: isRecording ? _stopRecording : _startRecording,
                    icon: Icon(isRecording ? Icons.stop : Icons.fiber_manual_record),
                    label: Text(isRecording ? 'Stop' : 'Record'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: isPlaying ? null : _play,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Play'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              buildWaveform(),
              const SizedBox(height: 16),
              Row(
                children: [
                  GestureDetector(
                    onTap: _toggleMetronome,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: metronomeOn && blink ? Colors.greenAccent : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Slider(
                      min: 40,
                      max: 240,
                      divisions: 200,
                      label: '$bpm BPM',
                      value: bpm.toDouble(),
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
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent[400]),
                ),
              )
            ],
          ),
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
