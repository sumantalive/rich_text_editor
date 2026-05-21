import 'package:flutter/material.dart';

class ColorPalette extends StatelessWidget {
  final Function(int) onColorSelected;
  final int currentColor;

  static const List<int> colors = [
    // Grays
    0xFF000000, 0xFF333333, 0xFF666666, 0xFF999999, 0xFFCCCCCC, 0xFFFFFFFF,
    // Reds
    0xFFFFCDD2, 0xFFEF9A9A, 0xFFE57373, 0xFFEF5350, 0xFFF44336, 0xFFE53935,
    // Oranges
    0xFFFFE0B2, 0xFFFFCC80, 0xFFFFB74D, 0xFFFFA726, 0xFFFF9800, 0xFFF57C00,
    // Yellows
    0xFFFFF9C4, 0xFFFFF59D, 0xFFFFF176, 0xFFFFEE58, 0xFFFFEB3B, 0xFFFDD835,
    // Greens
    0xFFC8E6C9, 0xFFA5D6A7, 0xFF81C784, 0xFF66BB6A, 0xFF4CAF50, 0xFF43A047,
    // Teals
    0xFFB2DFDB, 0xFF80CBC4, 0xFF4DB6AC, 0xFF26A69A, 0xFF009688, 0xFF00897B,
    // Cyans
    0xFFB2EBF2, 0xFF80DEEA, 0xFF4DD0E1, 0xFF26C6DA, 0xFF00BCD4, 0xFF0097A7,
    // Blues
    0xFFBBDEFB, 0xFF90CAF9, 0xFF64B5F6, 0xFF42A5F5, 0xFF2196F3, 0xFF1976D2,
    // Indigos
    0xFFC5CAE9, 0xFFA1B3E5, 0xFF7986CB, 0xFF5E35B1, 0xFF3F51B5, 0xFF3949AB,
    // Purples
    0xFFE1BEE7, 0xFFCE93D8, 0xFFBA68C8, 0xFFAB47BC, 0xFF9C27B0, 0xFF8E24AA,
    // Pinks
    0xFFF8BBD0, 0xFFF48FB1, 0xFFF06292, 0xFFEC407A, 0xFFE91E63, 0xFFC2185B,
    // Browns
    0xFFD7CCC8, 0xFFBCAAA4, 0xFFA1887F, 0xFF795548, 0xFF6D4C41, 0xFF5D4037,
  ];

  const ColorPalette({
    super.key,
    required this.onColorSelected,
    this.currentColor = 0xFF000000,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 6,
      shrinkWrap: true,
      padding: const EdgeInsets.all(8),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: colors.map((color) {
        return GestureDetector(
          onTap: () {
            onColorSelected(color);
          },
          child: Container(
            decoration: BoxDecoration(
              color: Color(color),
              border: Border.all(
                color: currentColor == color ? Colors.black : Colors.grey,
                width: currentColor == color ? 3 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: currentColor == color
                ? const Icon(Icons.check, color: Colors.white)
                : null,
          ),
        );
      }).toList(),
    );
  }
}
