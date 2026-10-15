import 'package:flutter/material.dart';
import 'package:rohii_hostel_hunt/theme/app_colors.dart';

/// A hostel's cover picture: loaded from the web when [source] is an address (Cloudinary), from the
/// app's bundled assets otherwise, and a plain placeholder when it cannot be loaded or is empty.
class HostelCoverImage extends StatelessWidget {
  const HostelCoverImage({super.key, required this.source, required this.width, required this.height});

  final String source;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    Widget placeholder(BuildContext context, Object error, StackTrace? stackTrace) => Container(
          width: width,
          height: height,
          color: AppColors.auburn500.withValues(alpha: 0.1),
          child: Icon(Icons.apartment_rounded, color: AppColors.auburn500, size: (width / 3).clamp(20, 40).toDouble()),
        );

    if (source.isEmpty) return placeholder(context, '', null);
    if (source.startsWith('http')) {
      return Image.network(source, width: width, height: height, fit: BoxFit.cover, errorBuilder: placeholder);
    }
    return Image.asset(source, width: width, height: height, fit: BoxFit.cover, errorBuilder: placeholder);
  }
}
