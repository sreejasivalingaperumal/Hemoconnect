import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Color-coded status badge widget for Pending, Approved, Rejected, Processing, Completed.
class StatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;

  const StatusBadge({
    super.key,
    required this.status,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'approved':
      case 'completed':
        bg = AppColors.successBg;
        fg = AppColors.success;
        icon = Icons.check_circle_rounded;
        break;
      case 'pending':
        bg = AppColors.warningBg;
        fg = AppColors.warning;
        icon = Icons.hourglass_empty_rounded;
        break;
      case 'processing':
        bg = AppColors.infoBg;
        fg = AppColors.info;
        icon = Icons.sync_rounded;
        break;
      case 'rejected':
      default:
        bg = AppColors.dangerBg;
        fg = AppColors.danger;
        icon = Icons.cancel_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: fg.withOpacity(0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: fg.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: fontSize + 3, color: fg),
          const SizedBox(width: 5),
          Text(
            status,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: fg,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
