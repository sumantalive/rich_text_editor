import 'package:flutter/material.dart';

class RichTextEditorConfig {
  /// AppBar title
  final String title;

  /// AppBar background color
  final Color appBarColor;

  /// Text input hint
  final String hintText;

  /// Enable/disable features
  final bool enableExport;
  final bool enableImport;
  final bool enableSave;
  final bool enableLoad;
  final bool enableImageUpload;
  final bool enableHtmlImport;
  final bool enableUndoRedo;

  /// Button styling
  final Color buttonColor;
  final Color buttonTextColor;
  final double buttonSize;

  /// Text input styling
  final double defaultFontSize;
  final Color textColor;
  final TextInputAction textInputAction;
  final TextCapitalization textCapitalization;

  /// Toolbar styling
  final Color toolbarBackgroundColor;
  final double toolbarHeight;
  final bool showToolbar;

  /// Highlight color opacity (0.0 - 1.0)
  final double highlightOpacity;

  /// Storage key for save/load
  final String storageKey;

  const RichTextEditorConfig({
    this.title = 'Text Editor',
    this.appBarColor = Colors.blue,
    this.hintText = 'Write message...',
    this.enableExport = true,
    this.enableImport = true,
    this.enableSave = true,
    this.enableLoad = true,
    this.enableImageUpload = true,
    this.enableHtmlImport = true,
    this.enableUndoRedo = true,
    this.buttonColor = Colors.blue,
    this.buttonTextColor = Colors.white,
    this.buttonSize = 14.0,
    this.defaultFontSize = 14.0,
    this.textColor = Colors.black,
    this.textInputAction = TextInputAction.newline,
    this.textCapitalization = TextCapitalization.sentences,
    this.toolbarBackgroundColor = Colors.white,
    this.toolbarHeight = 60.0,
    this.showToolbar = true,
    this.highlightOpacity = 0.4,
    this.storageKey = 'rich_text_editor_data',
  });

  RichTextEditorConfig copyWith({
    String? title,
    Color? appBarColor,
    String? hintText,
    bool? enableExport,
    bool? enableImport,
    bool? enableSave,
    bool? enableLoad,
    bool? enableImageUpload,
    bool? enableHtmlImport,
    bool? enableUndoRedo,
    Color? buttonColor,
    Color? buttonTextColor,
    double? buttonSize,
    double? defaultFontSize,
    Color? textColor,
    TextInputAction? textInputAction,
    TextCapitalization? textCapitalization,
    Color? toolbarBackgroundColor,
    double? toolbarHeight,
    bool? showToolbar,
    double? highlightOpacity,
    String? storageKey,
  }) {
    return RichTextEditorConfig(
      title: title ?? this.title,
      appBarColor: appBarColor ?? this.appBarColor,
      hintText: hintText ?? this.hintText,
      enableExport: enableExport ?? this.enableExport,
      enableImport: enableImport ?? this.enableImport,
      enableSave: enableSave ?? this.enableSave,
      enableLoad: enableLoad ?? this.enableLoad,
      enableImageUpload: enableImageUpload ?? this.enableImageUpload,
      enableHtmlImport: enableHtmlImport ?? this.enableHtmlImport,
      enableUndoRedo: enableUndoRedo ?? this.enableUndoRedo,
      buttonColor: buttonColor ?? this.buttonColor,
      buttonTextColor: buttonTextColor ?? this.buttonTextColor,
      buttonSize: buttonSize ?? this.buttonSize,
      defaultFontSize: defaultFontSize ?? this.defaultFontSize,
      textColor: textColor ?? this.textColor,
      textInputAction: textInputAction ?? this.textInputAction,
      textCapitalization: textCapitalization ?? this.textCapitalization,
      toolbarBackgroundColor: toolbarBackgroundColor ?? this.toolbarBackgroundColor,
      toolbarHeight: toolbarHeight ?? this.toolbarHeight,
      showToolbar: showToolbar ?? this.showToolbar,
      highlightOpacity: highlightOpacity ?? this.highlightOpacity,
      storageKey: storageKey ?? this.storageKey,
    );
  }
}
