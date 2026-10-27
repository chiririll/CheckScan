import 'dart:math' as math;

import 'package:flutter/material.dart';

const _enter = Duration(milliseconds: 420);

/// Fades and lifts [child] into place once, delayed by [index] so lists cascade.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({super.key, required this.child, this.index = 0, this.offset = 16});

  final Widget child;
  final int index;
  final double offset;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> with SingleTickerProviderStateMixin {
  static const _maxStagger = 8;
  static const _step = 45;

  late final AnimationController _controller;
  late final Animation<double> _curve;

  @override
  void initState() {
    super.initState();
    final delay = math.min(widget.index, _maxStagger) * _step;
    final total = _enter.inMilliseconds + delay;
    _controller = AnimationController(vsync: this, duration: Duration(milliseconds: total));
    _curve = CurvedAnimation(
      parent: _controller,
      curve: Interval(delay / total, 1, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      builder: (context, child) => Opacity(
        opacity: _curve.value,
        child: Transform.translate(offset: Offset(0, (1 - _curve.value) * widget.offset), child: child),
      ),
      child: widget.child,
    );
  }
}

/// Replays a short fade + rise whenever [active] flips to true.
/// For tabs kept alive in an [IndexedStack].
class TabFade extends StatefulWidget {
  const TabFade({super.key, required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<TabFade> createState() => _TabFadeState();
}

class _TabFadeState extends State<TabFade> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
    value: 1,
  );
  late final Animation<double> _curve = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);

  @override
  void didUpdateWidget(TabFade oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      builder: (context, child) => Opacity(
        opacity: _curve.value,
        child: Transform.translate(offset: Offset(0, (1 - _curve.value) * 12), child: child),
      ),
      child: widget.child,
    );
  }
}

/// Scales [child] down slightly while pressed.
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  void _set(bool value) => setState(() => _down = value);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapCancel: () => _set(false),
      onTapUp: (_) => _set(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.92 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
