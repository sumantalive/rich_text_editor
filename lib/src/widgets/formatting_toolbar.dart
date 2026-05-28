import 'package:flutter/material.dart';
import '../controllers/rich_text_controller.dart';
import 'color_palette.dart';
import 'custom_dropdown.dart';
import 'image_link_dialog.dart';

class FormattingToolbar extends StatefulWidget {
  final RichTextController controller;
  final ValueChanged<String>? onAlignmentChanged;
  final String initialAlignment;
  final ValueChanged<TextEditingValue>? onSelectionChanged;
  final FocusNode? focusNode;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final bool canUndo;
  final bool canRedo;
  final void Function()? onImageAdded;

  /// Returns the controller toolbar actions should write to, resolved at the
  /// moment of the action. The block editor host uses this to always target
  /// the currently focused block: between the user tapping into a different
  /// block and the parent rebuilding the toolbar with a fresh [controller],
  /// there is a brief frame where [controller] still points at the previously
  /// active block — without this hook, bold/link/etc. land on the wrong
  /// paragraph during that window. Falls back to [controller] when not
  /// provided so standalone uses of the toolbar are unaffected.
  final RichTextController Function()? resolveActiveController;

  const FormattingToolbar({
    super.key,
    required this.controller,
    this.onAlignmentChanged,
    this.onSelectionChanged,
    this.focusNode,
    this.initialAlignment = 'left',
    this.onUndo,
    this.onRedo,
    this.canUndo = false,
    this.canRedo = false,
    this.onImageAdded,
    this.resolveActiveController,
  });

  @override
  State<FormattingToolbar> createState() => _FormattingToolbarState();
}

class _FormattingToolbarState extends State<FormattingToolbar> {
  late ValueNotifier<TextFormatting> _currentFormattingNotifier;
  late ValueNotifier<String> _currentAlignmentNotifier;
  late TextEditingValue _lastValue;

  @override
  void initState() {
    super.initState();
    _lastValue = widget.controller.value;
    final formatting = widget.controller.getFormattingAt(
      widget.controller.selection.start,
    );
    _currentFormattingNotifier = ValueNotifier<TextFormatting>(formatting);
    _currentAlignmentNotifier = ValueNotifier<String>(widget.initialAlignment);
    widget.controller.addListener(_onControllerChanged);
    widget.focusNode?.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    _updateFormattingFromCursor();
  }

  void _updateFormattingFromCursor() {
    final formatting = widget.controller.getFormattingAt(
      widget.controller.selection.start,
    );
    _currentFormattingNotifier.value = formatting;
    // Alignment is already maintained by _currentAlignmentNotifier
    // No need to update from cursor position
  }

  void _onControllerChanged() {
    final currentValue = widget.controller.value;

    if (_lastValue.selection != currentValue.selection) {
      widget.onSelectionChanged?.call(currentValue);
      _updateFormattingFromCursor();
    }
    _lastValue = currentValue;

    _updateFormattingFromCursor();
  }

