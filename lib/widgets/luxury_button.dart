import 'package:flutter/material.dart';

class LuxuryButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;
  final IconData? icon;
  final double? width;
  final double? height;

  const LuxuryButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.isPrimary = true,
    this.icon,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  State<LuxuryButton> createState() => _LuxuryButtonState();
}

class _LuxuryButtonState extends State<LuxuryButton> with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails details) {
    setState(() => _scale = 0.96);
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _scale = 1.0);
  }

  void _onTapCancel() {
    setState(() => _scale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final width = widget.width ?? MediaQuery.of(context).size.width * 0.8;
    final height = widget.height ?? 52.0;
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: SizedBox(
          width: width,
          height: height,
          child: ElevatedButton.icon(
            icon: widget.icon != null ? Icon(widget.icon, size: 22) : const SizedBox.shrink(),
            label: Text(
              widget.label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 18,
                letterSpacing: 0.5,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.isPrimary ? colorScheme.primary : colorScheme.secondary,
              foregroundColor: widget.isPrimary ? colorScheme.onPrimary : colorScheme.onSecondary,
              elevation: 6,
              shadowColor: colorScheme.primary.withOpacity(0.18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              minimumSize: Size(width, height),
            ),
            onPressed: widget.onPressed,
          ),
        ),
      ),
    );
  }
} 