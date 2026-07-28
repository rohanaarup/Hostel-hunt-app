import 'package:flutter/material.dart';
import 'package:rohii_hostel_hunt/theme/app_colors.dart';
import 'blob_masked_hero.dart';

class AuthHeroRow extends StatelessWidget {
  final String headline;
  final String accentWord;
  final String subtext;
  final String imagePath;
  final bool isDark;

  const AuthHeroRow({
    super.key,
    required this.headline,
    required this.accentWord,
    required this.subtext,
    required this.imagePath,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left side: Headline + Subtext (55-60%)
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                headline,
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.ivory50 : AppColors.ink900,
                  height: 1.15,
                  letterSpacing: -0.5,
                ),
              ),
              if (accentWord.isNotEmpty)
                Text(
                  accentWord,
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: AppColors.auburn500,
                    height: 1.15,
                    letterSpacing: -0.5,
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                subtext,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.ivory300 : AppColors.ink700,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Right side: Blob-masked hero photo (40-45%)
        Expanded(
          flex: 4,
          child: BlobMaskedHero(
            imagePath: imagePath,
            isDark: isDark,
          ),
        ),
      ],
    );
  }
}
