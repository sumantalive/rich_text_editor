import 'package:flutter/material.dart';
import '../models/image_model.dart';

class InlineImageWidget extends StatefulWidget {
  final ImageData image;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onDeselect;
  final Function(double width, double height) onResize;

  const InlineImageWidget({
    super.key,
    required this.image,
    required this.isSelected,
    required this.onSelect,
    required this.onDeselect,
    required this.onResize,
  });

  @override
  State<InlineImageWidget> createState() => _InlineImageWidgetState();
}

class _InlineImageWidgetState extends State<InlineImageWidget> {
  late double currentWidth;
  late double currentHeight;
  Offset? resizeStartOffset;
  late double resizeStartWidth;
  late double resizeStartHeight;

  @override
  void initState() {
    super.initState();
    currentWidth = widget.image.width;
    currentHeight = widget.image.height;
  }

  void _handleResizeStart(Offset globalPosition) {
    resizeStartOffset = globalPosition;
    resizeStartWidth = currentWidth;
    resizeStartHeight = currentHeight;
  }

  void _handleResizeUpdate(Offset globalPosition) {
    if (resizeStartOffset == null) return;

    final deltaX = globalPosition.dx - resizeStartOffset!.dx;

    final aspectRatio = resizeStartWidth / resizeStartHeight;

    final newWidth = (resizeStartWidth + deltaX).clamp(28.0, 200.0);
    final newHeight = newWidth / aspectRatio;

    setState(() {
      currentWidth = newWidth;
      currentHeight = newHeight.clamp(28.0, 200.0);
    });

    widget.onResize(currentWidth, currentHeight);
  }

  void _handleResizeEnd() {
    resizeStartOffset = null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isSelected ? widget.onDeselect : widget.onSelect,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                widget.image.imageUrl,
                height: currentHeight,
                width: currentWidth,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: currentHeight,
                    width: currentWidth,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Center(
                      child: Icon(Icons.image_not_supported, size: 16),
                    ),
                  );
                },
              ),
            ),
            if (widget.isSelected)
              Container(
                height: currentHeight,
                width: currentWidth,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue, width: 2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            if (widget.isSelected)
              Positioned(
                right: -8,
                bottom: -8,
                child: MouseRegion(
                  cursor: SystemMouseCursors.resizeDownRight,
                  child: GestureDetector(
                    onPanStart: (details) => _handleResizeStart(details.globalPosition),
                    onPanUpdate: (details) => _handleResizeUpdate(details.globalPosition),
                    onPanEnd: (_) => _handleResizeEnd(),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.zoom_out_map,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
