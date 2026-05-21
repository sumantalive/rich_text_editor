# Rich Text Editor

A customizable, feature-rich text editor widget for Flutter with support for text formatting, HTML import/export, images, and undo/redo functionality.

## Features

✨ **Rich Text Formatting**
- Bold, Italic, Underline, Strikethrough
- Text color customization
- Background highlight with adjustable opacity
- Font size adjustment
- Font family selection (sans-serif, serif, monospace, and more)
- Text alignment (left, center, right, justify)

🖼️ **Image Support**
- Insert images from URLs
- Drag and reorder images
- Add hyperlinks to images
- Image preview dialog

📄 **HTML Export/Import**
- Export formatted content as HTML
- Import HTML with full formatting preservation
- Comprehensive HTML parser for complex documents

↩️ **Undo/Redo**
- Full undo/redo support
- State management for complex formatting operations

💾 **Persistence**
- Save content to local storage
- Load previously saved content
- Customizable storage key

🎨 **Highly Customizable**
- Theme colors (AppBar, buttons, toolbar)
- Enable/disable features
- Custom text input styling
- Toolbar customization
- Highlight opacity control

## Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  rich_text_editor: ^1.0.0
```

Then run:

```bash
flutter pub get
```

## Quick Start

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
          config: RichTextEditorConfig(
            title: 'My Text Editor',
          ),
        ),
      ),
    );
  }
}
```

## Customization

### Basic Configuration

```dart
RichTextEditor(
  config: RichTextEditorConfig(
    title: 'Custom Editor',
    appBarColor: Colors.blue,
    buttonColor: Colors.blue,
    hintText: 'Start typing...',
  ),
)
```

### Disable Features

```dart
RichTextEditor(
  config: RichTextEditorConfig(
    title: 'Minimal Editor',
    enableExport: false,
    enableHtmlImport: false,
    enableImageUpload: false,
    enableUndoRedo: false,
  ),
)
```

### Theme Customization

```dart
RichTextEditor(
  config: RichTextEditorConfig(
    title: 'Dark Mode Editor',
    appBarColor: Color(0xFF212121),
    buttonColor: Color(0xFF424242),
    toolbarBackgroundColor: Color(0xFF424242),
    textColor: Colors.white,
  ),
)
```

### Callbacks

```dart
RichTextEditor(
  config: const RichTextEditorConfig(),
  onSave: () {
    print('Content saved!');
  },
  onLoad: () {
    print('Content loaded!');
  },
)
```

## Configuration Options

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `title` | String | 'Text Editor' | AppBar title |
| `appBarColor` | Color | Colors.blue | AppBar background color |
| `hintText` | String | 'Write message...' | Input field hint text |
| `enableExport` | bool | true | Show export HTML button |
| `enableImport` | bool | true | Show load from storage button |
| `enableSave` | bool | true | Show save button |
| `enableLoad` | bool | true | Show load button |
| `enableImageUpload` | bool | true | Allow image insertion |
| `enableHtmlImport` | bool | true | Show import HTML button |
| `enableUndoRedo` | bool | true | Show undo/redo buttons |
| `buttonColor` | Color | Colors.blue | Button color |
| `buttonTextColor` | Color | Colors.white | Button text color |
| `defaultFontSize` | double | 14.0 | Default text font size |
| `textColor` | Color | Colors.black | Default text color |
| `toolbarBackgroundColor` | Color | Colors.white | Toolbar background color |
| `toolbarHeight` | double | 60.0 | Toolbar height |
| `showToolbar` | bool | true | Show formatting toolbar |
| `highlightOpacity` | double | 0.4 | Background highlight opacity (0.0-1.0) |
| `storageKey` | String | 'rich_text_editor_data' | Local storage key for save/load |

## Accessing Editor Content

To access the editor content programmatically, you can use the `RichTextController`:

```dart
import 'package:rich_text_editor/rich_text_editor.dart';

final controller = RichTextController();

// Get text
String text = controller.text;

// Get formatting spans
List<SpanData> spans = controller.extractSpanData();

// Get images
List<ImageData> images = controller.extractImageData();

// Export to HTML
String html = HtmlConverter.toHtml(
  controller.text,
  controller.extractSpanData(),
  controller.extractImageData(),
  'left',
);
```

## Export & Import

### Export HTML

The editor can export content as formatted HTML. This HTML can be:
- Saved to a file
- Sent to a server
- Displayed in a web view
- Stored in a database

### Import HTML

Import HTML content with full formatting preservation:

```dart
// Paste HTML code in the import dialog
// The editor automatically parses:
// - Text content and formatting (bold, italic, etc.)
// - Colors and background highlights
// - Font sizes and families
// - Images and hyperlinks
// - Text alignment
```

## Example App

Check the `example/` directory for a complete example app with multiple configuration presets:

```bash
cd example
flutter run
```

The example app demonstrates:
- Default configuration
- Minimal configuration (limited features)
- Professional theme
- Dark mode theme

## Best Practices

1. **Storage Key**: Use a unique `storageKey` if you have multiple editors in your app
2. **Highlight Opacity**: Adjust `highlightOpacity` (0.4 is recommended) so highlighted text remains readable
3. **Feature Enablement**: Disable features you don't need to simplify the UI
4. **Callbacks**: Use `onSave` and `onLoad` callbacks to handle data persistence on your backend

## Architecture

The package is organized as follows:

```
lib/
├── src/
│   ├── config/           # Configuration classes
│   ├── controllers/       # Text and state management
│   ├── models/           # Data models (SpanData, ImageData)
│   ├── services/         # HTML conversion, undo/redo
│   └── widgets/          # UI components
└── rich_text_editor.dart # Public API
```

### Key Components

- **RichTextEditorConfig**: Configuration object for customization
- **RichTextEditor**: Main widget to use in your app
- **RichTextController**: Low-level text controller for direct manipulation
- **HtmlConverter**: Converts between text and HTML formats
- **SpanData**: Represents formatted text spans
- **ImageData**: Represents images in the editor

## License

MIT License - See LICENSE file for details

## Support

For issues, feature requests, or contributions, please visit the GitHub repository.

---

Made with ❤️ for Flutter developers
