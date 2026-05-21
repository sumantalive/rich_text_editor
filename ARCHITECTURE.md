# Rich Text Editor - Architecture Guide

This document explains the architecture and structure of the Rich Text Editor package.

## Project Structure

```
lib/
├── src/
│   ├── config/
│   │   └── editor_config.dart          # Configuration management
│   ├── controllers/
│   │   └── rich_text_controller.dart   # Text and formatting control
│   ├── models/
│   │   ├── span_data_model.dart        # Formatting span data
│   │   └── image_model.dart            # Image data model
│   ├── services/
│   │   ├── html_converter.dart         # HTML import/export
│   │   └── undo_redo_service.dart      # State management
│   └── widgets/
│       ├── rich_text_editor.dart       # Main public widget
│       ├── compose_screen.dart         # Editor UI
│       ├── formatting_toolbar.dart     # Formatting controls
│       ├── color_palette.dart          # Color picker
│       ├── custom_button.dart          # Reusable button
│       ├── custom_dropdown.dart        # Dropdown widget
│       ├── html_import_dialog.dart     # HTML import UI
│       ├── image_preview_dialog.dart   # Image preview
│       ├── image_link_dialog.dart      # Image link dialog
│       ├── image_url_dialog.dart       # Image URL input
│       └── image_link_dialog.dart      # Additional image dialog
└── rich_text_editor.dart               # Public API exports

example/
├── lib/
│   └── main.dart                       # Example app
└── pubspec.yaml                        # Example app dependencies

test/
└── widget_test.dart                    # Package tests
```

## Core Components

### 1. Configuration Layer (`src/config/`)

**RichTextEditorConfig**
- Immutable configuration object
- Enables/disables features
- Customizes colors and styling
- Provides sensible defaults
- `copyWith()` for creating variants

### 2. Data Models (`src/models/`)

**SpanData**
- Represents formatted text ranges
- Immutable with `copyWith()`
- Fields: start, end, bold, italic, underline, strikethrough, color, fontSize, etc.
- JSON serialization support

**ImageData**
- Represents images in the editor
- Stores URL and optional link
- Unique ID for tracking
- JSON serialization support

### 3. Controllers (`src/controllers/`)

**RichTextController** (extends `TextEditingController`)
- Manages text content
- Tracks formatting spans
- Manages images
- Handles span merging and splitting
- Auto-applies active formatting to new text
- Provides methods for formatting operations

**TextFormatting**
- Encapsulates formatting properties
- Converts to Flutter `TextStyle`
- `copyWith()` for creating variants

### 4. Services (`src/services/`)

**HtmlConverter**
- Exports formatted text to HTML
- Imports HTML with full parsing
- Parses colors, fonts, alignment
- Extracts images and links
- Returns structured `HtmlImportData`

**UndoRedoService**
- Maintains state history stack
- Supports undo/redo operations
- Tracks `EditorState` objects
- Provides `canUndo`/`canRedo` status

### 5. Widgets (`src/widgets/`)

**RichTextEditor** (Public)
- Main entry point for package users
- Wraps ComposeScreen
- Accepts config and callbacks
- Simple, clean API

**ComposeScreen** (Internal)
- Main editor UI
- Manages state (controller, alignment, etc.)
- Handles save/load functionality
- Displays toolbar and text area
- Manages dialogs for import/export

**FormattingToolbar**
- Displays formatting buttons
- Color picker
- Font selection
- Text alignment
- Undo/redo buttons

**Supporting Widgets**
- ColorPalette: Color selection
- CustomButton: Styled buttons
- CustomDropdown: Dropdown widget
- HtmlImportDialog: Paste HTML
- ImagePreviewDialog: Preview images
- ImageLinkDialog: Add image links
- ImageUrlDialog: Enter image URLs

## Data Flow

### Text Editing Flow

```
User Input
    ↓
RichTextController.value setter
    ↓
Span adjustment (insertion/deletion)
    ↓
Active formatting applied to new text
    ↓
State saved to UndoRedoService
    ↓
Listeners notified
    ↓
UI rebuilds
```

### Formatting Application Flow

```
User selects text and applies formatting
    ↓
RichTextController.applyToSelection()
    ↓
Span splitting/merging logic
    ↓
New formatted spans created
    ↓
State saved to UndoRedoService
    ↓
Controller listeners notified
    ↓
UI rebuilds with new formatting
```

### HTML Export Flow

