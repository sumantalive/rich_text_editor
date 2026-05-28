import 'package:flutter/material.dart';

class CustomDropdownItem<T> {
  final T value;
  final String label;

  CustomDropdownItem({required this.value, required this.label});
}

class CustomDropdown<T> extends StatefulWidget {
  final T value;
  final List<CustomDropdownItem<T>> items;
  final Function(T) onChanged;
  final String? hint;
  final double? width;

  const CustomDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
    this.width,
  });

  @override
  State<CustomDropdown<T>> createState() => _CustomDropdownState<T>();
}

class _CustomDropdownState<T> extends State<CustomDropdown<T>> {
  late GlobalKey<State<StatefulWidget>> _key;
  OverlayEntry? _overlayEntry;
  late ValueNotifier<bool> _isOpenNotifier;

  @override
  void initState() {
    super.initState();
    _key = GlobalKey();
    _isOpenNotifier = ValueNotifier<bool>(false);
  }

  void _openDropdown() {
    if (_isOpenNotifier.value) {
      _closeDropdown();
      return;
    }

    final RenderBox renderBox = _key.currentContext!.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final screenHeight = MediaQuery.of(context).size.height;

    // Calculate available space
    final spaceBelow = screenHeight - (offset.dy + size.height);

    bool openBelow = spaceBelow > 250;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        width: widget.width ?? size.width,
        top: openBelow ? offset.dy + size.height + 5 : offset.dy - (250 + 10),
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            constraints: BoxConstraints(maxHeight: 250),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                final item = widget.items[index];
                final isSelected = item.value == widget.value;

                return Material(
                  color: isSelected ? Colors.blue[50] : Colors.white,
                  child: InkWell(
                    onTap: () {
                      Future.microtask(() {
                        widget.onChanged(item.value);
                        _closeDropdown();
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.label,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(Icons.check,
                                size: 18, color: Colors.blue),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _isOpenNotifier.value = true;
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _isOpenNotifier.value = false;
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _isOpenNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedLabel = widget.items
        .firstWhere((item) => item.value == widget.value,
            orElse: () => CustomDropdownItem(value: widget.value, label: widget.hint ?? ''))
        .label;

    return ValueListenableBuilder<bool>(
      valueListenable: _isOpenNotifier,
      builder: (context, isOpen, _) {
        return Container(
          key: _key,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            child: InkWell(
              onTap: _openDropdown,
              borderRadius: BorderRadius.circular(6),
              focusColor: Colors.transparent,
              highlightColor: Colors.grey[100],
              splashColor: Colors.grey[100],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  // mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      selectedLabel,
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                      size: 18,
                      color: Colors.grey[600],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
