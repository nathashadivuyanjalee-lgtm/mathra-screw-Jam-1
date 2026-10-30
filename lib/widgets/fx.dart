import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/brand.dart';
import '../services/haptics.dart';

// ---------------------------------------------------------------------------
// Mathra FX – lightweight, dependency-free animation effects.
//  1. StarfieldBackground  (twinkling stars)
//  2. floating screws      (rise inside the starfield)
//  3. RotatingRing         (spinning gradient ring)
//  4. FloatY               (gentle bobbing)
//  5. GlowPulse            (breathing glow)
//  6. ShimmerText          (light sweep over text)
//  7. StaggerIn            (slide + fade + scale entrance)
//  8. Pressable            (press-down squish + haptic)
//  9. ShineSweep           (shine passing over buttons)
// 10. TypingDots           (bouncing "typing…" dots)
// 11. Heartbeat            (pulsing scale)
// 12. Wiggle               (attention shake)
// 13. ScrewSpinner         (spinning screw icon)
// 14. Typewriter           (letter-by-letter text)
// 15. Ripples              (expanding rings while speaking)
// 16. CountUp              (animated numbers)
// 17. AnimatedSwitcher use in About/Home (cross-fade text)
// ---------------------------------------------------------------------------

class _Particle {
  final double x, y, size, phase;
  final int speed, twinkle;
  final bool screw;
  const _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.phase,
    required this.speed,
    required this.twinkle,
    required this.screw,
  });
}

/// 1 + 2. Night-sky gradient with twinkling stars and rising screws.
class StarfieldBackground extends StatefulWidget {
  final Widget child;
  final List<Color>? colors;
  const StarfieldBackground({super.key, required this.child, this.colors});

  @override
  State<StarfieldBackground> createState() => _StarfieldBackgroundState();
}

class _StarfieldBackgroundState extends State<StarfieldBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 24))
      ..repeat();
    final rng = math.Random(42);
    _particles = List.generate(
      44,
      (i) => _Particle(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        size: 1.0 + rng.nextDouble() * 2.0,
        phase: rng.nextDouble(),
        speed: 1 + rng.nextInt(3),
        twinkle: 2 + rng.nextInt(5),
        screw: i % 9 == 0,
      ),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: widget.colors ?? const [Brand.navy2, Brand.navy, Color(0xFF04060F)],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(painter: _StarPainter(_c, _particles)),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  final Animation<double> t;
  final List<_Particle> ps;
  _StarPainter(this.t, this.ps) : super(repaint: t);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint();
    for (final s in ps) {
      final y = (s.y - t.value * s.speed) % 1.0;
      final dx = size.width * s.x +
          math.sin((t.value * s.speed + s.phase) * 2 * math.pi) * 6;
      final pos = Offset(dx, y * size.height);
      final tw = 0.35 +
          0.65 * (0.5 + 0.5 * math.sin((t.value * s.twinkle + s.phase) * 2 * math.pi));
      if (s.screw) {
        p
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = Brand.cyan.withValues(alpha: 0.28 * tw);
        canvas.drawCircle(pos, 9, p);
        canvas.drawLine(pos.translate(-5, 0), pos.translate(5, 0), p);
        canvas.drawLine(pos.translate(0, -5), pos.translate(0, 5), p);
      } else {
        p
          ..style = PaintingStyle.fill
          ..color = Colors.white.withValues(alpha: 0.75 * tw);
        canvas.drawCircle(pos, s.size, p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StarPainter old) => old.ps != ps;
}

/// 3. Spinning gradient ring around [child] (clipped to a circle).
class RotatingRing extends StatefulWidget {
  final double size;
  final double thickness;
  final Widget child;
  const RotatingRing({
    super.key,
    required this.size,
    required this.child,
    this.thickness = 4,
  });

  @override
  State<RotatingRing> createState() => _RotatingRingState();
}

class _RotatingRingState extends State<RotatingRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 6))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        children: [
          Positioned.fill(
            child: RotationTransition(
              turns: _c,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      Brand.gold,
                      Brand.orange,
                      Brand.blue,
                      Brand.cyan,
                      Brand.gold,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(widget.thickness),
            child: ClipOval(child: widget.child),
          ),
        ],
      ),
    );
  }
}

