import 'package:flutter/material.dart';

/// A premium, high-glow neon pin widget for map destinations.
/// Features a hollow/transparent center and a multi-layered electric blue glow.
class NeonPinWidget extends StatelessWidget {
  final double size;
  final Color color;

  const NeonPinWidget({
    super.key,
    this.size = 60,
    this.color = Colors.cyanAccent,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _NeonPinPainter(color: color),
      ),
    );
  }
}

class _NeonPinPainter extends CustomPainter {
  final Color color;

  _NeonPinPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 3);
    final radius = size.width / 4;
    
    // ── PIN SHAPE PATH ──────────────────────────────────────────────────────
    final path = Path();
    path.moveTo(size.width / 2, size.height * 0.9); // Tip
    
    // Left curve
    path.quadraticBezierTo(
      size.width * 0.1, size.height * 0.6, 
      size.width * 0.1, size.height * 0.35,
    );
    
    // Top circle
    path.arcToPoint(
      Offset(size.width * 0.9, size.height * 0.35),
      radius: Radius.circular(size.width * 0.4),
      clockwise: true,
    );
    
    // Right curve
    path.quadraticBezierTo(
      size.width * 0.9, size.height * 0.6,
      size.width / 2, size.height * 0.9,
    );

    // ── GLOW LAYERS ──────────────────────────────────────────────────────────
    
    // LAYER 1: Outer soft glow
    final outerGlowPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawPath(path, outerGlowPaint);

    // LAYER 2: Medium glow
    final mediumGlowPaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawPath(path, mediumGlowPaint);

    // LAYER 3: Core bright line
    final corePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(path, corePaint);

    // LAYER 4: Inner circle (hollow)
    final innerCirclePath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius * 0.8));
    
    // Inner Circle Glow
    canvas.drawPath(innerCirclePath, outerGlowPaint..strokeWidth = 4);
    canvas.drawPath(innerCirclePath, corePaint..strokeWidth = 1.5);
    
    // ── BOTTOM PULSE RING ────────────────────────────────────────────────────
    final bottomCenter = Offset(size.width / 2, size.height * 0.92);
    final pulsePaint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    
    canvas.drawCircle(bottomCenter, 6, pulsePaint);
    canvas.drawCircle(bottomCenter, 2, corePaint..strokeWidth = 1);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
