import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum AppButtonVariant { primary, secondary, outline, danger, success }

/// Reusable modern button with gradient options, ambient button glow, loading indicators, and micro-press animations.
class AppButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final AppButtonVariant variant;
  final double? width;
  final double height;
  final EdgeInsetsGeometry? padding;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.width,
    this.height = 50,
    this.padding,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.isLoading;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Gradient? gradient;
    Color bgColor = AppColors.primary;
    Color textColor = Colors.white;
    BorderSide borderSide = BorderSide.none;
    List<BoxShadow>? shadow;

    switch (widget.variant) {
      case AppButtonVariant.primary:
        gradient = isDisabled ? null : AppColors.primaryGradient;
        bgColor = AppColors.primary;
        textColor = Colors.white;
        shadow = isDisabled ? null : AppColors.primaryButtonGlow;
        break;
      case AppButtonVariant.secondary:
        bgColor = AppColors.secondary;
        textColor = Colors.white;
        break;
      case AppButtonVariant.outline:
        bgColor = Colors.transparent;
        textColor = isDark ? AppColors.primaryLight : AppColors.primary;
        borderSide = BorderSide(
          color: isDark ? AppColors.primaryLight : AppColors.primary,
          width: 1.5,
        );
        break;
      case AppButtonVariant.danger:
        gradient = isDisabled ? null : AppColors.emergencyGradient;
        bgColor = AppColors.danger;
        textColor = Colors.white;
        shadow = isDisabled
            ? null
            : [
                BoxShadow(
                  color: AppColors.danger.withOpacity(0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ];
        break;
      case AppButtonVariant.success:
        gradient = isDisabled ? null : AppColors.successGradient;
        bgColor = AppColors.success;
        textColor = Colors.white;
        shadow = isDisabled
            ? null
            : [
                BoxShadow(
                  color: AppColors.success.withOpacity(0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ];
        break;
    }

    if (isDisabled) {
      bgColor = isDark ? AppColors.cardDark : AppColors.borderLight;
      textColor = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
      shadow = null;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: isDisabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed && !isDisabled ? 0.96 : (_isHovered && !isDisabled ? 1.015 : 1.0),
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: SizedBox(
            width: widget.width,
            height: widget.height,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                gradient: gradient,
                color: gradient == null ? bgColor : null,
                borderRadius: BorderRadius.circular(14),
                border: borderSide != BorderSide.none ? Border.fromBorderSide(borderSide) : null,
                boxShadow: shadow,
              ),
              child: ElevatedButton(
                onPressed: isDisabled ? null : widget.onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 22),
                ),
                child: widget.isLoading
                    ? SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(textColor),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(widget.icon, size: 19, color: textColor),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            widget.text,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
