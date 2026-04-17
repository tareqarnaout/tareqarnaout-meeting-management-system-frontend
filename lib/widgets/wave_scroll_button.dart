import 'package:flutter/material.dart';

class WaveScrollButton extends StatefulWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final bool isLoading;
  final int sliceCount;
  final bool outlined;
  final bool expand;
  final Color? borderColor;

  const WaveScrollButton({
    super.key,
    required this.text,
    this.icon,
    this.onPressed,
    this.backgroundColor = const Color(0xFF2E7D9E),
    this.foregroundColor = Colors.white,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.isLoading = false,
    this.sliceCount = 0,
    this.outlined = false,
    this.expand = false,
    this.borderColor,
  });

  @override
  State<WaveScrollButton> createState() => _WaveScrollButtonState();
}

class _WaveScrollButtonState extends State<WaveScrollButton>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late List<AnimationController> _sliceControllers;
  late List<Animation<double>> _sliceAnimations;

  bool _isHovered = false;
  int _resolvedSliceCount = 0;

  static const double _gap = 10.0;

  @override
  void initState() {
    super.initState();
    _resolvedSliceCount = widget.sliceCount > 0
        ? widget.sliceCount
        : widget.text.characters.length;

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );

    _sliceControllers = List.generate(_resolvedSliceCount, (int i) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      );
    });
    _sliceAnimations = _sliceControllers.map((AnimationController c) {
      return Tween<double>(begin: 0.0, end: -1.0).animate(
        CurvedAnimation(parent: c, curve: Curves.easeOutCubic),
      );
    }).toList();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    for (final AnimationController c in _sliceControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _onEnter() {
    if (widget.onPressed == null || widget.isLoading) return;
    setState(() => _isHovered = true);
    _scaleController.forward();
    for (int i = 0; i < _sliceControllers.length; i++) {
      Future.delayed(Duration(milliseconds: 35 * i), () {
        if (mounted && _isHovered) {
          _sliceControllers[i].forward();
        }
      });
    }
  }

  void _onExit() {
    setState(() => _isHovered = false);
    _scaleController.reverse();
    for (int i = 0; i < _sliceControllers.length; i++) {
      Future.delayed(Duration(milliseconds: 35 * i), () {
        if (mounted && !_isHovered) {
          _sliceControllers[i].reverse();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool disabled = widget.onPressed == null;

    return MouseRegion(
      onEnter: (_) => _onEnter(),
      onExit: (_) => _onExit(),
      cursor: disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: disabled ? null : widget.onPressed,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (BuildContext context, Widget? child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: widget.expand ? double.infinity : null,
            padding: widget.padding,
            decoration: widget.outlined
                ? BoxDecoration(
                    color: _isHovered
                        ? (widget.borderColor ?? widget.foregroundColor)
                            .withValues(alpha: 0.06)
                        : Colors.transparent,
                    borderRadius: widget.borderRadius,
                    border: Border.all(
                      color: widget.borderColor ?? widget.foregroundColor,
                    ),
                  )
                : BoxDecoration(
                    color: disabled
                        ? widget.backgroundColor.withValues(alpha: 0.5)
                        : widget.backgroundColor,
                    borderRadius: widget.borderRadius,
                    border: Border.all(
                      color: _isHovered
                          ? widget.foregroundColor.withValues(alpha: 0.3)
                          : Colors.transparent,
                    ),
                  ),
            child: Row(
              mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.isLoading)
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          widget.foregroundColor),
                    ),
                  )
                else if (widget.icon != null)
                  Icon(widget.icon, size: 16, color: widget.foregroundColor),
                if (widget.icon != null || widget.isLoading)
                  const SizedBox(width: 8),
                _WaveTextLayout(
                  text: widget.text,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: widget.foregroundColor,
                  ),
                  sliceCount: _resolvedSliceCount,
                  sliceAnimations: _sliceAnimations,
                  gap: _gap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WaveTextLayout extends StatefulWidget {
  final String text;
  final TextStyle style;
  final int sliceCount;
  final List<Animation<double>> sliceAnimations;
  final double gap;

  const _WaveTextLayout({
    required this.text,
    required this.style,
    required this.sliceCount,
    required this.sliceAnimations,
    required this.gap,
  });

  @override
  State<_WaveTextLayout> createState() => _WaveTextLayoutState();
}

class _WaveTextLayoutState extends State<_WaveTextLayout> {
  final GlobalKey _textKey = GlobalKey();
  double _textWidth = 0;
  double _textHeight = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  void _measure() {
    final RenderBox? box =
        _textKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && mounted) {
      setState(() {
        _textWidth = box.size.width + 2;
        _textHeight = box.size.height;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget fullText =
        Text(widget.text, style: widget.style, maxLines: 1);
    final double totalShift = _textHeight + widget.gap;
    final bool measured = _textWidth > 0 && _textHeight > 0;

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Opacity(
          opacity: measured ? 0.0 : 1.0,
          key: _textKey,
          child: fullText,
        ),
        if (measured)
          ...List.generate(widget.sliceCount, (int i) {
            final double sliceWidth = _textWidth / widget.sliceCount;
            final double left = sliceWidth * i;

            return AnimatedBuilder(
              animation: widget.sliceAnimations[i],
              builder: (BuildContext context, Widget? child) {
                final double offset =
                    widget.sliceAnimations[i].value * totalShift;
                return Positioned(
                  left: 0,
                  top: 0,
                  width: _textWidth,
                  height: _textHeight,
                  child: ClipRect(
                    clipper: _VerticalSliceClipper(
                      sliceLeft: left,
                      sliceWidth: sliceWidth,
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Transform.translate(
                          offset: Offset(0, offset),
                          child: fullText,
                        ),
                        Transform.translate(
                          offset: Offset(0, offset + totalShift),
                          child: fullText,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }),
      ],
    );
  }
}

class _VerticalSliceClipper extends CustomClipper<Rect> {
  final double sliceLeft;
  final double sliceWidth;

  _VerticalSliceClipper({
    required this.sliceLeft,
    required this.sliceWidth,
  });

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(sliceLeft, 0, sliceWidth, size.height);
  }

  @override
  bool shouldReclip(_VerticalSliceClipper oldClipper) {
    return sliceLeft != oldClipper.sliceLeft ||
        sliceWidth != oldClipper.sliceWidth;
  }
}
