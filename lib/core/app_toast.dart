import 'package:flutter/material.dart';

enum ToastType { success, error, info, warning }

class AppToast {
  AppToast._();

  static OverlayEntry? _current;

  /// Affiche un toast en haut de l'écran.
  static void show(
    BuildContext context, {
    required String message,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    // 👉 Ferme le toast précédent s'il existe
    _current?.remove();
    _current = null;

    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (_) => _ToastWidget(
        message: message,
        type: type,
        duration: duration,
        onClose: () {
          _current?.remove();
          _current = null;
        },
      ),
    );

    _current = entry;
    overlay.insert(entry);
  }

  // 👉 Raccourcis
  static void success(BuildContext context, String message) =>
      show(context, message: message, type: ToastType.success);

  static void error(BuildContext context, String message) =>
      show(context, message: message, type: ToastType.error);

  static void info(BuildContext context, String message) =>
      show(context, message: message, type: ToastType.info);

  static void warning(BuildContext context, String message) =>
      show(context, message: message, type: ToastType.warning);
}

// ==========================================
// WIDGET INTERNE
// ==========================================
class _ToastWidget extends StatefulWidget {
  final String message;
  final ToastType type;
  final Duration duration;
  final VoidCallback onClose;

  const _ToastWidget({
    required this.message,
    required this.type,
    required this.duration,
    required this.onClose,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _controller.forward();

    // 👉 Auto-fermeture
    Future.delayed(widget.duration, () {
      if (mounted) _dismiss();
    });
  }

  void _dismiss() async {
    if (!mounted) return;
    await _controller.reverse();
    if (mounted) widget.onClose();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _bgColor {
    switch (widget.type) {
      case ToastType.success:
        return const Color(0xFF4CAF50);
      case ToastType.error:
        return const Color(0xFFE53935);
      case ToastType.warning:
        return const Color(0xFFFB8C00);
      case ToastType.info:
        return const Color(0xFF1E88E5);
    }
  }

  IconData get _icon {
    switch (widget.type) {
      case ToastType.success:
        return Icons.check_circle;
      case ToastType.error:
        return Icons.error_outline;
      case ToastType.warning:
        return Icons.warning_amber_rounded;
      case ToastType.info:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top + 10;

    return Positioned(
      top: top,
      left: 15,
      right: 15,
      child: SlideTransition(
        position: _slide,
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: _dismiss,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 15, vertical: 14),
              decoration: BoxDecoration(
                color: _bgColor,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: _bgColor.withValues(alpha: 0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Icône
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_icon, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),

                  // Message
                  Expanded(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ),

                  // Croix
                  GestureDetector(
                    onTap: _dismiss,
                    child: Icon(
                      Icons.close,
                      color: Colors.white.withValues(alpha: 0.8),
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}