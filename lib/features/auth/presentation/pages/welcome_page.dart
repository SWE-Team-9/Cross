import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../routes/auth_routes.dart';
import '../widgets/auth_button.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: const Color(0xFF111111),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _WelcomeBackgroundPainter(),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(28, 36, 28, 36),
              decoration: const BoxDecoration(
                color: Color(0xFF5D8EF2),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(34),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud,
                    color: Colors.black,
                    size: 44,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "We lead what’s next in music.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 28),
                  AuthButton(
                    text: 'Create an account',
                    onPressed: () {
                      context.push(AuthRoutes.authMethod);
                    },
                  ),
                  const SizedBox(height: 16),
                  AuthButton(
                    text: 'Log in',
                    backgroundColor: const Color(0xFFDCE4F7),
                    textColor: Colors.black,
                    onPressed: () {
                      context.push(AuthRoutes.authMethod);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeBackgroundPainter extends CustomPainter {
  final _cyan = Paint()
    ..color = const Color(0xFF25D0E3)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;

  final _purple = Paint()
    ..color = const Color(0xFFA868F7)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;

  final _orange = Paint()
    ..color = const Color(0xFFFF8459)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < 6; i++) {
      final rect = Rect.fromCircle(
        center: Offset(size.width * 0.85, -80),
        radius: 120 + (i * 42),
      );
      canvas.drawArc(rect, 0.9, 2.2, false, _cyan);
    }

    for (int i = 0; i < 4; i++) {
      final rect = Rect.fromLTWH(
        -80 - (i * 30),
        size.height * 0.23 + (i * 18),
        260,
        320,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(60)),
        _purple,
      );
    }

    for (int i = 0; i < 6; i++) {
      final path = Path()
        ..moveTo(size.width * 0.30 + (i * 24), size.height * 0.62 - (i * 38))
        ..lineTo(size.width * 0.46 + (i * 24), size.height * 0.74 - (i * 38))
        ..lineTo(size.width * 0.88 + (i * 24), size.height * 0.60 - (i * 38))
        ..lineTo(size.width * 1.02 + (i * 24), size.height * 0.72 - (i * 38));
      canvas.drawPath(path, _orange);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
