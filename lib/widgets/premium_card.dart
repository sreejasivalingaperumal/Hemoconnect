import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Modern reusable card with hover animation, glassmorphism,
/// soft borders and clickable support.
class PremiumCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Border? border;
  final Gradient? gradient;
  final double borderRadius;
  final bool isGlass;

  const PremiumCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.backgroundColor,
    this.border,
    this.gradient,
    this.borderRadius = 16,
    this.isGlass = false,
  });

  @override
  State<PremiumCard> createState() => _PremiumCardState();
}

class _PremiumCardState extends State<PremiumCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = widget.backgroundColor ??
        (isDark
            ? AppColors.surfaceDark
            : AppColors.surfaceLight);

    final borderColor =
        isDark ? AppColors.borderDark : AppColors.borderLight;

    return MouseRegion(
      onEnter: (_) {
        if (widget.onTap != null) {
          setState(() {
            _isHovered = true;
          });
        }
      },
      onExit: (_) {
        if (widget.onTap != null) {
          setState(() {
            _isHovered = false;
          });
        }
      },
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,

      child: AnimatedScale(
        scale: _isHovered ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,

        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,

          decoration: BoxDecoration(
            color: widget.gradient == null
                ? (widget.isGlass
                    ? bgColor.withOpacity(0.75)
                    : bgColor)
                : null,

            gradient: widget.gradient,

            borderRadius:
                BorderRadius.circular(widget.borderRadius),

            border: widget.border ??
                Border.all(
                  color: borderColor,
                  width: 1,
                ),

            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(
                  _isHovered ? 0.10 : 0.04,
                ),
                blurRadius:
                    _isHovered ? 18 : 8,
                spreadRadius: 0,
                offset: Offset(
                  0,
                  _isHovered ? 6 : 2,
                ),
              ),
            ],
          ),

          child: Material(
            color: Colors.transparent,
            borderRadius:
                BorderRadius.circular(widget.borderRadius),

            child: InkWell(
              onTap: widget.onTap,

              borderRadius:
                  BorderRadius.circular(widget.borderRadius),

              splashColor:
                  Theme.of(context)
                      .colorScheme
                      .primary
                      .withOpacity(0.08),

              highlightColor:
                  Theme.of(context)
                      .colorScheme
                      .primary
                      .withOpacity(0.04),

              child: Padding(
                padding: widget.padding ??
                    const EdgeInsets.all(16),

                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}