/// 4. Gentle up/down bobbing.
class FloatY extends StatefulWidget {
  final Widget child;
  final double amplitude;
  final int seconds;
  const FloatY({
    super.key,
    required this.child,
    this.amplitude = 8,
    this.seconds = 3,
  });

  @override
  State<FloatY> createState() => _FloatYState();
}

class _FloatYState extends State<FloatY> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(seconds: widget.seconds),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (_, child) => Transform.translate(
        offset: Offset(
          0,
          (Curves.easeInOut.transform(_c.value) * 2 - 1) * widget.amplitude,
        ),
        child: child,
      ),
    );
  }
}

/// 5. Breathing glow behind [child].
class GlowPulse extends StatefulWidget {
  final Widget child;
  final Color color;
  final BorderRadius borderRadius;
  final bool circle;
  final double maxBlur;
  const GlowPulse({
    super.key,
    required this.child,
    required this.color,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.circle = false,
    this.maxBlur = 22,
  });

  @override
  State<GlowPulse> createState() => _GlowPulseState();
}

class _GlowPulseState extends State<GlowPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
        ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (_, child) {
        final v = Curves.easeInOut.transform(_c.value);
        return DecoratedBox(
          decoration: BoxDecoration(
            shape: widget.circle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: widget.circle ? null : widget.borderRadius,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.25 + 0.35 * v),
                blurRadius: 10 + widget.maxBlur * v,
                spreadRadius: 1 + 3 * v,
              ),
            ],
          ),
          child: child,
        );
      },
    );
  }
}

class _SlideGT extends GradientTransform {
  final double p;
  const _SlideGT(this.p);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * p, 0, 0);
}

/// 6. Gold/orange text with a white highlight sweeping across.
class ShimmerText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final TextAlign align;
  const ShimmerText(
    this.text, {
    super.key,
    required this.style,
    this.align = TextAlign.center,
  });

  @override
  State<ShimmerText> createState() => _ShimmerTextState();
}

class _ShimmerTextState extends State<ShimmerText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) => LinearGradient(
          colors: const [
            Brand.orange,
            Brand.gold,
            Colors.white,
            Brand.gold,
            Brand.orange,
          ],
          stops: const [0.0, 0.4, 0.5, 0.6, 1.0],
          transform: _SlideGT(-1 + 2 * _c.value),
        ).createShader(bounds),
        child: Text(
          widget.text,
          textAlign: widget.align,
          style: widget.style.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}

/// 7. Slide + fade + scale entrance with a delay.
class StaggerIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Offset offset;
  final Curve curve;
  final Duration duration;
  const StaggerIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = const Offset(0, 0.3),
    this.curve = Curves.easeOutBack,
    this.duration = const Duration(milliseconds: 650),
  });

  @override
  State<StaggerIn> createState() => _StaggerInState();
}

class _StaggerInState extends State<StaggerIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration);
    if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      _timer = Timer(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (_, child) {
        final t = widget.curve.transform(_c.value);
        final o = (_c.value * 1.8).clamp(0.0, 1.0).toDouble();
        return Opacity(
          opacity: o,
          child: FractionalTranslation(
            translation: Offset(
              widget.offset.dx * (1 - t),
              widget.offset.dy * (1 - t),
            ),
            child: Transform.scale(scale: 0.85 + 0.15 * t, child: child),
          ),
        );
      },
    );
  }
}

