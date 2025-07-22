import 'package:flutter/material.dart';
import 'dart:math' as math;

class StarRatingWidget extends StatefulWidget {
  final int rating;
  final ValueChanged<int> onRatingChanged;
  final double size;
  final String? title;

  const StarRatingWidget({
    super.key,
    required this.rating,
    required this.onRatingChanged,
    this.size = 30,
    this.title,
  });

  @override
  State<StarRatingWidget> createState() => _StarRatingWidgetState();
}

class _StarRatingWidgetState extends State<StarRatingWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.title != null)
          Text(
            widget.title!,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
        if (widget.title != null) const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            return GestureDetector(
          onTap: () {
            widget.onRatingChanged(index + 1);
            _controller.forward(from: 0.0);
          },
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 +
                    (index < widget.rating
                        ? math.sin(_controller.value * math.pi) * 0.2
                        : 0.0),
                child: child,
              );
            },
            child: Icon(
              index < widget.rating ? Icons.star_rounded : Icons.star_border_rounded,
              color: Colors.amber,
              size: widget.size,
              shadows: index < widget.rating
                  ? [
                      Shadow(
                        color: Colors.amber.withOpacity(0.5),
                        blurRadius: 10.0,
                      ),
                    ]
                  : null,
            ),
          ),
        );
      })),
      ],
    );
  }
}
