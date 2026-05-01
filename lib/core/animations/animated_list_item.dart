import 'package:flutter/material.dart';

/// Wraps any child with a staggered fade + slide-up animation.
/// Use [index] to stagger list items naturally.
///
/// Usage:
///   AnimatedListItem(index: index, child: MyCard(...))
class AnimatedListItem extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration baseDuration;

  const AnimatedListItem({
    super.key,
    required this.child,
    required this.index,
    this.baseDuration = const Duration(milliseconds: 400),
  });

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    // Cap stagger at 6 items so late items don't wait forever
    final staggerMs = (widget.index.clamp(0, 6) * 60);

    _controller = AnimationController(
      vsync: this,
      duration: widget.baseDuration,
    );

    _fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    Future.delayed(Duration(milliseconds: staggerMs), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
