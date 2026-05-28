import 'package:flutter/material.dart';
import 'custom_button.dart';

class ImageLinkDialog extends StatefulWidget {
  final String? initialLink;
  final ValueChanged<String?> onLinkSaved;

  /// Dialog heading; defaults to image-link wording but can be overridden so
  /// the same dialog can add a link to selected text.
  final String title;
  final String description;

  const ImageLinkDialog({
    super.key,
    this.initialLink,
    required this.onLinkSaved,
    this.title = 'Add Image Link',
    this.description = 'Enter the URL this image should link to:',
  });

  @override
  State<ImageLinkDialog> createState() => _ImageLinkDialogState();
}

class _ImageLinkDialogState extends State<ImageLinkDialog> {
  late TextEditingController _linkController;

  @override
  void initState() {
    super.initState();
    _linkController = TextEditingController(text: widget.initialLink ?? '');
  }

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }

  bool _isValidUrl(String url) {
    if (url.isEmpty) return true;
    try {
      Uri.parse(url);
      return url.startsWith('http://') || url.startsWith('https://');
    } catch (e) {
      return false;
    }
  }

  void _saveLink() {
    String link = _linkController.text.trim();
    if (link.isNotEmpty && !link.startsWith('http://') && !link.startsWith('https://')) {
      link = 'https://$link';
    }
    if (link.isEmpty || _isValidUrl(link)) {
      widget.onLinkSaved(link.isEmpty ? null : link);
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid URL')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.description,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          ExcludeSemantics(
            child: TextField(
              controller: _linkController,
              decoration: InputDecoration(
                hintText: 'https://example.com',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
                suffixIcon: _linkController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _linkController.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (value) => setState(() {}),
              onSubmitted: (_) => _saveLink(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            _linkController.clear();
            widget.onLinkSaved(null);
            Navigator.pop(context);
          },
          child: const Text('Remove Link'),
        ),
        CustomButton(
          label: 'Save Link',
          onPressed: _saveLink,
        ),
      ],
    );
  }
}
