import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rohii_hostel_hunt/models/hostel.dart';
import 'package:rohii_hostel_hunt/services/colors.dart';
import 'package:rohii_hostel_hunt/utils/hostel_navigation.dart';

/// ─────────────────────────────────────────────────────────
/// Compact search result card — horizontal layout
/// ─────────────────────────────────────────────────────────
///
/// Optimized for scanning in a search results list.
/// Different from [PremiumHostelCard] which is full-bleed.
class SearchResultCard extends StatefulWidget {
  final Hostel hostel;
  final bool isDark;
  final String query;
  final VoidCallback? onTap;

  const SearchResultCard({
    super.key,
    required this.hostel,
    required this.isDark,
    this.query = '',
    this.onTap,
  });

  @override
  State<SearchResultCard> createState() => _SearchResultCardState();
}

class _SearchResultCardState extends State<SearchResultCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final hostel = widget.hostel;
    final isDark = widget.isDark;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        HapticFeedback.selectionClick();
        // Use custom callback if provided, otherwise central navigation
        if (widget.onTap != null) {
          widget.onTap!();
        } else {
          navigateToHostelDetails(context, widget.hostel);
        }
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.cardBg(isDark),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? AppColors.white.withValues(alpha: 0.06)
                  : AppColors.border,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? AppColors.shadow.withValues(alpha: 0.25)
                    : AppColors.shadow.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // ── Thumbnail ──
              _buildThumbnail(hostel, isDark),
              const SizedBox(width: 14),

              // ── Info ──
              Expanded(child: _buildInfo(hostel, isDark)),

              // ── Rating badge ──
              _buildRating(hostel),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(Hostel hostel, bool isDark) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.orange.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.asset(
          hostel.image,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.orange.withValues(alpha: 0.15),
                  AppColors.orangeDark.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(
              Icons.apartment_rounded,
              color: AppColors.orange.withValues(alpha: 0.5),
              size: 32,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfo(Hostel hostel, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Name — with highlighted match
        _buildHighlightedText(
          hostel.name,
          widget.query,
          TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary(isDark),
            letterSpacing: -0.2,
            height: 1.2,
          ),
          isDark,
        ),
        const SizedBox(height: 4),

        // Location
        Row(
          children: [
            Icon(
              Icons.location_on_rounded,
              size: 12,
              color: AppColors.orange.withValues(alpha: 0.8),
            ),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                hostel.location,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary(isDark),
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Price + Tags row
        Row(
          children: [
            // Price chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: isDark ? 0.15 : 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                hostel.price,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.orange,
                ),
              ),
            ),
            const SizedBox(width: 6),

            // Tag chips (first 2 only to save space)
            ...hostel.tags.take(2).map(
                  (tag) => Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.chipBg(isDark),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary(isDark),
                      ),
                    ),
                  ),
                ),
          ],
        ),
      ],
    );
  }

  Widget _buildRating(Hostel hostel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.orange, AppColors.orangeDark],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppColors.orange.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: AppColors.white, size: 14),
          const SizedBox(height: 1),
          Text(
            hostel.rating.toString(),
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// Highlights matching portion of text with orange color.
  Widget _buildHighlightedText(
    String text,
    String query,
    TextStyle baseStyle,
    bool isDark,
  ) {
    if (query.isEmpty) {
      return Text(text, style: baseStyle, maxLines: 1, overflow: TextOverflow.ellipsis);
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final matchIndex = lowerText.indexOf(lowerQuery);

    if (matchIndex < 0) {
      return Text(text, style: baseStyle, maxLines: 1, overflow: TextOverflow.ellipsis);
    }

    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        children: [
          if (matchIndex > 0)
            TextSpan(
              text: text.substring(0, matchIndex),
              style: baseStyle,
            ),
          TextSpan(
            text: text.substring(matchIndex, matchIndex + query.length),
            style: baseStyle.copyWith(color: AppColors.orange),
          ),
          if (matchIndex + query.length < text.length)
            TextSpan(
              text: text.substring(matchIndex + query.length),
              style: baseStyle,
            ),
        ],
      ),
    );
  }
}