  /// The controller a toolbar action should target. Resolved at action time
  /// (not at widget-build time) so we always hit the field the user is
  /// currently editing, even if [widget.controller] still points at the
  /// previously active block because the parent hasn't rebuilt yet.
  RichTextController get _actionController =>
      widget.resolveActiveController?.call() ?? widget.controller;

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    widget.focusNode?.removeListener(_onFocusChanged);
    _currentFormattingNotifier.dispose();
    _currentAlignmentNotifier.dispose();
    super.dispose();
  }


  void _showColorPicker(bool isBackground, BuildContext buttonContext) {
    final RenderBox renderBox = buttonContext.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final current = _currentFormattingNotifier.value;

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (dialogContext) => Stack(
        children: [
          Positioned(
            left: offset.dx,
            top: offset.dy + renderBox.size.height + 8,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 300,
                constraints: const BoxConstraints(maxHeight: 350),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SingleChildScrollView(
                  child: ColorPalette(
                    onColorSelected: (color) {
                      Navigator.pop(dialogContext);
                      _applyColor(color, isBackground);
                    },
                    currentColor: isBackground ? (current.highlightColor ?? 0xFFFFFF00) : current.textColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _applyColor(int color, bool isBackground) {
    final controller = _actionController;
    final selection = controller.selection;
    final formatting = isBackground
        ? TextFormatting(highlightColor: color)
        : TextFormatting(textColor: color);

    if (selection.start < selection.end) {
      controller.applyPropertyToSelection(formatting);
      _updateFormattingFromCursor();
    } else {
      final newFormatting = isBackground
          ? controller.activeFormatting.copyWith(highlightColor: color)
          : controller.activeFormatting.copyWith(textColor: color);
      controller.setActiveFormatting(newFormatting);
      _currentFormattingNotifier.value = newFormatting;
    }
  }

  void _changeFontSize(double size) {
    final controller = _actionController;
    final selection = controller.selection;
    if (selection.start < selection.end) {
      final formatting = TextFormatting(fontSize: size);
      controller.applyPropertyToSelection(formatting);
      _updateFormattingFromCursor();
    } else {
      final newFormatting = controller.activeFormatting.copyWith(fontSize: size);
      controller.setActiveFormatting(newFormatting);
      _currentFormattingNotifier.value = newFormatting;
    }
  }

  void _changeFontFamily(String family) {
    final controller = _actionController;
    final selection = controller.selection;
    if (selection.start < selection.end) {
      final formatting = TextFormatting(fontFamily: family);
      controller.applyPropertyToSelection(formatting);
      _updateFormattingFromCursor();
    } else {
      final newFormatting = controller.activeFormatting.copyWith(fontFamily: family);
      controller.setActiveFormatting(newFormatting);
      _currentFormattingNotifier.value = newFormatting;
    }
  }



  void _toggleBold() {
    final controller = _actionController;
    final selection = controller.selection;
    if (selection.start < selection.end) {
      controller.togglePropertyInSelection('bold');
      _updateFormattingFromCursor();
    } else {
      controller.toggleActiveFormatting('bold');
      _currentFormattingNotifier.value = controller.activeFormatting;
    }
  }

  void _toggleItalic() {
    final controller = _actionController;
    final selection = controller.selection;
    if (selection.start < selection.end) {
      controller.togglePropertyInSelection('italic');
      _updateFormattingFromCursor();
    } else {
      controller.toggleActiveFormatting('italic');
      _currentFormattingNotifier.value = controller.activeFormatting;
    }
  }

  void _toggleUnderline() {
    final controller = _actionController;
    final selection = controller.selection;
    if (selection.start < selection.end) {
      controller.togglePropertyInSelection('underline');
      _updateFormattingFromCursor();
    } else {
      controller.toggleActiveFormatting('underline');
      _currentFormattingNotifier.value = controller.activeFormatting;
    }
  }

  void _toggleStrikethrough() {
    final controller = _actionController;
    final selection = controller.selection;
    if (selection.start < selection.end) {
      controller.togglePropertyInSelection('strikethrough');
      _updateFormattingFromCursor();
    } else {
      controller.toggleActiveFormatting('strikethrough');
      _currentFormattingNotifier.value = controller.activeFormatting;
    }
  }

  /// Adds/edits a hyperlink. If an image is currently selected, the link is
  /// attached to that image; otherwise it is applied to the selected text.
  /// With nothing selected, prompts the user to select something first.
  void _editLink() {
    final controller = _actionController;
    final selectedImageId = controller.selectedImageId;

    if (selectedImageId != null) {
      _showLinkDialog(
        title: 'Add Image Link',
        description: 'Enter the URL this image should link to:',
        initialLink: controller.selectedImageLink,
        onSaved: (url) => controller.updateImageLink(selectedImageId, url),
      );
      return;
    }

    // Capture the selection now — showing the dialog moves focus and would
    // otherwise collapse it before the user confirms.
    final selection = controller.selection;
    if (selection.isValid && selection.start < selection.end) {
      _showLinkDialog(
        title: 'Add Link',
        description: 'Enter the URL for the selected text:',
        initialLink: controller.getFormattingAt(selection.start).linkUrl,
        onSaved: (url) {
          controller.setSelectionLink(url, explicitSelection: selection);
          _updateFormattingFromCursor();
        },
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.red,
        content: Text('Select some text or tap an image to add a link'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showLinkDialog({
    required String title,
    required String description,
    required String? initialLink,
    required ValueChanged<String?> onSaved,
  }) {
    showDialog(
      context: context,
      builder: (_) => ImageLinkDialog(
        title: title,
        description: description,
        initialLink: initialLink,
        onLinkSaved: onSaved,
      ),
    );
  }

  void _changeAlignment(String newAlignment) {
    // Alignment is a per-line (per-block) property in the block editor, so we
    // delegate to the host instead of writing it onto text spans.
    _currentAlignmentNotifier.value = newAlignment;
    widget.onAlignmentChanged?.call(newAlignment);
    widget.focusNode?.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextFormatting>(
      valueListenable: _currentFormattingNotifier,
      builder: (context, currentFormatting, _) {
        return ValueListenableBuilder<String>(
          valueListenable: _currentAlignmentNotifier,
          builder: (context, currentAlignment, _) {
            return Container(
              // color: Colors.grey[100],
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    CustomDropdown<String>(
                      value: currentFormatting.fontFamily,
                      width: 150,
                      items: [
                        CustomDropdownItem(value: 'default', label: 'Default'),
                        CustomDropdownItem(value: 'sans-serif', label: 'Sans Serif'),
                        CustomDropdownItem(value: 'serif', label: 'Serif'),
                        CustomDropdownItem(value: 'monospace', label: 'Fixed Width'),
                        CustomDropdownItem(value: 'wide', label: 'Wide'),
                        CustomDropdownItem(value: 'narrow', label: 'Narrow'),
                        CustomDropdownItem(value: 'comic-sans-ms', label: 'Comic Sans MS'),
                        CustomDropdownItem(value: 'garamond', label: 'Garamond'),
                        CustomDropdownItem(value: 'georgia', label: 'Georgia'),
                        CustomDropdownItem(value: 'tahoma', label: 'Tahoma'),
                        CustomDropdownItem(value: 'trebuchet-ms', label: 'Trebuchet MS'),
                        CustomDropdownItem(value: 'verdana', label: 'Verdana'),
                      ],
                      onChanged: _changeFontFamily,
                    ),
                    const SizedBox(width: 8),
                    CustomDropdown<double>(
                      value: currentFormatting.fontSize,
                      width: 80,
                      items: [
                        CustomDropdownItem(value: 10.0, label: '10'),
                        CustomDropdownItem(value: 12.0, label: '12'),
                        CustomDropdownItem(value: 14.0, label: '14'),
                        CustomDropdownItem(value: 16.0, label: '16'),
                        CustomDropdownItem(value: 18.0, label: '18'),
                        CustomDropdownItem(value: 20.0, label: '20'),
                        CustomDropdownItem(value: 24.0, label: '24'),
                        CustomDropdownItem(value: 28.0, label: '28'),
                      ],
                      onChanged: _changeFontSize,
                    ),
                    const SizedBox(width: 8),
                    _FormatButton(
                      icon: Icons.format_bold,
                      isActive: currentFormatting.bold,
                      onPressed: _toggleBold,
                    ),
                    _FormatButton(
                      icon: Icons.format_italic,
                      isActive: currentFormatting.italic,
                      onPressed: _toggleItalic,
                    ),
                    _FormatButton(
                      icon: Icons.format_underlined,
                      isActive: currentFormatting.underline,
                      onPressed: _toggleUnderline,
                    ),
                    _FormatButton(
                      icon: Icons.strikethrough_s,
                      isActive: currentFormatting.strikethrough,
                      onPressed: _toggleStrikethrough,
                    ),
                    _FormatButton(
                      icon: Icons.link,
                      isActive: currentFormatting.linkUrl != null,
                      onPressed: _editLink,
                    ),
                    const SizedBox(width: 8),
                    Builder(
                      builder: (buttonContext) => _ColorButton(
                        icon: Icons.text_fields,
                        color: Color(currentFormatting.textColor),
                        onPressed: () => _showColorPicker(false, buttonContext),
                      ),
                    ),
                    Builder(
                      builder: (buttonContext) => _ColorButton(
                        icon: Icons.highlight,
                        color: currentFormatting.highlightColor != null
                            ? Color(currentFormatting.highlightColor!)
                            : Colors.transparent,
                        onPressed: () => _showColorPicker(true, buttonContext),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _FormatButton(
                      icon: Icons.format_align_left,
                      isActive: currentAlignment == 'left',
                      onPressed: () => _changeAlignment('left'),
                    ),
                    _FormatButton(
                      icon: Icons.format_align_center,
                      isActive: currentAlignment == 'center',
                      onPressed: () => _changeAlignment('center'),
                    ),
                    _FormatButton(
                      icon: Icons.format_align_right,
                      isActive: currentAlignment == 'right',
                      onPressed: () => _changeAlignment('right'),
                    ),
                    _FormatButton(
                      icon: Icons.format_align_justify,
                      isActive: currentAlignment == 'justify',
                      onPressed: () => _changeAlignment('justify'),
                    ),
                    const SizedBox(width: 8),
                    if (widget.onImageAdded != null)
                      _FormatButton(
                        icon: Icons.image,
                        isActive: false,
                        onPressed: widget.onImageAdded
                      ),
                    const SizedBox(width: 8),
                    if (widget.onUndo != null)
                      _UndoRedoButton(
                        icon: Icons.undo,
                        isActive: widget.canUndo,
                        onPressed: widget.canUndo ? widget.onUndo! : null,
                      ),
                    if (widget.onRedo != null)
                      _UndoRedoButton(
                        icon: Icons.redo,
                        isActive: widget.canRedo,
                        onPressed: widget.canRedo ? widget.onRedo! : null,
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _FormatButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback? onPressed;

  const _FormatButton({
    required this.icon,
    required this.isActive,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: isActive ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.black),
      ),
      child: IconButton(
        icon: Icon(icon, color: isActive ? Colors.white : Colors.black),
        onPressed: onPressed,
        iconSize: 16,
        padding: const EdgeInsets.all(4),
        constraints: const BoxConstraints.tightFor(width: 32, height: 32),
      ),
    );
  }
}

class _ColorButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _ColorButton({
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Material(
        color: Colors.white,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, color: Colors.black, size: 16),
                Positioned(
                  bottom: 0,
                  child: Container(
                    width: 16,
                    height: 3,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UndoRedoButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback? onPressed;

  const _UndoRedoButton({
    required this.icon,
    required this.isActive,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        border: Border.all(color:Colors.black),
        borderRadius: BorderRadius.circular(4),
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: isActive ? Colors.black : Colors.grey,
        ),
        onPressed: onPressed,
        iconSize: 16,
        padding: const EdgeInsets.all(4),
        constraints: const BoxConstraints.tightFor(width: 32, height: 32),
      ),
    );
  }
}
