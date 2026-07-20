import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  factory StatusBadge.success(String label, {IconData icon = Icons.check_circle_rounded}) {
    return StatusBadge(
      label: label,
      color: const Color(0xFF10B981),
      icon: icon,
    );
  }

  factory StatusBadge.warning(String label, {IconData icon = Icons.warning_rounded}) {
    return StatusBadge(
      label: label,
      color: const Color(0xFFF59E0B),
      icon: icon,
    );
  }

  factory StatusBadge.error(String label, {IconData icon = Icons.error_rounded}) {
    return StatusBadge(
      label: label,
      color: const Color(0xFFEF4444),
      icon: icon,
    );
  }

  factory StatusBadge.info(String label, {IconData icon = Icons.info_rounded}) {
    return StatusBadge(
      label: label,
      color: const Color(0xFF3B82F6),
      icon: icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
