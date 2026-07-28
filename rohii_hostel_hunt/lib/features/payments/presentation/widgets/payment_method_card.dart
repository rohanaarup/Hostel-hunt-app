import 'package:flutter/material.dart';
import 'package:rohii_hostel_hunt/theme/app_colors.dart';

class PaymentMethodCard extends StatelessWidget {
  final String value;
  final String groupValue;
  final String title;
  final String iconUrl;
  final IconData fallbackIcon;
  final Color fallbackColor;
  final ValueChanged<String> onChanged;
  final bool isCard;

  const PaymentMethodCard({
    super.key,
    required this.value,
    required this.groupValue,
    required this.title,
    required this.iconUrl,
    required this.fallbackIcon,
    required this.fallbackColor,
    required this.onChanged,
    this.isCard = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = value == groupValue;
    final primaryColor = isDark ? AppColors.auburn300 : AppColors.auburn500;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => onChanged(value),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.ink900 : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? primaryColor : (isDark ? AppColors.ivory700 : AppColors.ivory300),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected && !isDark ? [
                BoxShadow(
                  color: primaryColor.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ] : [],
            ),
            child: Row(
              children: [
                _buildIcon(isDark),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.ivory50 : AppColors.ink900,
                    ),
                  ),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? primaryColor : (isDark ? AppColors.ivory700 : AppColors.ivory300),
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: primaryColor,
                            ),
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
        if (isSelected && isCard) ...[
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              // Action for add new card
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.ink900 : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppColors.ivory700 : AppColors.ivory300),
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 20, color: primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      "Add New Card",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildIcon(bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        color: Colors.white, // In case logo expects white bg
        child: Image.network(
          iconUrl,
          width: 32,
          height: 32,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: fallbackColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(fallbackIcon, color: fallbackColor, size: 20),
            );
          },
        ),
      ),
    );
  }
}
