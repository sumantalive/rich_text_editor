import 'package:flutter/material.dart';
import '../config/editor_config.dart';
import 'compose_screen.dart';

class RichTextEditor extends StatelessWidget {
  /// Configuration for the editor
  final RichTextEditorConfig config;

  /// Callback when content is saved
  final VoidCallback? onSave;

  /// Callback when content is loaded
  final VoidCallback? onLoad;

  const RichTextEditor({
    super.key,
    this.config = const RichTextEditorConfig(),
    this.onSave,
    this.onLoad,
  });

  @override
  Widget build(BuildContext context) {
    return ComposeScreen(
      config: config,
      onSave: onSave,
      onLoad: onLoad,
    );
  }
}
