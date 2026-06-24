import 'package:flutter/material.dart';

/// A wrapper widget that provides interactive micro‑animations (scaling)
/// and optional background color on hover, with cursor pointer change.
class HoverWidget extends StatefulWidget {
  final Widget child;
  final double scale;
  final Duration duration;
  final Color? hoverColor;

  const HoverWidget({
    super.key,
    required this.child,
    this.scale = 1.02,
    this.duration = const Duration(milliseconds: 150),
    this.hoverColor,
  });

  @override
  State<HoverWidget> createState() => _HoverWidgetState();
}

class _HoverWidgetState extends State<HoverWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // Use a subtle hover color that fits the theme if none provided
    final hoverBg = widget.hoverColor ?? Theme.of(context).colorScheme.secondary.withAlpha(26);
    final bg = _isHovered ? hoverBg : Colors.transparent;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: widget.duration,
        curve: Curves.easeInOut,
        // No scaling, only background color change on hover
        transform: Matrix4.identity(),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: widget.child,
      ),
    );
  }
}