/// 8. Press-down squish with haptic feedback.
class Pressable extends StatefulWidget {
  final VoidCallback? onTap;
  final Widget child;
  final double pressedScale;
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.94,
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap == null
          ? null
          : () {
              Haptics.select();
              widget.onTap!();
            },
      child: AnimatedScale(
        scale: _down ? widget.pressedScale : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// 9. A shine that periodically sweeps across [child].
class ShineSweep extends StatefulWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final double phase;
  const ShineSweep({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.phase = 0,
  });

  @override
  State<ShineSweep> createState() => _ShineSweepState();
}

class _ShineSweepState extends State<ShineSweep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 3400))
        ..value = widget.phase
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: Stack(
        children: [
          widget.child,
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _c,
                builder: (_, __) {
                  final t = (_c.value / 0.45).clamp(0.0, 1.0).toDouble();
                  return FractionalTranslation(
                    translation: Offset(-1.2 + t * 4.4, 0),
                    child: FractionallySizedBox(
                      widthFactor: 0.28,
                      alignment: Alignment.centerLeft,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0),
                              Colors.white.withValues(alpha: 0.35),
                              Colors.white.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 10. Three bouncing dots ("bot is typing").
class TypingDots extends StatefulWidget {
  final Color color;
  const TypingDots({super.key, this.color = Brand.gold});

  @override
  State<TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final v = math.sin(_c.value * 2 * math.pi - i * 0.9);
          return Transform.translate(
            offset: Offset(0, -5 * math.max(0.0, v)),
            child: Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.6 + 0.4 * math.max(0.0, v)),
                shape: BoxShape.circle,
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// 11. Heartbeat pulse.
class Heartbeat extends StatefulWidget {
  final Widget child;
  final double amount;
  const Heartbeat({super.key, required this.child, this.amount = 0.14});

  @override
  State<Heartbeat> createState() => _HeartbeatState();
}

class _HeartbeatState extends State<Heartbeat>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (_, child) {
        final beat = math.pow(math.sin(math.pi * _c.value), 8).toDouble();
        return Transform.scale(scale: 1 + widget.amount * beat, child: child);
      },
    );
  }
}

/// 12. Short attention wiggle every few seconds.
class Wiggle extends StatefulWidget {
  final Widget child;
  const Wiggle({super.key, required this.child});

  @override
  State<Wiggle> createState() => _WiggleState();
}

class _WiggleState extends State<Wiggle> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 3200))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (_, child) {
        final t = _c.value;
        final a = t < 0.22
            ? math.sin(t / 0.22 * math.pi * 4) * 0.2 * (1 - t / 0.22)
            : 0.0;
        return Transform.rotate(angle: a, child: child);
      },
    );
  }
}

/// 13. Spinning metallic screw icon.
class ScrewSpinner extends StatefulWidget {
  final double size;
  const ScrewSpinner({super.key, this.size = 28});

  @override
  State<ScrewSpinner> createState() => _ScrewSpinnerState();
}

class _ScrewSpinnerState extends State<ScrewSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 5))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _c,
      child: CustomPaint(
        size: Size.square(widget.size),
        painter: _ScrewPainter(),
      ),
    );
  }
}

class _ScrewPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.3),
          colors: [Color(0xFFF1F5F9), Color(0xFF94A3B8), Color(0xFF475569)],
        ).createShader(rect),
    );
    final slot = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = r * 0.28
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(c.translate(-r * 0.5, 0), c.translate(r * 0.5, 0), slot);
    canvas.drawLine(c.translate(0, -r * 0.5), c.translate(0, r * 0.5), slot);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// 14. Letter-by-letter text reveal. Reserves the final size so the layout
/// does not jump while typing.
class Typewriter extends StatefulWidget {
  final String text;
  final TextStyle style;
  final VoidCallback? onTick;
  const Typewriter({
    super.key,
    required this.text,
    required this.style,
    this.onTick,
  });

  @override
  State<Typewriter> createState() => _TypewriterState();
}

class _TypewriterState extends State<Typewriter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    final ms = (widget.text.length * 24).clamp(300, 2200).toInt();
    _c = AnimationController(vsync: this, duration: Duration(milliseconds: ms));
    _c.addListener(() => widget.onTick?.call());
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final n = (widget.text.length * _c.value).floor();
        return Text.rich(
          TextSpan(
            style: widget.style,
            children: [
              TextSpan(text: widget.text.substring(0, n)),
              TextSpan(
                text: widget.text.substring(n),
                style: const TextStyle(color: Colors.transparent),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 15. Expanding ripple rings behind [child] while [active].
class Ripples extends StatefulWidget {
  final Widget child;
  final bool active;
  final Color color;
  final double size;
  const Ripples({
    super.key,
    required this.child,
    required this.active,
    this.color = Brand.cyan,
    this.size = 48,
  });

  @override
  State<Ripples> createState() => _RipplesState();
}

class _RipplesState extends State<Ripples> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (widget.active)
            Positioned.fill(
              child: CustomPaint(painter: _RipplePainter(_c, widget.color)),
            ),
          widget.child,
        ],
      ),
    );
  }
}

