# Rich Text Editor - Usage Guide

## Installation

### From pub.dev
```yaml
dependencies:
  rich_text_editor: ^1.0.0
```

### From GitHub
```yaml
dependencies:
  rich_text_editor:
    git:
      url: https://github.com/sumantalive/rich_text_editor.git
      ref: main
```

### From Local (Development)
```yaml
dependencies:
  rich_text_editor:
    path: ../rich_text_editor
```

Then run:
```bash
flutter pub get
```

---

## Import Statements

### Basic Imports
```dart
import 'package:rich_text_editor/rich_text_editor.dart';
```

This gives you access to all public classes:
- `ComposeScreen` - Full featured editor screen
- `RichTextEditor` - Embedded editor widget
- `RichTextEditorConfig` - Configuration class
- `RichTextController` - Controller for managing editor state
- And more...

### Selective Imports (if needed)
```dart
// Just the compose screen
import 'package:rich_text_editor/src/widgets/compose_screen.dart';

// Just the configuration
import 'package:rich_text_editor/src/config/editor_config.dart';

// Just the controller
import 'package:rich_text_editor/src/controllers/rich_text_controller.dart';
```

⚠️ **Note:** Selective imports from `src/` are NOT recommended. Always use the main import above.

---

## Usage Examples

### 1. Complete Compose Screen (Recommended)
Perfect for a notes app, message composer, or blog editor.

```dart
import 'package:flutter/material.dart';
import 'package:rich_text_editor/rich_text_editor.dart';

class NotesApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ComposeScreen(
        config: RichTextEditorConfig(
          title: 'New Note',
          enableImageUpload: true,
          enableHtmlImport: true,
          enableExport: true,
        ),
      ),
    );
  }
}
```

### 2. Embedded Editor Widget
Use the editor inside your existing UI.

```dart
import 'package:flutter/material.dart';
import 'package:rich_text_editor/rich_text_editor.dart';

class MyContent extends StatefulWidget {
  @override
  State<MyContent> createState() => _MyContentState();
}

class _MyContentState extends State<MyContent> {
  late RichTextController _controller;

  @override
  void initState() {
    super.initState();
    _controller = RichTextController();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: RichTextEditor(
            config: const RichTextEditorConfig(
              title: 'Edit Content',
              showToolbar: true,
            ),
            controller: _controller,
          ),
        ),
        ElevatedButton(
          onPressed: () {
            // Access the HTML content
            final htmlContent = _controller.getHtml();
            print('HTML: $htmlContent');
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

### 3. Custom Toolbar Configuration
```dart
ComposeScreen(
  config: RichTextEditorConfig(
    title: 'Minimal Editor',
    // Only show specific toolbar items
    toolbarItems: const [
      ToolbarItem(ToolbarItemType.bold),
      ToolbarItem(ToolbarItemType.italic),
      ToolbarItem(ToolbarItemType.underline),
      ToolbarItem(ToolbarItemType.textColor),
      ToolbarItem(ToolbarItemType.alignLeft),
      ToolbarItem(ToolbarItemType.alignCenter),
      ToolbarItem(ToolbarItemType.alignRight),
    ],
  ),
)
```

### 4. Custom Callbacks
```dart
ComposeScreen(
  config: RichTextEditorConfig(
    title: 'Editor with Custom Logic',
    onCustomSave: () async {
      // Save to your backend
      final htmlContent = _controller.getHtml();
      await apiService.saveNote(htmlContent);
    },
    onCustomExport: (htmlContent) async {
      // Custom export logic
      await Share.share(htmlContent);
    },
  ),
  onSave: () {
    print('Save button pressed');
  },
)
```

### 5. With Custom Styling
```dart
ComposeScreen(
  config: RichTextEditorConfig(
    title: 'Styled Editor',
    appBarColor: Colors.deepPurple,
    buttonColor: Colors.deepPurple,
    buttonTextColor: Colors.white,
    toolbarBackgroundColor: Colors.grey[100],
    textColor: Colors.black87,
    defaultFontSize: 16.0,
    hintText: 'Start typing...',
  ),
)
```

---

## Available Classes & Models

### Configuration
- **`RichTextEditorConfig`** - Customize appearance, toolbar, callbacks
  - Properties: title, colors, fonts, toolbar items, feature toggles, callbacks

### Main Widgets
- **`ComposeScreen`** - Full-featured editor screen
- **`RichTextEditor`** - Embedded editor widget

### Controller & State
- **`RichTextController`** - Manage editor content and state
  - Methods: `getHtml()`, `getText()`, `setText()`, `dispose()`

### Data Models
- **`ImageData`** - Represents an image in the editor
- **`SpanData`** - Represents a formatted text span

### Services
- **`HtmlConverter`** - Convert between HTML and editor format
- **`UndoRedoService`** - Handle undo/redo functionality

---

## Common Patterns

### Save to SharedPreferences
```dart
late RichTextController _controller;

