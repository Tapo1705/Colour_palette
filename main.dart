import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:palette_generator/palette_generator.dart';

void main() => runApp(const ColorHarmonyApp());

class ColorHarmonyApp extends StatelessWidget {
  const ColorHarmonyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Color Palette Harmony',
        theme: ThemeData(
          primarySwatch: Colors.deepPurple,
          scaffoldBackgroundColor: const Color(0xFFF5F6FA),
          
        ),
        home: const HarmonyHome(),
      );
}

class HarmonyHome extends StatefulWidget {
  const HarmonyHome({Key? key}) : super(key: key);

  @override
  State<HarmonyHome> createState() => _HarmonyHomeState();
}

class _HarmonyHomeState extends State<HarmonyHome> {
  File? _imageFile;
  List<Color> _palette = [];
  String _feedback = 'Pick a photo to check color harmony';
  bool _loading = false;

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _loading = true;
        _imageFile = File(result.files.single.path!);
      });
      await _analyzePalette(_imageFile!);
    }
  }

  Future<void> _analyzePalette(File imageFile) async {
    try {
      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        FileImage(imageFile),
        size: const Size(300, 300),
        maximumColorCount: 6,
      );
      final colors = paletteGenerator.colors.toList();
      setState(() {
        _palette = colors;
        _feedback = _ratePalette(colors);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _feedback = "Error extracting colors.";
        _palette = [];
        _loading = false;
      });
    }
  }

  String _ratePalette(List<Color> colors) {
    if (colors.length < 2) return 'Try a clearer image!';
    final luminances = colors.map((c) => c.computeLuminance()).toList();
    var maxDiff = 0.0;
    for (var i = 0; i < luminances.length; i++) {
      for (var j = i + 1; j < luminances.length; j++) {
        maxDiff = (luminances[i] - luminances[j]).abs() > maxDiff
            ? (luminances[i] - luminances[j]).abs()
            : maxDiff;
      }
    }
    if (maxDiff < 0.18) return 'Colors are soft and minimalistic!';
    if (maxDiff < 0.39) return 'Pleasant harmony!';
    if (maxDiff < 0.70) return 'Bold & contrasting!';
    return 'High contrast—may look clashing!';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clothes Palette Checker'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(28.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: _imageFile != null
                        ? Image.file(
                            _imageFile!,
                            height: 210,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          )
                        : Container(
                            height: 160,
                            width: double.infinity,
                            color: Colors.deepPurple.shade50,
                            child: const Icon(Icons.camera_alt_rounded,
                                size: 70, color: Colors.deepPurple),
                          ),
                  ),
                  const SizedBox(height: 25),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.photo),
                    label: const Text('Pick a Clothes Photo'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    onPressed: _loading ? null : _pickImage,
                  ),
                  const SizedBox(height: 24),
                  if (_loading) const CircularProgressIndicator(),
                  if (!_loading) ...[
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        _feedback,
                        key: ValueKey(_feedback),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_palette.isNotEmpty)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: _palette
                            .map((c) => Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: c,
                                    borderRadius: BorderRadius.circular(9),
                                    border: Border.all(
                                        color: Colors.grey.shade300, width: 2),
                                  ),
                                ))
                            .toList(),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}