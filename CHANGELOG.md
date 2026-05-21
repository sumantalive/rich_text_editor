# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-05-21

### Added
- Initial release of Rich Text Editor package
- Rich text formatting support (bold, italic, underline, strikethrough)
- Text color and background highlight customization
- Font size and font family selection
- Text alignment support (left, center, right, justify)
- Image insertion and management with URL support
- Image hyperlinks support
- Image drag and reorder functionality
- HTML export functionality with full formatting preservation
- HTML import with comprehensive parsing
- Undo/redo support with full state management
- Save/load functionality with local storage persistence
- Highly customizable configuration system
- Dark theme support
- Customizable UI colors and styling
- Feature enable/disable configuration
- Callbacks for save and load events
- Complete example app with multiple theme presets

### Features
- **RichTextEditor**: Main widget for easy integration
- **RichTextEditorConfig**: Comprehensive configuration object
- **RichTextController**: Low-level controller for advanced usage
- **HtmlConverter**: HTML export/import with advanced parsing
- **SpanData**: Formatting span data model
- **ImageData**: Image data model with link support
- **UndoRedoService**: Full undo/redo state management
- **FormattingToolbar**: Customizable formatting toolbar
- **ColorPalette**: Color selection widget
- **ImagePreviewDialog**: Image preview with link management
- **HtmlImportDialog**: Dialog for pasting HTML content

### Architecture
- Clean separation of concerns with src/ structure
- Public API exports via main package file
- Well-documented configuration system
- Example app demonstrating all features

## [Unreleased]

### Planned Features
- Markdown export/import
- PDF export functionality
- Custom font support
- Link detection and auto-linking
- Table support
- Code block syntax highlighting
- Collaborative editing support
