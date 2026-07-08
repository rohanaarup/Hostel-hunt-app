import 'package:flutter/material.dart';
import 'package:rohii_hostel_hunt/core/theme/colors.dart';

class SubHeader extends StatelessWidget {
  final String title, subtitle;
  final bool isDark;
  const SubHeader({required this.title, required this.subtitle, required this.isDark, super.key});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(16, top + 12, 16, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark ? [AppColors.cardDark, AppColors.surfaceDark2] : [AppColors.headerStart, AppColors.headerEnd],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
        boxShadow: [BoxShadow(color: AppColors.shadow.withValues(alpha: isDark ? 0.22 : 0.07), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.maybePop(context),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.chipDark : AppColors.white.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? AppColors.white.withValues(alpha: 0.08) : AppColors.border, width: 0.8),
            ),
            child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.textPrimary(isDark)),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(color: AppColors.textPrimary(isDark), fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
          Text(subtitle, style: TextStyle(color: AppColors.textSecondary(isDark), fontSize: 12)),
        ])),
      ]),
    );
  }
}
