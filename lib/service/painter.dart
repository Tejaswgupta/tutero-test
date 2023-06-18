import 'dart:math';

import 'package:asteroids/screens/game_screen.dart';
import 'package:flutter/material.dart';

import '../models/bullet_model.dart';
import '../models/particle_model.dart';
import '../models/player_model.dart';

class GamePainter extends CustomPainter {
  final Player _player;
  final List<Particle> _particles;
  final List<Bullet> _bullets;
  final double _dx;
  final double _dy;

  final Paint playerPaint = Paint()..color = Colors.red;
  final Paint particlePaint = Paint()..color = Colors.green;
  final Paint bulletPaint = Paint()..color = Colors.black;

  GamePainter({
    required Player player,
    required List<Particle> particles,
    required double dx,
    required double dy,
    required List<Bullet> bullets,
  })  : _player = player,
        _particles = particles,
        _dx = dx,
        _dy = dy,
        _bullets = bullets;

  Offset _calculatePoint(
      double originX, double originY, double angle, double distance) {
    final x = originX + distance * cos(angle);
    final y = originY + distance * sin(angle);
    return Offset(x, y);
  }

  Path _buildParticlePath(Particle particle) {
    final polygonPath = Path();
    final polygonPoints = List<Offset>.generate(
      particle.sides, // Use the 'sides' property of Particle
      (i) => _calculatePoint(
        particle.x,
        particle.y,
        i * 2 * pi / particle.sides, // Use the 'sides' property of Particle
        particle.radius,
      ),
    );
    polygonPath.addPolygon(polygonPoints, true);
    return polygonPath;
  }

  @override
  void paint(Canvas canvas, Size size) {
    _particles.forEach((particle) {
      canvas.drawPath(_buildParticlePath(particle), particlePaint);
    });

    _bullets.forEach((bullet) {
      canvas.drawCircle(
        Offset(bullet.x, bullet.y),
        2,
        bulletPaint,
      );
    });

    final path = Path();
    final angle = atan2(_dy, _dx);

    final arrowHead = _calculatePoint(
        _player.x, _player.y, angle, Constants.playerRadius * 1.5);
    final leftWingTip = _calculatePoint(_player.x, _player.y,
        angle + 5 * pi / 6, Constants.playerRadius.toDouble());
    final arrowTail = _calculatePoint(
        _player.x, _player.y, angle + pi, Constants.playerRadius.toDouble());
    final rightWingTip = _calculatePoint(_player.x, _player.y,
        angle - 5 * pi / 6, Constants.playerRadius.toDouble());

    path.moveTo(arrowHead.dx, arrowHead.dy);
    path.lineTo(leftWingTip.dx, leftWingTip.dy);
    path.lineTo(arrowTail.dx, arrowTail.dy);
    path.lineTo(rightWingTip.dx, rightWingTip.dy);

    path.close();

    canvas.drawPath(path, playerPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
