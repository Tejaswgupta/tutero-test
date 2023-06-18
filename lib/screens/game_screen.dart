import 'dart:async';
import 'dart:math';

import 'package:asteroids/service/painter.dart';
import 'package:flutter/material.dart';

import '../models/bullet_model.dart';
import '../models/particle_model.dart';
import '../models/player_model.dart';

// encapsulate the constants in a private class
class Constants {
  Constants._();

  static const int speedConstant = 2;
  static const int bulletSpeedConstant = 5;
  static const int playerRadius = 15;
  static const int minAsteroidSize = 5;
  static const int maxAsteroidSize = 10;
}

class GameScreen extends StatefulWidget {
  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  Offset _mousePosition = Offset.zero;
  late Player _player;
  bool _gameOver = false;
  int _gameTime = 0;
  double _dx = 0.0;
  double _dy = 0.0;
  late Timer _timer;

  final List<Bullet> _bullets = [];
  final List<Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addObserver(this);
    _initPlayer();
  }

  void _initPlayer() {
    _player = Player(x: _mousePosition.dx, y: _mousePosition.dy);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _setInitialValues();
    _timer = Timer.periodic(Duration(milliseconds: 16), _startGame);
  }

  _setInitialValues() {
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;

    _player
      ..x = width / 2
      ..y = height / 2;

    _mousePosition = Offset(width / 2, height / 2);

    _generateParticles(50);
  }

  void _startGame(Timer timer) {
    _gameTime++;
    setState(() {
      _performGameIteration();
      if (_gameOver) {
        _timer.cancel();
      }
    });
  }

  void _performGameIteration() {
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;

    // update particles and bullets
    _particles.forEach((particle) {
      _updateParticlePosition(particle);
      _checkParticleBoundaries(particle, width, height);
    });

    _bullets.forEach((bullet) {
      _updateBulletPosition(bullet);
      _wrapPosition(bullet, 0);
    });

    // handle bullet hits
    final hitBullets = <Bullet>{};
    _particles.removeWhere((particle) {
      for (final bullet in _bullets) {
        double dx = bullet.x - particle.x;
        double dy = bullet.y - particle.y;
        double distance = sqrt(dx * dx + dy * dy);

        if (distance < particle.radius + 2) {
          hitBullets.add(bullet);
          return true;
        }
      }
      return false;
    });

    // Remove hit bullets
    _bullets.removeWhere((bullet) => hitBullets.contains(bullet));

    // clean up the bullets when off screen
    _bullets.removeWhere((bullet) =>
        bullet.x < 0 || bullet.x > width || bullet.y < 0 || bullet.y > height);
  }

  void _updateParticlePosition(Particle particle) {
    particle
      ..x += particle.velocityX
      ..y += particle.velocityY;
  }

  void _checkParticleBoundaries(
      Particle particle, double width, double height) {
    double dx = particle.x - _player.x;
    double dy = particle.y - _player.y;
    double distance = sqrt(dx * dx + dy * dy);

    _wrapPosition(particle, particle.radius);

    if (distance < particle.radius + Constants.playerRadius) {
      _handleGameOver();
      return;
    }

    if (particle.x < 0 ||
        particle.x > width ||
        particle.y < 0 ||
        particle.y > height) {
      _resetParticle(particle, width, height);
    }
  }

  void _updateBulletPosition(Bullet bullet) {
    bullet
      ..x += bullet.velocityX
      ..y += bullet.velocityY;
  }

  void _resetParticle(Particle particle, double width, double height) {
    particle
      ..x = _random.nextDouble() * width
      ..y = _random.nextDouble() * height
      ..velocityX = Constants.speedConstant * _random.nextDouble() - 1
      ..velocityY = Constants.speedConstant * _random.nextDouble() - 1
      ..radius = Constants.minAsteroidSize +
          _random.nextDouble() * Constants.maxAsteroidSize;
  }

  void _handleGameOver() {
    _timer.cancel();
    _gameOver = true;
  }

  void _restartGame() {
    _particles.clear();
    _bullets.clear();
    _gameTime = 0;
    _gameOver = false;

    _setInitialValues();

    _timer = Timer.periodic(Duration(milliseconds: 16), _startGame);
  }

  void _generateParticles(int numParticles) {
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;

    for (int i = 0; i < numParticles; i++) {
      double x = _random.nextDouble() * width;
      double y = _random.nextDouble() * height;
      double velocityX = Constants.speedConstant * _random.nextDouble() - 1;
      double velocityY = Constants.speedConstant * _random.nextDouble() - 1;
      double radius = Constants.minAsteroidSize +
          _random.nextDouble() * Constants.maxAsteroidSize;
      int sides = _random.nextInt(4) + 3;

      _particles.add(Particle(
        x: x,
        y: y,
        velocityX: velocityX,
        velocityY: velocityY,
        radius: radius,
        sides: sides,
      ));
    }
  }

  void _shootBullet(double x, double y) {
    double dx = x - _player.x;
    double dy = y - _player.y;
    double magnitude = sqrt(dx * dx + dy * dy);

    double directionX = dx / magnitude;
    double directionY = dy / magnitude;

    setState(() {
      _bullets.add(
        Bullet(
          x: _player.x,
          y: _player.y,
          velocityX: directionX * Constants.bulletSpeedConstant,
          velocityY: directionY * Constants.bulletSpeedConstant,
        ),
      );
    });
  }

  void _wrapPosition(dynamic obj, double radius) {
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;

    if (obj.x < -radius) {
      obj.x = width + radius;
    } else if (obj.x > width + radius) {
      obj.x = -radius;
    }

    if (obj.y < -radius) {
      obj.y = height + radius;
    } else if (obj.y > height + radius) {
      obj.y = -radius;
    }
  }

  String _formattedTime() {
    double totalTimeSeconds = _gameTime * 0.016;
    int minutes = totalTimeSeconds ~/ 60;
    int seconds = totalTimeSeconds.round() % 60;

    return 'You lasted $minutes minutes and $seconds seconds';
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (details) {
        final pos = details.localPosition;

        setState(() {
          _dx = pos.dx - _player.x;
          _dy = pos.dy - _player.y;

          _normalizeDirection();
        });
      },
      child: GestureDetector(
        onTapDown: (details) {
          _shootBullet(details.localPosition.dx, details.localPosition.dy);
        },
        child: CustomPaint(
          painter: GamePainter(
            player: _player,
            particles: _particles,
            bullets: _bullets,
            dx: _dx,
            dy: _dy,
          ),
          child: _buildGameOverScreen(),
        ),
      ),
    );
  }

  void _normalizeDirection() {
    var magnitude = sqrt(_dx * _dx + _dy * _dy);

    if (magnitude != 0) {
      _dx /= magnitude;
      _dy /= magnitude;
    }
  }

  Widget _buildGameOverScreen() {
    if (_gameOver) {
      return Container(
        color: Colors.black.withOpacity(0.5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: double.infinity),
            Text(
              "GAME OVER \n ${_formattedTime()}",
              style: const TextStyle(
                fontSize: 30,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.deepPurpleAccent,
              ),
              onPressed: _restartGame,
              child: Text("Try Again"),
            ),
          ],
        ),
      );
    }
    return Container();
  }
}
