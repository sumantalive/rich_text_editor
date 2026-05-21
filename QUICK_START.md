# Quick Start Guide - Rich Text Editor Package

Get started with Rich Text Editor in 5 minutes!

## Step 1: Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  rich_text_editor: ^1.0.0
```

Then run:
```bash
flutter pub get
```

## Step 2: Import the Package

```dart
import 'package:rich_text_editor/rich_text_editor.dart';
```

## Step 3: Create the Editor

### Minimal Setup
```dart
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
      home: Scaffold(
        body: RichTextEditor(
          config: const RichTextEditorConfig(
            title: 'My Editor',
          ),
        ),
      ),
    );
  }
}
```

### With Customization
```dart
RichTextEditor(
  config: RichTextEditorConfig(
    title: 'Custom Editor',
    appBarColor: Colors.deepPurple,
    buttonColor: Colors.deepPurple,
    enableImageUpload: true,
    enableHtmlImport: true,
  ),
  onSave: () {
    print('Content saved!');
  },
  onLoad: () {
    print('Content loaded!');
  },
)
```

## Step 4: Run Your App

```bash
flutter run
```

## Common Use Cases

### Dark Mode Editor
```dart
RichTextEditor(
  config: RichTextEditorConfig(
    title: 'Dark Editor',
    appBarColor: Color(0xFF212121),
    buttonColor: Color(0xFF424242),
    toolbarBackgroundColor: Color(0xFF424242),
    textColor: Colors.white,
  ),
)
```

### Limited Features (No Images)
```dart
RichTextEditor(
  config: RichTextEditorConfig(
    title: 'Text Only',
    enableImageUpload: false,
    enableHtmlImport: false,
  ),
)
```

### With Backend Saving
```dart
RichTextEditor(
  config: const RichTextEditorConfig(),
  onSave: () async {
    // Get HTML content
    final html = HtmlConverter.toHtml(
      controller.text,
      controller.extractSpanData(),
      controller.extractImageData(),
      'left',
    );
    // Save to backend
    await saveToBackend(html);
  },
)
```

## Features at a Glance

✨ **Text Formatting**
- Bold, Italic, Underline, Strikethrough
- Text and background colors
- Font size and family selection
- Text alignment

🖼️ **Images**
- Insert from URLs
- Add hyperlinks
- Reorder by dragging
- Preview dialog

📄 **HTML**
- Export as HTML
- Import HTML code
- Full formatting preserved

↩️ **Undo/Redo**
- Full history support
- Keyboard shortcuts

💾 **Storage**
- Auto save to device
- Load previous content

## Configuration Options

```dart
RichTextEditorConfig(
  // Display
  title: 'Text Editor',                    // AppBar title
  hintText: 'Write message...',            // Input hint
  
  // Colors
  appBarColor: Colors.blue,                // AppBar color
  buttonColor: Colors.blue,                // Button color
  toolbarBackgroundColor: Colors.white,    // Toolbar color
  textColor: Colors.black,                 // Text color
  
  // Features
  enableExport: true,                      // Show export button
  enableHtmlImport: true,                  // Show import button
  enableSave: true,                        // Show save button
  enableLoad: true,                        // Show load button
  enableImageUpload: true,                 // Allow images
  enableUndoRedo: true,                    // Show undo/redo
  
  // Styling
  defaultFontSize: 14.0,                   // Default font size
  highlightOpacity: 0.4,                   // Highlight transparency
  toolbarHeight: 60.0,                     // Toolbar height
  showToolbar: true,                       // Show toolbar
  
  // Storage
  storageKey: 'rich_text_editor_data',    // Local storage key
)
```

## Accessing Content

```dart
// Get the controller
final controller = RichTextController();

// Get plain text
String text = controller.text;

// Get formatted spans
List<SpanData> spans = controller.extractSpanData();

// Get images
List<ImageData> images = controller.extractImageData();

// Export to HTML
String html = HtmlConverter.toHtml(text, spans, images, 'left');
```

## Troubleshooting

**Q: Images not loading?**
A: Ensure URLs are valid HTTPS and images are publicly accessible.

**Q: HTML import not working?**
A: Check HTML is properly formatted. Complex HTML may need simplification.

**Q: Save/load not working?**
A: Verify storage permissions and ensure unique `storageKey` for multiple editors.

**Q: Want to disable a feature?**
A: Set corresponding `enableXxx` to false in config.

## Next Steps

1. **Explore Examples**: Check `example/lib/main.dart`
2. **Read Full Docs**: See `README.md`
3. **Understand Architecture**: Read `ARCHITECTURE.md`
4. **Customize**: Adjust `RichTextEditorConfig`
5. **Integrate**: Add to your app!

## Need Help?

- **Documentation**: See README.md
- **Examples**: Run the example app
- **Architecture**: Read ARCHITECTURE.md
- **Publishing**: See PUBLISHING.md

---

**That's it! You're ready to use Rich Text Editor.** 🚀

Start with the minimal setup above and gradually customize as needed!
