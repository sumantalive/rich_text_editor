# Import Issues - Quick Fix Guide

## Problem
When you import the rich_text_editor package into another project, you get errors like:
- ❌ "Cannot find symbol 'ComposeScreen'"
- ❌ "Package import not found"
- ❌ "Undefined class 'RichTextEditorConfig'"

## Solution

### Step 1: Correct Import Statement
Use **ONLY** this import:
```dart
import 'package:rich_text_editor/rich_text_editor.dart';
```

### ❌ DO NOT use these:
```dart
// WRONG - Don't import from src/
import 'package:rich_text_editor/src/widgets/compose_screen.dart';
import 'package:rich_text_editor/src/config/editor_config.dart';
import 'package:rich_text_editor/src/controllers/rich_text_controller.dart';

// WRONG - typo or wrong path
import 'package:rich_text_editor/widgets/compose_screen.dart';
import 'package:rich_texteditor/rich_text_editor.dart';  // missing underscore
```

### ✅ DO use this:
```dart
import 'package:rich_text_editor/rich_text_editor.dart';
```

---

## Step 2: Rebuild Your Project

After fixing the import, run:

```bash
# Clean the project
flutter clean

# Get dependencies
flutter pub get

# Run the app
flutter run
```

---

## Step 3: Check pubspec.yaml

Ensure your `pubspec.yaml` has the package listed correctly:

```yaml
dependencies:
  flutter:
    sdk: flutter
  rich_text_editor: ^1.0.0  # Add this line
```

Then run:
```bash
flutter pub get
```

---

## Complete Working Example

Here's a minimal example that works:

```dart
import 'package:flutter/material.dart';
import 'package:rich_text_editor/rich_text_editor.dart';  // ✅ ONLY this import

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rich Text Editor Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rich Text Editor'),
      ),
      body: ComposeScreen(  // ✅ Now available through main import
        config: const RichTextEditorConfig(  // ✅ Also available
          title: 'My Note',
          enableImageUpload: true,
          enableExport: true,
        ),
      ),
    );
  }
}
```

---

## What's Now Exported

After the fix, you can use these classes directly:

```dart
import 'package:rich_text_editor/rich_text_editor.dart';

// Now you can use:
ComposeScreen()              // ✅ Full featured editor screen
RichTextEditor()             // ✅ Embedded editor widget
RichTextEditorConfig()       // ✅ Configuration
RichTextController()         // ✅ State controller
RichTextEditorConfig()       // ✅ Configuration class
ImageData()                  // ✅ Image model
SpanData()                   // ✅ Text span model
HtmlConverter()              // ✅ HTML utility
UndoRedoService()            // ✅ Undo/Redo service
```

---

## Common Mistakes & Fixes

### ❌ Mistake 1: Using src/ imports
```dart
// WRONG
import 'package:rich_text_editor/src/widgets/compose_screen.dart';
```
✅ Fix:
```dart
import 'package:rich_text_editor/rich_text_editor.dart';
```

---

### ❌ Mistake 2: Typo in package name
```dart
// WRONG - missing underscore
import 'package:richtexteditor/rich_text_editor.dart';
```
✅ Fix:
```dart
// RIGHT - correct package name
import 'package:rich_text_editor/rich_text_editor.dart';
```

---

### ❌ Mistake 3: Wrong path
```dart
// WRONG - trying to import widgets directly
import 'package:rich_text_editor/widgets/compose_screen.dart';
```
✅ Fix:
```dart
// RIGHT - use the main package import
import 'package:rich_text_editor/rich_text_editor.dart';
```

---

### ❌ Mistake 4: Old pubspec.yaml
If you added this before the fix:
```yaml
dependencies:
  rich_text_editor:
    git:
      url: https://github.com/sumantalive/rich_text_editor.git
      ref: old-branch
```

✅ Update to:
```yaml
dependencies:
  rich_text_editor: ^1.0.0
```

Or if using latest from git:
```yaml
dependencies:
  rich_text_editor:
    git:
      url: https://github.com/sumantalive/rich_text_editor.git
      ref: main  # or latest tag
```

---

## Verify It Works

Create a simple test file:

```dart
import 'package:flutter/material.dart';
import 'package:rich_text_editor/rich_text_editor.dart';

class TestImports extends StatelessWidget {
  const TestImports({super.key});

  @override
  Widget build(BuildContext context) {
    // If these compile without errors, imports are working
    final config = RichTextEditorConfig();
    final controller = RichTextController();
    
    return const ComposeScreen();  // Should compile without error
  }
}
```

If this compiles, your imports are fixed! ✅

---

## Still Having Issues?

### Check Flutter Version
```bash
flutter --version
```
Requires: Flutter 3.0+

### Regenerate Android/iOS
```bash
flutter pub get
flutter clean
flutter pub get
```

### Clear Pub Cache
```bash
flutter pub cache clean
flutter pub get
```

### Check for Typos
- Package name: `rich_text_editor` (with underscores)
- Import path: `package:rich_text_editor/rich_text_editor.dart`

### Invalidate Caches (if using IDE)
- **Android Studio/IntelliJ:** File → Invalidate Caches → Invalidate and Restart
- **VS Code:** Reload window (Ctrl+Shift+P → Reload Window)

---

## Summary

| What | Before Fix | After Fix |
|------|-----------|-----------|
| Import Statement | Multiple imports needed | Single import |
| ComposeScreen | ❌ Not exported | ✅ Directly available |
| Classes | Had to import from src/ | All exported from main |
| Complexity | High | Low |

**TL;DR:** Use only `import 'package:rich_text_editor/rich_text_editor.dart';` and everything works! ✅

---

For more examples, see [USAGE_GUIDE.md](USAGE_GUIDE.md)
