import 'package:flutter/material.dart';
import '../models/image_model.dart';

/// Which edge of the image a resize drag started from. Top/bottom change the
/// height; left/right change the width.
enum _ResizeEdge { top, bottom, left, right }

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

  // Margin reserved around the image inside the Stack so the drag handles,
  // which overhang the image edges, stay within the Stack's hit-test bounds.
  static const double _pad = 12.0;

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

  /// Resizes from the dragged [edge]:
  ///  - top/bottom change only the height (the field grows vertically to fit),
  ///  - left/right change only the width (capped at the field width).
  void _handleResizeUpdate(Offset globalPosition, _ResizeEdge edge) {
    if (resizeStartOffset == null) return;

    final deltaX = globalPosition.dx - resizeStartOffset!.dx;
    final deltaY = globalPosition.dy - resizeStartOffset!.dy;

    double newWidth = resizeStartWidth;
    double newHeight = resizeStartHeight;

    switch (edge) {
      case _ResizeEdge.top:
        // Dragging up (deltaY negative) grows the height.
        newHeight = (resizeStartHeight - deltaY).clamp(_minSize, double.infinity);
        break;
      case _ResizeEdge.bottom:
        newHeight = (resizeStartHeight + deltaY).clamp(_minSize, double.infinity);
        break;
      case _ResizeEdge.left:
        // Dragging left (deltaX negative) grows the width.
        newWidth = (resizeStartWidth - deltaX).clamp(_minSize, _effectiveMaxWidth);
        break;
      case _ResizeEdge.right:
        newWidth = (resizeStartWidth + deltaX).clamp(_minSize, _effectiveMaxWidth);
        break;
    }

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

    // The handles overhang the image edges. A child positioned outside its
    // Stack's bounds is painted (Clip.none) but receives NO pointer events in
    // the overflow region — so the Stack must be larger than the image and the
    // handles must sit inside it. [_pad] is the margin reserved on every side.
    final stackWidth = width + _pad * 2;
    final stackHeight = height + _pad * 2;

    return GestureDetector(
      onTap: widget.isSelected ? widget.onDeselect : widget.onSelect,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
        child: SizedBox(
          width: stackWidth,
          height: stackHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: _pad,
                top: _pad,
                child: ClipRRect(
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
              ),
              if (widget.isSelected)
                Positioned(
                  left: _pad,
                  top: _pad,
                  child: IgnorePointer(
                    child: Container(
                      height: height,
                      width: width,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue, width: 2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              // Top edge — drag up/down to change height.
              if (widget.isSelected)
                Positioned(
                  top: _pad - 6,
                  left: _pad,
                  width: width,
                  child: Center(
                    child: _buildEdgeHandle(_ResizeEdge.top),
                  ),
                ),
              // Bottom edge — drag up/down to change height.
              if (widget.isSelected)
                Positioned(
                  top: _pad + height - 6,
                  left: _pad,
                  width: width,
                  child: Center(
                    child: _buildEdgeHandle(_ResizeEdge.bottom),
                  ),
                ),
              // Left edge — drag left/right to change width.
              if (widget.isSelected)
                Positioned(
                  left: _pad - 6,
                  top: _pad,
                  height: height,
                  child: Center(
                    child: _buildEdgeHandle(_ResizeEdge.left),
                  ),
                ),
              // Right edge — drag left/right to change width.
              if (widget.isSelected)
                Positioned(
                  left: _pad + width - 6,
                  top: _pad,
                  height: height,
                  child: Center(
                    child: _buildEdgeHandle(_ResizeEdge.right),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a pill-shaped drag handle for one side of the image.
  /// Horizontal bars (top/bottom) resize height; vertical bars (left/right)
  /// resize width. The empty [onTap] keeps a tap on the handle from bubbling
  /// up to the image and toggling its selection.
  Widget _buildEdgeHandle(_ResizeEdge edge) {
    final isHorizontalBar = edge == _ResizeEdge.top || edge == _ResizeEdge.bottom;
    return MouseRegion(
      cursor: isHorizontalBar
          ? SystemMouseCursors.resizeUpDown
          : SystemMouseCursors.resizeLeftRight,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {},
        onPanStart: (details) => _handleResizeStart(details.globalPosition),
        onPanUpdate: (details) => _handleResizeUpdate(details.globalPosition, edge),
        onPanEnd: (_) => _handleResizeEnd(),
        child: Container(
          width: isHorizontalBar ? 28 : 12,
          height: isHorizontalBar ? 12 : 28,
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
