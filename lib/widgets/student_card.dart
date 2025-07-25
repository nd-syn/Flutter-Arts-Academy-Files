import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui';
import 'package:flutter_animate/flutter_animate.dart';

class StudentCard extends StatefulWidget {
  final String name;
  final String className;
  final String? photoPath;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final String? version; // Add version if available

  const StudentCard({
    Key? key,
    required this.name,
    required this.className,
    this.photoPath,
    this.onTap,
    this.onEdit,
    this.version,
  }) : super(key: key);

  @override
  State<StudentCard> createState() => _StudentCardState();
}

class _StudentCardState extends State<StudentCard> {
  bool _isPressed = false;

  String getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 600;
    return RepaintBoundary(
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: Container(
            margin: EdgeInsets.symmetric(vertical: width * 0.018, horizontal: width * 0.03),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.55),
                  Colors.white.withOpacity(0.35),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.blue.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: Colors.white.withOpacity(0.18),
                width: 1.2,
              ),
              backgroundBlendMode: BlendMode.overlay,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: widget.onTap,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: width * 0.03, horizontal: width * 0.04),
                      child: Row(
                        children: [
                          // Avatar with glow
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.primary.withOpacity(0.25),
                                  blurRadius: 18,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: widget.photoPath != null && widget.photoPath!.isNotEmpty
                                ? CircleAvatar(
                                    radius: width * 0.07,
                                    backgroundImage: FileImage(
                                      File(widget.photoPath!),
                                      // Optimize for avatar size
                                      // ignore: unnecessary_cast
                                    ),
                                  )
                                : CircleAvatar(
                                    radius: width * 0.07,
                                    backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
                                    child: Text(
                                      getInitials(widget.name),
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                          ),
                          SizedBox(width: width * 0.04),
                          // Name, class badge, and school/version
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.name,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: isWide ? 22 : 18,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                // Class badge below name
                                Container(
                                  margin: const EdgeInsets.only(bottom: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    widget.className,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    if (widget.version != null)
                                      Icon(
                                        widget.version == 'bengali' ? Icons.language : Icons.translate,
                                        color: theme.colorScheme.secondary,
                                        size: 18,
                                      ),
                                    if (widget.version != null) const SizedBox(width: 6),
                                    Text(
                                      widget.version == null
                                          ? ''
                                          : (widget.version == 'bengali' ? 'Bengali Version' : 'English Version'),
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.secondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Edit button as floating action
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(22),
                              onTap: widget.onEdit,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(0.13),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.colorScheme.primary.withOpacity(0.18),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Icon(Icons.edit, color: theme.colorScheme.primary, size: 22),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 