void saveToLocal() async {
  final prefs = await SharedPreferences.getInstance();
  final htmlContent = _controller.getHtml();
  await prefs.setString('note_content', htmlContent);
}

void loadFromLocal() async {
  final prefs = await SharedPreferences.getInstance();
  final htmlContent = prefs.getString('note_content') ?? '';
  _controller.setText(htmlContent);
}
```

### Save to Backend API
```dart
void saveToServer() async {
  final htmlContent = _controller.getHtml();
  
  try {
    final response = await http.post(
      Uri.parse('https://api.example.com/notes'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'content': htmlContent}),
    );
    
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved successfully')),
      );
    }
  } catch (e) {
    print('Error: $e');
  }
}
```

### Add Custom Buttons to Toolbar
```dart
ComposeScreen(
  config: RichTextEditorConfig(
    title: 'Editor with Custom Buttons',
    customToolbarButtons: [
      CustomToolbarButton(
        id: 'custom_action',
        icon: Icons.star,
        tooltip: 'Favorite',
        onPressed: () {
          print('Custom button pressed');
        },
      ),
    ],
  ),
)
```

---

## Troubleshooting Import Issues

### Issue: "Import not found" error
**Solution:** Make sure you're using the correct import path:
```dart
// ✅ CORRECT
import 'package:rich_text_editor/rich_text_editor.dart';

// ❌ WRONG
import 'package:rich_text_editor/src/widgets/compose_screen.dart';
```

### Issue: ComposeScreen not found
**Solution:** Update to the latest version and ensure it's exported in the main file.
```bash
flutter pub upgrade rich_text_editor
```

### Issue: Controller not working
**Solution:** Make sure you're initializing the controller properly:
```dart
@override
void initState() {
  super.initState();
  _controller = RichTextController();
}

@override
void dispose() {
  _controller.dispose();
  super.dispose();
}
```

### Issue: Dependencies missing
**Solution:** Run pub get to ensure all dependencies are installed:
```bash
flutter pub get
```

---

## API Reference

### RichTextEditorConfig

```dart
const RichTextEditorConfig({
  // Appearance
  String title = 'Rich Text Editor',
  Color appBarColor = Colors.blue,
  Color buttonColor = Colors.blue,
  Color buttonTextColor = Colors.white,
  Color toolbarBackgroundColor = Colors.white,
  Color textColor = Colors.black,
  Color hintTextColor = Colors.grey,
  double defaultFontSize = 16.0,
  String hintText = 'Enter text...',

  // Toolbar customization
  List<ToolbarItem> toolbarItems = const [],
  List<CustomToolbarButton> customToolbarButtons = const [],
  List<CustomAppBarButton> customAppBarButtons = const [],

  // Feature toggles
  bool enableExport = true,
  bool enableImport = true,
  bool enableSave = true,
  bool enableLoad = true,
  bool enableImageUpload = true,
  bool enableHtmlImport = true,
  bool enableUndoRedo = true,
  bool showToolbar = true,

  // Dialog customization
  DialogCustomization dialogCustomization = const DialogCustomization(),

  // Callbacks
  Function(String)? onCustomExport,
  Function(String)? onCustomImport,
  Function()? onCustomSave,
  Function()? onCustomLoad,
})
```

---

## Best Practices

1. **Always use the main import** - Don't import from `src/` directory
2. **Dispose of controllers** - Always call `_controller.dispose()` in cleanup
3. **Handle errors** - Wrap API calls in try-catch blocks
4. **Test thoroughly** - Test on both Android and iOS
5. **Keep UI responsive** - Use async/await for long operations
6. **Provide feedback** - Show loading indicators during operations
7. **Cache content** - Consider saving drafts locally

---

## Support & Issues

- **GitHub Issues:** https://github.com/sumantalive/rich_text_editor/issues
- **Documentation:** https://github.com/sumantalive/rich_text_editor
- **Examples:** Check the `/example` directory in the repository

---

For detailed customization, see [CUSTOMIZATION.md](CUSTOMIZATION.md).
