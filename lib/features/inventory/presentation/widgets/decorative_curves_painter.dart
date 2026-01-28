import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Decorative curves painter - extracted from inventory_screen.dart
class DecorativeCurvesPainter extends CustomPainter {
  final Color color;
  final double opacity;

  DecorativeCurvesPainter({
    this.color = const Color(0xFF2196F3),
    this.opacity = 0.1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw decorative curves
    final path1 = Path();
    path1.moveTo(0, size.height * 0.3);
    path1.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.1,
      size.width * 0.5,
      size.height * 0.3,
    );
    path1.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.5,
      size.width,
      size.height * 0.3,
    );
    canvas.drawPath(path1, paint);

    final path2 = Path();
    path2.moveTo(0, size.height * 0.7);
    path2.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.9,
      size.width * 0.5,
      size.height * 0.7,
    );
    path2.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.5,
      size.width,
      size.height * 0.7,
    );
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant DecorativeCurvesPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.opacity != opacity;
  }
}

/// Animated decorative curves painter with rotation
class AnimatedDecorativeCurvesPainter extends CustomPainter {
  final Color color;
  final double opacity;
  final double rotation;

  AnimatedDecorativeCurvesPainter({
    this.color = const Color(0xFF2196F3),
    this.opacity = 0.1,
    this.rotation = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(rotation * math.pi / 180);
    canvas.translate(-size.width / 2, -size.height / 2);

    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    path.moveTo(0, size.height * 0.5);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.2,
      size.width * 0.5,
      size.height * 0.5,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.8,
      size.width,
      size.height * 0.5,
    );
    canvas.drawPath(path, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant AnimatedDecorativeCurvesPainter oldDelegate) {
    return oldDelegate.rotation != rotation ||
        oldDelegate.color != color ||
        oldDelegate.opacity != opacity;
  }
}
