import 'package:flutter/material.dart';
import '../models/image_model.dart';

class InlineImageWidget extends StatefulWidget {
  final ImageData image;
  final bool isSelected;

  /// Largest width the image may take so it never overflows the editor field
  /// horizontally. The image's height grows with it and the surrounding text
  /// line grows to fit (the field grows vertically, like typing more text).
  final double maxWidth;
  final VoidCallback onSelect;
  final VoidCallback onDeselect;
  final Function(double width, double height) onResize;

  const InlineImageWidget({
    super.key,
    required this.image,
    required this.isSelected,
    this.maxWidth = double.infinity,
    required this.onSelect,
    required this.onDeselect,
    required this.onResize,
  });

  @override
  State<InlineImageWidget> createState() => _InlineImageWidgetState();
}

class _InlineImageWidgetState extends State<InlineImageWidget> {
  // Null until a concrete size is known (either stored or resolved from the
  // image's natural dimensions). No upper bound is enforced.
  static const double _minSize = 28.0;

  double? currentWidth;
  double? currentHeight;
  Offset? resizeStartOffset;
  late double resizeStartWidth;
  late double resizeStartHeight;

  ImageStream? _stream;
  ImageStreamListener? _streamListener;

  // Width available to the image itself, after this widget's own horizontal
  // padding (4 on each side). [maxWidth] is the editor field's content width.
  double get _effectiveMaxWidth =>
      widget.maxWidth.isFinite ? (widget.maxWidth - 8).clamp(_minSize, double.infinity) : double.infinity;

  @override
  void initState() {
    super.initState();
    if (!widget.image.needsNaturalSize) {
      currentWidth = widget.image.width;
      currentHeight = widget.image.height;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.image.needsNaturalSize && currentWidth == null) {
      // Resolve the real image dimensions once, when no size was provided.
      _resolveNaturalSize();
    } else if (currentWidth != null) {
      // Keep a stored/known size within the field width (e.g. after the field
      // is resized or on a narrower screen).
      _fitToFieldAndPersist(currentWidth!, currentHeight!);
    }
  }

  @override
  void didUpdateWidget(covariant InlineImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-fit if the editor field's available width changed.
    if (widget.maxWidth != oldWidget.maxWidth && currentWidth != null) {
      _fitToFieldAndPersist(currentWidth!, currentHeight!);
    }
  }

  /// Scales (w, h) down so the width fits [_effectiveMaxWidth], preserving the
  /// aspect ratio, then stores and persists it if it actually changed.
  void _fitToFieldAndPersist(double w, double h) {
    final maxW = _effectiveMaxWidth;
    var fittedW = w;
    var fittedH = h;
    if (maxW.isFinite && fittedW > maxW) {
      fittedH = fittedH * (maxW / fittedW);
      fittedW = maxW;
    }
    if ((fittedW - (currentWidth ?? -1)).abs() < 0.5 &&
        (fittedH - (currentHeight ?? -1)).abs() < 0.5) {
      return; // no meaningful change — avoid a notify/rebuild loop
    }
    setState(() {
      currentWidth = fittedW;
      currentHeight = fittedH;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onResize(fittedW, fittedH);
    });
  }

  void _resolveNaturalSize() {
    final stream = NetworkImage(widget.image.imageUrl)
        .resolve(const ImageConfiguration());
    final listener = ImageStreamListener(
      (info, _) {
        if (!mounted) return;
        // Use the image's real dimensions, only shrunk to fit the field width.
        _fitToFieldAndPersist(
          info.image.width.toDouble(),
          info.image.height.toDouble(),
        );
      },
      onError: (_, _) {
        if (!mounted) return;
        setState(() {
          currentWidth = 100;
          currentHeight = 100;
        });
      },
    );
    stream.addListener(listener);
    _stream = stream;
    _streamListener = listener;
  }

  @override
  void dispose() {
    if (_stream != null && _streamListener != null) {
      _stream!.removeListener(_streamListener!);
    }
    super.dispose();
  }

  void _handleResizeStart(Offset globalPosition) {
    resizeStartOffset = globalPosition;
    resizeStartWidth = currentWidth ?? _minSize;
    resizeStartHeight = currentHeight ?? _minSize;
  }

  void _handleResizeUpdate(Offset globalPosition) {
    if (resizeStartOffset == null) return;

    final deltaX = globalPosition.dx - resizeStartOffset!.dx;
    final aspectRatio = resizeStartWidth / resizeStartHeight;

    // Cap at the field width so the image can't overflow; preserve aspect ratio.
    final newWidth = (resizeStartWidth + deltaX).clamp(_minSize, _effectiveMaxWidth);
    final newHeight = newWidth / aspectRatio;

    setState(() {
      currentWidth = newWidth;
      currentHeight = newHeight;
    });

    widget.onResize(newWidth, newHeight);
  }

  void _handleResizeEnd() {
    resizeStartOffset = null;
  }

  @override
  Widget build(BuildContext context) {
    // While the natural size is still resolving, show a small placeholder.
    if (currentWidth == null || currentHeight == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 2, horizontal: 4),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }

    final width = currentWidth!;
    final height = currentHeight!;

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
                height: height,
                width: width,
                fit: BoxFit.fill,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: height,
                    width: width,
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
                height: height,
                width: width,
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