class _RipplePainter extends CustomPainter {
  final Animation<double> t;
  final Color color;
  _RipplePainter(this.t, this.color) : super(repaint: t);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    for (var i = 0; i < 3; i++) {
      final v = (t.value + i / 3) % 1.0;
      canvas.drawCircle(
        c,
        size.width * (0.5 + 0.55 * v),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = color.withValues(alpha: 0.6 * (1 - v)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RipplePainter old) => old.color != color;
}

/// 16. Number that counts up from 0.
class CountUp extends StatelessWidget {
  final int value;
  final TextStyle style;
  const CountUp({super.key, required this.value, required this.style});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: const Duration(milliseconds: 1300),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Text('$v', style: style),
    );
  }
}

// ---------------------------------------------------------------------------
// 3D effects
// ---------------------------------------------------------------------------

Matrix4 perspective3D({double rx = 0, double ry = 0, double rz = 0}) {
  return Matrix4.identity()
    ..setEntry(3, 2, 0.0012)
    ..rotateX(rx)
    ..rotateY(ry)
    ..rotateZ(rz);
}

/// 18. Touch-driven 3D tilt: the child leans toward your finger and springs back.
class Tilt3D extends StatefulWidget {
  final Widget child;
  final double maxAngle;
  const Tilt3D({super.key, required this.child, this.maxAngle = 0.28});

  @override
  State<Tilt3D> createState() => _Tilt3DState();
}

class _Tilt3DState extends State<Tilt3D> {
  double _rx = 0, _ry = 0;
  bool _active = false;

  void _update(Offset local, Size size) {
    if (size.isEmpty) return;
    final nx = (local.dx / size.width - 0.5) * 2; // -1..1
    final ny = (local.dy / size.height - 0.5) * 2;
    setState(() {
      _active = true;
      _ry = (nx * widget.maxAngle).clamp(-widget.maxAngle, widget.maxAngle).toDouble();
      _rx = (-ny * widget.maxAngle).clamp(-widget.maxAngle, widget.maxAngle).toDouble();
    });
  }

  void _release() => setState(() {
        _active = false;
        _rx = 0;
        _ry = 0;
      });

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (e) => _update(e.localPosition, context.size ?? Size.zero),
      onPointerMove: (e) => _update(e.localPosition, context.size ?? Size.zero),
      onPointerUp: (_) => _release(),
      onPointerCancel: (_) => _release(),
      child: AnimatedContainer(
        duration: Duration(milliseconds: _active ? 90 : 420),
        curve: _active ? Curves.easeOut : Curves.elasticOut,
        transformAlignment: Alignment.center,
        transform: perspective3D(rx: _rx, ry: _ry),
        child: widget.child,
      ),
    );
  }
}

/// 19. Coin-flip: rotates around the Y axis every few seconds.
class Spin3D extends StatefulWidget {
  final Widget child;
  const Spin3D({super.key, required this.child});

  @override
  State<Spin3D> createState() => _Spin3DState();
}

class _Spin3DState extends State<Spin3D> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 7))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (_, child) {
        final t = _c.value;
        final a = t < 0.16 ? Curves.easeInOut.transform(t / 0.16) * 2 * math.pi : 0.0;
        return Transform(
          alignment: Alignment.center,
          transform: perspective3D(ry: a),
          child: child,
        );
      },
    );
  }
}

/// 20. A disc that spins in 3D space (vinyl / coin). Used by the music player.
class Vinyl3D extends StatefulWidget {
  final bool spinning;
  final double size;
  final Widget? label;
  const Vinyl3D({super.key, required this.spinning, this.size = 150, this.label});

