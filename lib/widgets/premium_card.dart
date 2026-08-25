import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Modern visual card widget with glassmorphism, subtle border glows, soft ambient shadows, and hover micro-animations.
class PremiumCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Border? border;
  final Gradient? gradient;
  final double borderRadius;
  final bool isGlass;
  final List<BoxShadow>? boxShadow;

  const PremiumCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.backgroundColor,
    this.border,
    this.gradient,
    this.borderRadius = 20,
    this.isGlass = false,
    this.boxShadow,
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
        (isDark ? AppColors.surfaceDark : AppColors.surfaceLight);

    final borderColor = widget.isGlass
        ? (isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight)
        : (isDark ? AppColors.borderDark : AppColors.borderLight);

    final defaultShadows = isDark ? AppColors.cardShadowDark : AppColors.cardShadowLight;

    Widget cardContent = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: widget.gradient == null
            ? (widget.isGlass ? bgColor.withOpacity(isDark ? 0.7 : 0.85) : bgColor)
            : null,
        gradient: widget.gradient,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: widget.border ?? Border.all(color: borderColor, width: 1.2),
        boxShadow: widget.boxShadow ??
            [
              ...defaultShadows,
              if (_isHovered)
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.12),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
            ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          splashColor: AppColors.primary.withOpacity(0.08),
          highlightColor: AppColors.primary.withOpacity(0.04),
          child: Padding(
            padding: widget.padding ?? const EdgeInsets.all(20),
            child: widget.child,
          ),
        ),
      ),
    );

    if (widget.isGlass) {
      cardContent = ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: cardContent,
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) {
        if (widget.onTap != null) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (widget.onTap != null) setState(() => _isHovered = false);
      },
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: AnimatedScale(
        scale: _isHovered ? 1.015 : 1.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: cardContent,
      ),
    );
  }
}