# Rich Text Editor - Example App

This is a complete example app demonstrating all features and customization options of the Rich Text Editor package.

## Running the Example

From this directory, run:

```bash
flutter run
```

Or run on web:

```bash
flutter run -d chrome
```

## What's Included

This example app showcases:

1. **Default Configuration** - Out-of-the-box setup with all features enabled
2. **Minimal Configuration** - Stripped-down version with limited features
3. **Professional Theme** - Dark purple theme for a professional look
4. **Dark Mode** - Dark theme with white text for low-light environments

## Features Demonstrated

### Text Formatting
- Apply bold, italic, underline, and strikethrough formatting
- Change text color with color picker
- Apply background highlight color
- Adjust font size
- Select different font families
- Align text (left, center, right, justify)

### Images
- Insert images by URL
- Preview images with preview dialog
- Add hyperlinks to images
- Reorder images by dragging
- Remove images

### HTML
- Export formatted content as HTML
- Import HTML by pasting code
- Preserve all formatting during export/import

### Persistence
- Save content to device storage
- Load previously saved content
- Automatic state management

### Undo/Redo
- Undo recent changes
- Redo undone changes
- Full state tracking

## Code Examples

### Basic Usage

```dart
import 'package:rich_text_editor/rich_text_editor.dart';

RichTextEditor(
  config: const RichTextEditorConfig(
    title: 'My Editor',
  ),
)
```

### Custom Colors

```dart
RichTextEditor(
  config: RichTextEditorConfig(
    title: 'Custom Themed Editor',
    appBarColor: Colors.deepPurple,
    buttonColor: Colors.deepPurple,
    textColor: Colors.white,
  ),
)
```

### Feature Control

```dart
RichTextEditor(
  config: RichTextEditorConfig(
    title: 'Limited Features',
    enableImageUpload: false,
    enableHtmlImport: false,
    enableUndoRedo: false,
  ),
)
```

### With Callbacks

```dart
RichTextEditor(
  config: const RichTextEditorConfig(),
  onSave: () {
    print('Content saved!');
    // Handle save on your backend
  },
  onLoad: () {
    print('Content loaded!');
    // Refresh UI if needed
  },
)
```

## Configuration Options

See the main [README.md](../README.md) for a complete list of configuration options.

## Key Features to Test

1. **Text Formatting**
   - Select text and apply formatting from toolbar
   - Observe formatting applied correctly
   - Undo/redo formatting changes

2. **Colors**
   - Apply text color using color palette
   - Apply background highlight
   - Change color of existing text

3. **Images**
   - Add image by entering URL (https://via.placeholder.com/200)
   - Reorder images by dragging
   - Add link to image
   - Preview image

4. **HTML Import/Export**
   - Export current content as HTML
   - Copy HTML to clipboard
   - Import HTML by pasting in dialog
   - Verify all formatting preserved

5. **Save/Load**
   - Write some content with formatting
   - Click Save
   - Clear content or restart app
   - Click Load to restore

6. **Theme Switching**
   - Switch between different configuration presets
   - Verify colors and styling update correctly
   - Test with minimal configuration

## Development Notes

- The example uses `StatefulWidget` to manage configuration state
- Multiple `RichTextEditor` instances can have different `storageKey` values
- All features are enabled by default for demonstration
- The toolbar automatically hides/shows based on configuration

## Troubleshooting

**Images not loading:**
- Ensure the image URL is valid and HTTPS
- Check the image format is supported (PNG, JPG, GIF, WebP)

**HTML import not working:**
- Ensure HTML is properly formatted
- Complex HTML might need simplification
- Check browser console for parsing errors

**Save/Load not working:**
- Verify device has storage permission
- Check `storageKey` is unique if using multiple editors
- Clear app data and try again

## Next Steps

After exploring this example:

1. Read the main [README.md](../README.md)
2. Review the [API documentation](../README.md#configuration-options)
3. Integrate into your own Flutter app
4. Customize configuration for your needs
5. Implement backend persistence if needed

## Support

For issues or questions:
- Check the [README.md](../README.md)
- Review the source code in `lib/src/`
- Test with the example configurations

---

Happy editing! 📝✨
