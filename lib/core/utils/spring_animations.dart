import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';
class SpringAnimations {
  static const double defaultMass = 1.0;
  static const double defaultStiffness = 500.0;
  static const double defaultDamping = 25.0;
  static SpringDescription get defaultSpring => const SpringDescription(
        mass: defaultMass,
        stiffness: defaultStiffness,
        damping: defaultDamping,
      );
  static SpringDescription get bouncy => const SpringDescription(
        mass: defaultMass,
        stiffness: 300.0,
        damping: 15.0,
      );
  static SpringDescription get smooth => const SpringDescription(
        mass: defaultMass,
        stiffness: 400.0,
        damping: 20.0,
      );
  static SpringDescription get gentle => const SpringDescription(
        mass: 1.5,
        stiffness: 200.0,
        damping: 30.0,
      );
  static SpringSimulation createSimulation({
    required double start,
    required double end,
    double velocity = 0.0,
    SpringDescription? spring,
  }) {
    return SpringSimulation(
      spring ?? defaultSpring,
      start,
      end,
      velocity,
    );
  }
  static double dampedSpring({
    required double t,
    double stiffness = 100.0,
    double damping = 10.0,
    double mass = 1.0,
  }) {
    final omega = (stiffness / mass).abs();
    final dampedOmega = (omega - (damping / (2 * mass)).abs()).abs();
    if (dampedOmega <= 0) return 1.0;
    final exp = (-damping * t) / (2 * mass);
    return 1 - exp * (dampedOmega * t).abs();
  }
}
class AnimationDurations {
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration slower = Duration(milliseconds: 500);
  static const Duration mapFlyTo = Duration(milliseconds: 1200);
  static const Duration mapRoute = Duration(milliseconds: 1500);
}
class AnimationCurves {
  static const Curve standard = Curves.easeInOutCubic;
  static const Curve emphasis = Curves.easeOutCubic;
  static const Curve subtle = Curves.easeOut;
  static const Curve bounce = Curves.elasticOut;
  static const Curve decelerate = Curves.decelerate;
  static const Curve smooth = Curves.fastOutSlowIn;
}
class TweenAnimations {
  static Widget fadeIn({
    required Widget child,
    required Animation<double> animation,
    Curve curve = Curves.easeOut,
  }) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: animation, curve: curve),
      ),
      child: child,
    );
  }
  static Widget fadeOut({
    required Widget child,
    required Animation<double> animation,
    Curve curve = Curves.easeIn,
  }) {
    return FadeTransition(
      opacity: Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(parent: animation, curve: curve),
      ),
      child: child,
    );
  }
  static Widget slideIn({
    required Widget child,
    required Animation<double> animation,
    Offset beginOffset = const Offset(0, 0.1),
    Curve curve = Curves.easeOutCubic,
  }) {
    return SlideTransition(
      position: Tween<Offset>(begin: beginOffset, end: Offset.zero).animate(
        CurvedAnimation(parent: animation, curve: curve),
      ),
      child: child,
    );
  }
  static Widget scaleIn({
    required Widget child,
    required Animation<double> animation,
    double beginScale = 0.8,
    Curve curve = Curves.easeOutCubic,
  }) {
    return ScaleTransition(
      scale: Tween<double>(begin: beginScale, end: 1.0).animate(
        CurvedAnimation(parent: animation, curve: curve),
      ),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOut),
        ),
        child: child,
      ),
    );
  }
  static Widget scaleInOut({
    required Widget child,
    required Animation<double> animation,
    double beginScale = 0.9,
    Curve curve = Curves.easeInOut,
  }) {
    return ScaleTransition(
      scale: Tween<double>(begin: beginScale, end: 1.0).animate(
        CurvedAnimation(parent: animation, curve: curve),
      ),
      child: child,
    );
  }
}
class AnimatedDelay extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Curve curve;
  const AnimatedDelay({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeOutCubic,
  });
  @override
  State<AnimatedDelay> createState() => _AnimatedDelayState();
}
class _AnimatedDelayState extends State<AnimatedDelay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: widget.child,
    );
  }
}
class AnimatedSequence extends StatelessWidget {
  final List<Widget> children;
  final Duration itemDuration;
  final Duration itemDelay;
  final Curve curve;
  const AnimatedSequence({
    super.key,
    required this.children,
    this.itemDuration = const Duration(milliseconds: 400),
    this.itemDelay = const Duration(milliseconds: 80),
    this.curve = Curves.easeOutCubic,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(children.length, (index) {
        return AnimatedDelay(
          delay: itemDelay * index,
          duration: itemDuration,
          curve: curve,
          child: children[index],
        );
      }),
    );
  }
}
