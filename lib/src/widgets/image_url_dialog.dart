import 'package:flutter/material.dart';
import 'custom_button.dart';

class ImageUrlDialog extends StatefulWidget {
  final ValueChanged<String> onImageUrlAdded;

  const ImageUrlDialog({
    super.key,
    required this.onImageUrlAdded,
  });

  @override
  State<ImageUrlDialog> createState() => _ImageUrlDialogState();
}

class _ImageUrlDialogState extends State<ImageUrlDialog> {
  late TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController();
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  bool _isValidUrl(String url) {
    try {
      Uri.parse(url);
      return url.startsWith('http://') || url.startsWith('https://');
    } catch (e) {
      return false;
    }
  }

  void _addImage() {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Please enter an image URL')),
      );
      return;
    }

    if (!_isValidUrl(url)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Please enter a valid image URL (http:// or https://)')),
      );
      return;
    }

    widget.onImageUrlAdded(url);
    _urlController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Image URL'),
      content: TextField(
        controller: _urlController,
        decoration: InputDecoration(
          hintText: 'https://example.com/image.jpg',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.all(12),
        ),
        maxLines: 3,
        onSubmitted: (_) => _addImage(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        CustomButton(
          label: 'Add Image',
          onPressed: _addImage,
        ),
      ],
    );
  }
}
