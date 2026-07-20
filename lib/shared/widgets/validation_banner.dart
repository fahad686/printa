import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/utils/payload_validator.dart';

class ValidationBanner extends StatelessWidget {
  final ValidationResult result;

  const ValidationBanner({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final ok = result.isValid;
    final color = ok ? AppConstants.primaryOrange : const Color(0xFFEF4444);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle_outline : Icons.error_outline,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              result.message,
              style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
