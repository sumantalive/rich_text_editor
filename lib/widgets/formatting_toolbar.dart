import 'package:flutter/material.dart';
import '../controllers/rich_text_controller.dart';
import 'color_palette.dart';
import 'custom_dropdown.dart';

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

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    widget.focusNode?.removeListener(_onFocusChanged);
    _currentFormattingNotifier.dispose();
    _currentAlignmentNotifier.dispose();
    super.dispose();
  }

  void _applyFormatting(TextFormatting formatting) {
    final selection = widget.controller.selection;

    if (selection.start < selection.end) {
      // Apply to selected text
      widget.controller.applyToSelection(formatting, explicitSelection: selection);
      // Restore selection after formatting
      Future.microtask(() {
        widget.controller.selection = selection;
      });
    } else {
      // No selection - set active formatting
      widget.controller.setActiveFormatting(formatting);
    }

    _currentFormattingNotifier.value = formatting;

    widget.focusNode?.requestFocus();
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
    final formatting = isBackground
        ? TextFormatting(highlightColor: color)
        : TextFormatting(textColor: color);

    widget.controller.applyPropertyToSelection(formatting);
    _updateFormattingFromCursor();
  }

  void _changeFontSize(double size) {
    final formatting = TextFormatting(fontSize: size);
    widget.controller.applyPropertyToSelection(formatting);
    _updateFormattingFromCursor();
  }

  void _changeFontFamily(String family) {
    final formatting = TextFormatting(fontFamily: family);
    widget.controller.applyPropertyToSelection(formatting);
    _updateFormattingFromCursor();
  }

  void _toggleBold() {
    widget.controller.togglePropertyInSelection('bold');
    _updateFormattingFromCursor();
  }

  void _toggleItalic() {
    widget.controller.togglePropertyInSelection('italic');
    _updateFormattingFromCursor();
  }

  void _toggleUnderline() {
    widget.controller.togglePropertyInSelection('underline');
    _updateFormattingFromCursor();
  }

  void _toggleStrikethrough() {
    widget.controller.togglePropertyInSelection('strikethrough');
    _updateFormattingFromCursor();
  }

  void _changeAlignment(String newAlignment) {
    final text = widget.controller.text;
    final selection = widget.controller.selection;
    int applyStart = selection.start;
    int applyEnd = selection.end;

    if (applyStart >= applyEnd) {
      applyStart = 0;
      applyEnd = text.length;

      for (int i = selection.start - 1; i >= 0; i--) {
        if (text[i] == '\n') {
          applyStart = i + 1;
          break;
        }
      }

      for (int i = selection.start; i < text.length; i++) {
        if (text[i] == '\n') {
          applyEnd = i;
          break;
        }
      }

      widget.controller.selection = TextSelection(baseOffset: applyStart, extentOffset: applyEnd);
    }

    final currentFormatting = widget.controller.getFormattingAt(applyStart);

    final formatting = TextFormatting(
      bold: currentFormatting.bold,
      italic: currentFormatting.italic,
      underline: currentFormatting.underline,
      strikethrough: currentFormatting.strikethrough,
      textColor: currentFormatting.textColor,
      highlightColor: currentFormatting.highlightColor,
      fontSize: currentFormatting.fontSize,
      fontFamily: currentFormatting.fontFamily,
      alignment: newAlignment,
    );

    _applyFormatting(formatting);
    _currentAlignmentNotifier.value = newAlignment;
    widget.onAlignmentChanged?.call(newAlignment);
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
              color: Colors.grey[100],
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
        color: isActive ? Colors.blue : Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey),
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
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Material(
        color: Colors.white,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(4),
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
        border: Border.all(color: Colors.grey),
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
