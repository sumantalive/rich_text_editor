import 'package:flutter/material.dart';
import 'package:rich_text_editor/rich_text_editor.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Rich Text Editor Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const ExampleScreen(),
    );
  }
}

class ExampleScreen extends StatefulWidget {
  const ExampleScreen({super.key});

  @override
  State<ExampleScreen> createState() => _ExampleScreenState();
}

class _ExampleScreenState extends State<ExampleScreen> {
  late RichTextEditorConfig _config;
  String _customizationMode = 'default';

  @override
  void initState() {
    super.initState();
    _config = const RichTextEditorConfig();
  }

  void _updateConfig(String mode) {
    setState(() {
      _customizationMode = mode;
      switch (mode) {
        case 'default':
          _config = const RichTextEditorConfig();
          break;
        case 'minimal':
          _config = const RichTextEditorConfig(
            title: 'Simple Editor',
            enableExport: false,
            enableHtmlImport: false,
            enableUndoRedo: false,
            showToolbar: true,
          );
          break;
        case 'professional':
          _config = const RichTextEditorConfig(
            title: 'Professional Editor',
            appBarColor: Colors.deepPurple,
            buttonColor: Colors.deepPurple,
            toolbarBackgroundColor: Color(0xFFF5F5F5),
            highlightOpacity: 0.35,
            hintText: 'Enter your content here...',
          );
          break;
        case 'dark':
          _config = const RichTextEditorConfig(
            title: 'Dark Mode Editor',
            appBarColor: Color(0xFF212121),
            buttonColor: Color(0xFF424242),
            toolbarBackgroundColor: Color(0xFF424242),
            textColor: Colors.white,
          );
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration Examples'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Configuration:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildConfigButton('Default', 'default'),
                    _buildConfigButton('Minimal', 'minimal'),
                    _buildConfigButton('Professional', 'professional'),
                    _buildConfigButton('Dark', 'dark'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: RichTextEditor(
              config: _config,
              onSave: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Content saved!')),
                );
              },
              onLoad: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Content loaded!')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigButton(String label, String mode) {
    final isSelected = _customizationMode == mode;
    return ElevatedButton(
      onPressed: () => _updateConfig(mode),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : Colors.white,
        foregroundColor: isSelected ? Colors.white : Colors.black,
      ),
      child: Text(label),
    );
  }
}
