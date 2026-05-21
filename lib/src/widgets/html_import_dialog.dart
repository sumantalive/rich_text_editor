import 'package:flutter/material.dart';

class HtmlImportDialog extends StatefulWidget {
  final Function(String) onImport;

  const HtmlImportDialog({
    super.key,
    required this.onImport,
  });

  @override
  State<HtmlImportDialog> createState() => _HtmlImportDialogState();
}

class _HtmlImportDialogState extends State<HtmlImportDialog> {
  late TextEditingController _htmlController;

  @override
  void initState() {
    super.initState();
    _htmlController = TextEditingController();
  }

  @override
  void dispose() {
    _htmlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Import HTML'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste your HTML code below:',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _htmlController,
              maxLines: 10,
              minLines: 5,
              decoration: InputDecoration(
                hintText: 'Enter HTML here...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _handleImport,
          child: const Text('Import'),
        ),
      ],
    );
  }

  void _handleImport() {
    final html = _htmlController.text.trim();
    if (html.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please paste HTML code')),
      );
      return;
    }
    widget.onImport(html);
    Navigator.pop(context);
  }
}
