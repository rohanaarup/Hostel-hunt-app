import 'package:flutter/material.dart';
import 'package:rohii_hostel_hunt/theme/app_colors.dart';

class BlobMaskedHero extends StatelessWidget {
  final String imagePath;
  final bool isDark;

  const BlobMaskedHero({
    super.key,
    required this.imagePath,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.85,
      child: Stack(
        children: [
          // 1. The image clipped to the blob shape
          Positioned.fill(
            child: ClipPath(
              clipper: BlobClipper(),
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                color: isDark
                    ? Colors.black.withValues(alpha: 0.45)
                    : Colors.black.withValues(alpha: 0.15),
                colorBlendMode: BlendMode.darken,
              ),
            ),
          ),
          // 2. The thin auburn border tracing the same blob shape
          Positioned.fill(
            child: CustomPaint(
              painter: BlobBorderPainter(
                color: AppColors.auburn300,
                strokeWidth: 2.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BlobClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();
    
    // Create an organic, irregular blob shape using bezier curves.
    // Based on reference, wider at top, narrower curves at bottom-left, wavy right side.
    path.moveTo(w * 0.35, h * 0.03);
    path.cubicTo(w * 0.70, -0.05 * h, w * 1.05, h * 0.20, w * 0.96, h * 0.45);
    path.cubicTo(w * 0.88, h * 0.65, w * 0.95, h * 0.88, w * 0.70, h * 0.97);
    path.cubicTo(w * 0.42, h * 1.07, w * 0.10, h * 0.95, w * 0.02, h * 0.75);
    path.cubicTo(-0.06 * w, h * 0.50, w * 0.15, h * 0.25, w * 0.35, h * 0.03);
    
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class BlobBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  BlobBorderPainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final path = BlobClipper().getClip(size);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..isAntiAlias = true;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant BlobBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}