```
User clicks Export
    ↓
HtmlConverter.toHtml() called with:
  - text content
  - span data
  - image data
  - alignment
    ↓
Converts each span to HTML tags and styles
    ↓
Wraps in div with alignment
    ↓
Adds images with optional links
    ↓
Returns complete HTML string
    ↓
Displayed in dialog with copy option
```

### HTML Import Flow

```
User opens Import dialog
    ↓
Pastes HTML code
    ↓
HtmlConverter.parseHtmlFull() called
    ↓
HTML parser processes document:
  - Extracts text content
  - Identifies formatting tags
  - Parses inline styles
  - Extracts images
  - Detects text alignment
    ↓
Returns HtmlImportData with:
  - Plain text
  - SpanData list
  - ImageData list
  - Alignment
    ↓
ComposeScreen loads data into controller
    ↓
UI updates with imported content
```

## State Management

### EditorState
Immutable object containing:
- Text content
- Formatting spans
- Images
- Text alignment
- Timestamp

Used by UndoRedoService to track history.

### ValueNotifiers

```
_textAlignmentNotifier      - Current alignment
_canUndoNotifier            - Can undo?
_canRedoNotifier            - Can redo?
_imagesNotifier             - Current images list
```

These trigger UI rebuilds when values change.

## Key Design Patterns

### 1. Immutability
- SpanData, ImageData use `final` properties
- Use `copyWith()` to create variants
- Immutable configuration object
- Prevents accidental state mutations

### 2. Separation of Concerns
- Config: Customization
- Models: Data
- Controllers: Business logic
- Services: Utilities
- Widgets: UI

### 3. Composition
- Widgets compose smaller widgets
- Easy to replace or modify components
- Clear dependency flow

### 4. Listener Pattern
- RichTextController extends TextEditingController
- Listeners notified of changes
- UI rebuilds automatically

### 5. Extension Methods
- SpanData extension on toTextStyle()
- TextFormatting class for formatting objects
- Clean separation of concerns

## Important Algorithms

### Span Splitting and Merging

When text is edited:
1. Find spans that overlap with edited region
2. Split overlapping spans at boundaries
3. Remove spans completely within deleted region
4. Adjust offsets of spans after deletion
5. Merge spans with same properties

### Formatting Application

When user applies formatting to selection:
1. Find all spans overlapping selection
2. Split spans at selection boundaries
3. Apply formatting to overlapping portions
4. Merge spans with same properties
5. Fill gaps in unformatted regions

### Color Extraction from HTML

1. Extract CSS properties from style attribute
2. Use regex with negative lookbehind to avoid matching `background-color` when looking for `color`
3. Parse hex (#RRGGBB or #AARRGGBB) or rgb() format
4. Convert to ARGB integer format

## Extension Points

### Custom Formatting

Add new formatting type:
1. Add property to SpanData
2. Update TextFormatting class
3. Add button to FormattingToolbar
4. Update applyToSelection() logic
5. Update HTML converter

### Custom Widget

Replace ComposeScreen:
1. Create new widget extending StatefulWidget
2. Use RichTextController for text management
3. Implement same callback signatures
4. Update RichTextEditor to use new widget

### Custom HTML Parsing

Extend HtmlConverter:
1. Override parseHtmlFull()
2. Implement custom HTML parsing logic
3. Return HtmlImportData with parsed content

## Performance Considerations

### Span Management
- Spans are stored in a sorted list
- O(n) to find overlapping spans
- Consider segmentation tree for large documents

### Text Rendering
- Flutter rebuilds TextSpan only when needed
- ValueNotifiers prevent unnecessary rebuilds
- Consider virtual scrolling for very long documents

### HTML Parsing
- HTML parser creates DOM tree
- Single pass extraction to HtmlImportData
- Consider caching for repeated imports

## Testing Strategy

### Unit Tests
- Test SpanData immutability
- Test span merging logic
- Test HTML parsing
- Test color conversion

### Widget Tests
- Test UI rendering
- Test user interactions
- Test state updates

### Integration Tests
- Test complete editing workflows
- Test save/load functionality
- Test HTML export/import round trip

## Future Improvements

1. **Performance**: Implement segmentation tree for span management
2. **Features**: Add markdown support, tables, links
3. **Customization**: Plugin system for custom formatting
4. **Testing**: Increase test coverage to 90%+
5. **Documentation**: Add inline code comments
6. **Accessibility**: Implement full a11y support

## Contributing Guidelines

When adding new features:
1. Follow the existing structure
2. Keep components focused and small
3. Use immutable data models
4. Add comprehensive tests
5. Update documentation
6. Follow Flutter best practices

---

For more details, review the source code with comments and inline documentation.
