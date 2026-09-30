import 'package:flutter/material.dart';

enum GameButtonStyle { green, purple, gold, teal, red }

/// Chunky "candy" button that presses down.
class GameButton extends StatefulWidget {
  const GameButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style = GameButtonStyle.green,
    this.icon,
    this.sublabel,
    this.height = 56,
    this.fontSize = 22,
    this.expand = true,
  });

  final String label;
  final String? sublabel;
  final VoidCallback? onPressed;
  final GameButtonStyle style;
  final IconData? icon;
  final double height;
  final double fontSize;
  final bool expand;

  @override
  State<GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<GameButton> {
  bool _down = false;

  (Color, Color, Color) get _colors {
    switch (widget.style) {
      case GameButtonStyle.green:
        return (
          const Color(0xFF7BE04A),
          const Color(0xFF3FAE1F),
          const Color(0xFF26761A),
        );
      case GameButtonStyle.purple:
        return (
          const Color(0xFFA06BFF),
          const Color(0xFF6A3FD8),
          const Color(0xFF43258F),
        );
      case GameButtonStyle.gold:
        return (
          const Color(0xFFFFD23F),
          const Color(0xFFFF9A3D),
          const Color(0xFFB3541A),
        );
      case GameButtonStyle.teal:
        return (
          const Color(0xFF37D3C2),
          const Color(0xFF1A9AA8),
          const Color(0xFF0D6470),
        );
      case GameButtonStyle.red:
        return (
          const Color(0xFFFF6A6A),
          const Color(0xFFD63B3B),
          const Color(0xFF8D1F1F),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final (top, bottom, edge) = _colors;
    const depth = 5.0;

    final content = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (widget.icon != null) ...<Widget>[
          Icon(
            widget.icon,
            color: Colors.white,
            size: widget.fontSize + 4,
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontWeight: FontWeight.w700,
                  fontSize: widget.fontSize,
                  color: Colors.white,
                  shadows: const <Shadow>[
                    Shadow(
                      color: Color(0x40000000),
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
              if (widget.sublabel != null)
                Text(
                  widget.sublabel!,
                  style: const TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 13,
                    color: Color(0xE6FFFFFF),
                  ),
                ),
            ],
          ),
        ),
      ],
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: enabled ? () => setState(() => _down = false) : null,
        onTapUp: enabled ? (_) => setState(() => _down = false) : null,
        onTap: widget.onPressed,
        child: Opacity(
          opacity: enabled ? 1 : 0.5,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 70),
            height: widget.height,
            margin: EdgeInsets.only(
              top: _down ? depth - 2 : 0,
              bottom: _down ? 2 : depth,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 22),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[top, bottom],
              ),
              borderRadius: BorderRadius.circular(widget.height / 2),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: edge,
                  offset: Offset(0, _down ? 2 : depth),
                ),
                const BoxShadow(
                  color: Color(0x59000000),
                  offset: Offset(0, 10),
                  blurRadius: 14,
                ),
              ],
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}
