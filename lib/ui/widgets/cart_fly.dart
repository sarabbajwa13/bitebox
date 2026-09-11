import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../config/app_theme.dart';

/// Cart icon ke "bump" ke liye — jab koi item cart tak pahunchta hai to
/// value badhti hai aur cart icon ek chhota bounce karta hai.
final ValueNotifier<int> cartBumpNotifier = ValueNotifier<int>(0);

/// Menu subtree ko cart icon ka [GlobalKey] deta hai (fly ka target). Har screen
/// apna key deti hai (shared global key nahi — warna duplicate-key crash).
class CartFlyTarget extends InheritedWidget {
  final GlobalKey cartKey;
  const CartFlyTarget({
    required this.cartKey,
    required super.child,
    super.key,
  });

  static CartFlyTarget? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CartFlyTarget>();

  @override
  bool updateShouldNotify(CartFlyTarget oldWidget) =>
      oldWidget.cartKey != cartKey;
}

/// [sourceKey] wali image ko [cartKey] wale cart icon tak arc me uda deta hai —
/// jaate-jaate chhoti hoti hai aur cart pe pahunch ke gayab.
void flyToCart({
  required BuildContext context,
  required GlobalKey sourceKey,
  required GlobalKey cartKey,
  required String imageUrl,
}) {
  if (imageUrl.isEmpty) return;
  final srcCtx = sourceKey.currentContext;
  final cartCtx = cartKey.currentContext;
  if (srcCtx == null || cartCtx == null) return;
  final srcBox = srcCtx.findRenderObject();
  final cartBox = cartCtx.findRenderObject();
  if (srcBox is! RenderBox || cartBox is! RenderBox) return;
  if (!srcBox.hasSize || !cartBox.hasSize) return;

  final overlay = Overlay.of(context, rootOverlay: true);
  final start = srcBox.localToGlobal(Offset.zero);
  final end = cartBox.localToGlobal(Offset.zero);

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _FlyingImage(
      start: start,
      startSize: srcBox.size,
      end: end,
      endSize: cartBox.size,
      imageUrl: imageUrl,
      onDone: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
}

class _FlyingImage extends StatefulWidget {
  final Offset start;
  final Size startSize;
  final Offset end;
  final Size endSize;
  final String imageUrl;
  final VoidCallback onDone;

  const _FlyingImage({
    required this.start,
    required this.startSize,
    required this.end,
    required this.endSize,
    required this.imageUrl,
    required this.onDone,
  });

  @override
  State<_FlyingImage> createState() => _FlyingImageState();
}

class _FlyingImageState extends State<_FlyingImage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        cartBumpNotifier.value++; // cart icon bounce
        widget.onDone();
      }
    });
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Offset get _startCenter =>
      widget.start +
      Offset(widget.startSize.width / 2, widget.startSize.height / 2);
  Offset get _endCenter =>
      widget.end + Offset(widget.endSize.width / 2, widget.endSize.height / 2);

  // Quadratic bezier (arc) between two points.
  Offset _bezier(Offset p0, Offset p1, Offset p2, double t) {
    final u = 1 - t;
    return p0 * (u * u) + p1 * (2 * u * t) + p2 * (t * t);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = Curves.easeInOutCubic.transform(_c.value);
        final sc = _startCenter;
        final ec = _endCenter;
        // Control point dono ke upar → upar ki taraf arc.
        final control = Offset(
          (sc.dx + ec.dx) / 2,
          math.min(sc.dy, ec.dy) - 70,
        );
        final center = _bezier(sc, control, ec, t);
        final scale = ui.lerpDouble(
          1.0,
          widget.endSize.width / widget.startSize.width,
          t,
        )!;
        final w = widget.startSize.width * scale;
        final h = widget.startSize.height * scale;
        // End ke paas fade out.
        final opacity = _c.value < 0.82
            ? 1.0
            : (1 - (_c.value - 0.82) / 0.18).clamp(0.0, 1.0);

        return Positioned(
          left: center.dx - w / 2,
          top: center.dy - h / 2,
          width: w,
          height: h,
          child: IgnorePointer(
            child: Opacity(
              opacity: opacity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md * scale),
                child: Image.network(
                  widget.imageUrl,
                  width: w,
                  height: h,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
