import 'package:flutter/material.dart';

class DesktopTitleBar extends StatelessWidget {
  final String title;
  final VoidCallback? onClose;
  final VoidCallback? onMaximize;
  final VoidCallback? onMinimize;
  final bool isMaximized;

  const DesktopTitleBar({
    super.key,
    required this.title,
    this.onClose,
    this.onMaximize,
    this.onMinimize,
    this.isMaximized = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      color: Theme.of(context).appBarTheme.backgroundColor,
      child: Row(
        children: [
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              _WindowButton(
                icon: Icons.remove,
                onPressed: onMinimize,
              ),
              _WindowButton(
                icon: isMaximized ? Icons.fullscreen_exit : Icons.fullscreen,
                onPressed: onMaximize,
              ),
              _WindowButton(
                icon: Icons.close,
                onPressed: onClose,
                isCloseButton: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WindowButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isCloseButton;

  const _WindowButton({
    required this.icon,
    this.onPressed,
    this.isCloseButton = false,
  });

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          width: 46,
          height: 32,
          color: _isHovered
              ? widget.isCloseButton
                  ? Colors.red
                  : Colors.grey.withOpacity(0.2)
              : Colors.transparent,
          child: Icon(
            widget.icon,
            size: 16,
            color: widget.isCloseButton && _isHovered
                ? Colors.white
                : Theme.of(context).iconTheme.color,
          ),
        ),
      ),
    );
  }
}