  @override
  State<Vinyl3D> createState() => _Vinyl3DState();
}

class _Vinyl3DState extends State<Vinyl3D> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 4));

  @override
  void initState() {
    super.initState();
    if (widget.spinning) _c.repeat();
  }

  @override
  void didUpdateWidget(covariant Vinyl3D old) {
    super.didUpdateWidget(old);
    if (widget.spinning && !_c.isAnimating) {
      _c.repeat();
    } else if (!widget.spinning && _c.isAnimating) {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return Transform(
      alignment: Alignment.center,
      transform: perspective3D(rx: 0.9),
      child: Container(
        width: s,
        height: s,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Brand.cyan.withValues(alpha: 0.35), blurRadius: 28, offset: const Offset(0, 18)),
          ],
        ),
        child: RotationTransition(
          turns: _c,
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [Color(0xFF111111), Color(0xFF3A3A3A), Color(0xFF111111), Color(0xFF2A2A2A), Color(0xFF111111)],
              ),
            ),
            child: Center(
              child: Container(
                width: s * 0.42,
                height: s * 0.42,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Brand.gold, Brand.orange, Brand.pink],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: widget.label ??
                      Container(
                        width: s * 0.08,
                        height: s * 0.08,
                        decoration: const BoxDecoration(color: Brand.navy, shape: BoxShape.circle),
                      ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 21. Music equalizer bars.
class EqualizerBars extends StatefulWidget {
  final bool active;
  final Color color;
  final double height;
  const EqualizerBars({super.key, required this.active, this.color = Brand.cyan, this.height = 22});

  @override
  State<EqualizerBars> createState() => _EqualizerBarsState();
}

class _EqualizerBarsState extends State<EqualizerBars> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void initState() {
    super.initState();
    if (widget.active) _c.repeat();
  }

  @override
  void didUpdateWidget(covariant EqualizerBars old) {
    super.didUpdateWidget(old);
    if (widget.active && !_c.isAnimating) {
      _c.repeat();
    } else if (!widget.active && _c.isAnimating) {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(5, (i) {
          final v = widget.active
              ? 0.25 + 0.75 * (0.5 + 0.5 * math.sin(_c.value * 2 * math.pi * (1 + i % 3) + i * 1.3))
              : 0.2;
          return Container(
            width: 4,
            height: widget.height * v,
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(color: widget.color, borderRadius: BorderRadius.circular(2)),
          );
        }),
      ),
    );
  }
}

/// 22. Confetti burst (used on level complete).
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({super.key});

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))
        ..forward();
  late final List<_Conf> _items = () {
    final r = math.Random(5);
    const cols = [Brand.gold, Brand.pink, Brand.cyan, Brand.green, Brand.orange, Brand.purple];
    return List.generate(
      60,
      (i) => _Conf(
        angle: -math.pi / 2 + (r.nextDouble() - 0.5) * 2.2,
        speed: 260 + r.nextDouble() * 360,
        spin: r.nextDouble() * 10,
        color: cols[i % cols.length],
        size: 6 + r.nextDouble() * 6,
      ),
    );
  }();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _ConfPainter(_c, _items),
      ),
    );
  }
}

class _Conf {
  final double angle, speed, spin, size;
  final Color color;
  const _Conf({required this.angle, required this.speed, required this.spin, required this.color, required this.size});
}

class _ConfPainter extends CustomPainter {
  final Animation<double> t;
  final List<_Conf> items;
  _ConfPainter(this.t, this.items) : super(repaint: t);

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width / 2, size.height * 0.62);
    final time = t.value * 2.4;
    for (final c in items) {
      final dx = math.cos(c.angle) * c.speed * time;
      final dy = math.sin(c.angle) * c.speed * time + 420 * time * time;
      canvas.save();
      canvas.translate(origin.dx + dx, origin.dy + dy);
      canvas.rotate(c.spin * time);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: c.size, height: c.size * 0.5),
        Paint()..color = c.color.withValues(alpha: (1 - t.value).clamp(0.0, 1.0).toDouble()),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfPainter old) => false;
}
