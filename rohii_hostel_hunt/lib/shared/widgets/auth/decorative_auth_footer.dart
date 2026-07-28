import 'package:flutter/material.dart';
import 'package:rohii_hostel_hunt/theme/app_colors.dart';

class DecorativeAuthFooter extends StatelessWidget {
  final bool isDark;

  const DecorativeAuthFooter({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 200,
      child: CustomPaint(
        painter: _FooterPainter(isDark: isDark),
      ),
    );
  }
}

class _FooterPainter extends CustomPainter {
  final bool isDark;

  _FooterPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Wavy divider lines (auburn300/ember300, low opacity)
    final wavePaint = Paint()
      ..color = AppColors.auburn300.withValues(alpha: isDark ? 0.15 : 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..isAntiAlias = true;

    final wavePath1 = Path();
    wavePath1.moveTo(0, h * 0.4);
    wavePath1.quadraticBezierTo(w * 0.25, h * 0.6, w * 0.5, h * 0.4);
    wavePath1.quadraticBezierTo(w * 0.75, h * 0.2, w, h * 0.4);
    canvas.drawPath(wavePath1, wavePaint);

    final wavePaint2 = Paint()
      ..color = AppColors.ember300.withValues(alpha: isDark ? 0.1 : 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..isAntiAlias = true;

    final wavePath2 = Path();
    wavePath2.moveTo(0, h * 0.5);
    wavePath2.quadraticBezierTo(w * 0.3, h * 0.7, w * 0.6, h * 0.45);
    wavePath2.quadraticBezierTo(w * 0.85, h * 0.25, w, h * 0.5);
    canvas.drawPath(wavePath2, wavePaint2);

    // 2. Line-art city skyline silhouette
    final cityPaint = Paint()
      ..color = isDark 
          ? AppColors.ivory700.withValues(alpha: 0.15) 
          : AppColors.ivory500.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..isAntiAlias = true;

    final cityPath = Path();
    // Start from right side, bottom
    double currentX = w;
    double baseH = h * 0.95;
    
    cityPath.moveTo(w, baseH);
    // Draw some simple building outlines moving left
    
    // Building 1 (tall)
    cityPath.lineTo(w, h * 0.3);
    cityPath.lineTo(w - 30, h * 0.3);
    cityPath.lineTo(w - 30, baseH);
    
    // Building 2 (medium)
    currentX = w - 35;
    cityPath.moveTo(currentX, baseH);
    cityPath.lineTo(currentX, h * 0.45);
    cityPath.lineTo(currentX - 25, h * 0.45);
    cityPath.lineTo(currentX - 25, baseH);
    
    // Building 3 (with pitched roof)
    currentX = w - 65;
    cityPath.moveTo(currentX, baseH);
    cityPath.lineTo(currentX, h * 0.6);
    cityPath.lineTo(currentX - 15, h * 0.5); // peak
    cityPath.lineTo(currentX - 30, h * 0.6);
    cityPath.lineTo(currentX - 30, baseH);
    
    // Building 4 (small)
    currentX = w - 100;
    cityPath.moveTo(currentX, baseH);
    cityPath.lineTo(currentX, h * 0.7);
    cityPath.lineTo(currentX - 20, h * 0.7);
    cityPath.lineTo(currentX - 20, baseH);
    
    // Building 5 (tall, thin)
    currentX = w - 125;
    cityPath.moveTo(currentX, baseH);
    cityPath.lineTo(currentX, h * 0.35);
    cityPath.lineTo(currentX - 15, h * 0.35);
    cityPath.lineTo(currentX - 15, baseH);
    
    // Draw some windows on building 1
    for (int i = 0; i < 5; i++) {
      for (int j = 0; j < 2; j++) {
        double wx = (w - 25) + (j * 10);
        double wy = (h * 0.35) + (i * 15);
        cityPath.addRect(Rect.fromLTWH(wx, wy, 5, 8));
      }
    }
    
    canvas.drawPath(cityPath, cityPaint);

    // 3. Scattered dot pattern in bottom left
    final dotPaint = Paint()
      ..color = AppColors.auburn300.withValues(alpha: isDark ? 0.1 : 0.15)
      ..style = PaintingStyle.fill;
      
    for (int r = 0; r < 5; r++) {
      for (int c = 0; c < 5; c++) {
        // Only draw some dots to make it scattered
        if ((r + c) % 2 == 0) {
          canvas.drawCircle(Offset(w * 0.05 + (c * 15), h * 0.65 + (r * 15)), 1.5, dotPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FooterPainter oldDelegate) {
    return oldDelegate.isDark != isDark;
  }
}
