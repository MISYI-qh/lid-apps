import 'dart:math';
import 'package:flutter/material.dart';
import 'icons.dart';
import 'store.dart';

void drawFigure(Canvas c, Offset o, double s, Color col, double ph) {
  final p = Paint()..color = col..style = PaintingStyle.stroke..strokeWidth = s * 0.07..strokeCap = StrokeCap.round;
  final sw = sin(ph * 2 * pi), bob = sin(ph * 4 * pi).abs() * s * 0.05;
  final head = Offset(o.dx, o.dy - s * 0.78 - bob);
  c.drawCircle(head, s * 0.14, p);
  final f = Paint()..color = col..style = PaintingStyle.stroke..strokeWidth = s * 0.03..strokeCap = StrokeCap.round;
  c.drawArc(Rect.fromCircle(center: head.translate(s * 0.02, s * 0.03), radius: s * 0.05), 0.3, 2.5, false, f);
  c.drawLine(head.translate(-s * 0.04, -s * 0.03), head.translate(-s * 0.04, -s * 0.01), f);
  c.drawLine(head.translate(s * 0.06, -s * 0.03), head.translate(s * 0.06, -s * 0.01), f);
  c.drawLine(head.translate(s * 0.06, -s * 0.14), head.translate(s * 0.11, -s * 0.2), f);
  final neck = Offset(o.dx, o.dy - s * 0.64 - bob), hip = Offset(o.dx, o.dy - s * 0.34 - bob), sh = Offset(o.dx, o.dy - s * 0.58 - bob);
  c.drawLine(neck, hip, p);
  Offset limb(Offset a, double ang, double len) => a + Offset(sin(ang) * len, cos(ang) * len);
  for (final k in [1, -1]) {
    c.drawLine(sh, limb(sh, k * sw * 0.9, s * 0.26), p);
    c.drawLine(hip, limb(hip, -k * sw * 0.9, s * 0.36), p);
  }
}

class _FigPainter extends CustomPainter {
  final double ph; final Color col;
  _FigPainter(this.ph, this.col);
  @override
  void paint(Canvas c, Size s) => drawFigure(c, Offset(s.width / 2, s.height - 4), s.height - 8, col, ph);
  @override
  bool shouldRepaint(_FigPainter o) => o.ph != ph;
}

class RunnerLoader extends StatefulWidget {
  final double size; final String? label;
  const RunnerLoader({super.key, this.size = 90, this.label});
  @override
  State<RunnerLoader> createState() => _RL();
}
class _RL extends State<RunnerLoader> with SingleTickerProviderStateMixin {
  late final AnimationController a = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..repeat();
  @override
  void dispose() { a.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext c) {
    final col = Theme.of(c).colorScheme.onSurface;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      AnimatedBuilder(animation: a, builder: (_, __) => CustomPaint(size: Size(widget.size, widget.size), painter: _FigPainter(a.value, col))),
      AnimatedBuilder(animation: a, builder: (_, __) => CustomPaint(size: Size(widget.size * 1.6, 4), painter: _GroundPainter(a.value, col))),
      if (widget.label != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(widget.label!)),
    ]);
  }
}
class _GroundPainter extends CustomPainter {
  final double v; final Color col;
  _GroundPainter(this.v, this.col);
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()..color = col..strokeWidth = 2..strokeCap = StrokeCap.round;
    for (var i = -1; i < 6; i++) {
      final x = (i * 22 - v * 22) % (s.width + 22);
      c.drawLine(Offset(x, 2), Offset(x + 10, 2), p);
    }
  }
  @override
  bool shouldRepaint(_GroundPainter o) => o.v != v;
}

class Fade extends StatefulWidget {
  final Widget child; final int delay;
  const Fade(this.child, {super.key, this.delay = 0});
  @override
  State<Fade> createState() => _FadeS();
}
class _FadeS extends State<Fade> with SingleTickerProviderStateMixin {
  late final AnimationController a = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
  @override
  void initState() { super.initState(); if (widget.delay == 0) { a.forward(); } else { Future.delayed(Duration(milliseconds: widget.delay), () { if (mounted) a.forward(); }); } }
  @override
  void dispose() { a.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext c) {
    final v = CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
    return FadeTransition(opacity: v, child: SlideTransition(position: Tween(begin: const Offset(0, .06), end: Offset.zero).animate(v), child: widget.child));
  }
}

/// Efek tekan: mengecil sedikit saat disentuh
class Tap extends StatefulWidget {
  final Widget child; final VoidCallback? onTap;
  const Tap({super.key, required this.child, this.onTap});
  @override
  State<Tap> createState() => _TapS();
}
class _TapS extends State<Tap> {
  bool d = false;
  @override
  Widget build(BuildContext c) => GestureDetector(
      behavior: HitTestBehavior.opaque, onTap: widget.onTap,
      onTapDown: (_) => setState(() => d = true), onTapUp: (_) => setState(() => d = false), onTapCancel: () => setState(() => d = false),
      child: AnimatedScale(scale: d ? .88 : 1, duration: const Duration(milliseconds: 120), curve: Curves.easeOut, child: widget.child));
}

/// Melayang naik-turun pelan (untuk logo / keadaan kosong)
class Float extends StatefulWidget {
  final Widget child;
  const Float(this.child, {super.key});
  @override
  State<Float> createState() => _FloatS();
}
class _FloatS extends State<Float> with SingleTickerProviderStateMixin {
  late final AnimationController a = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  @override
  void dispose() { a.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext c) => AnimatedBuilder(animation: a, builder: (_, ch) => Transform.translate(offset: Offset(0, -8 * Curves.easeInOut.transform(a.value)), child: ch), child: widget.child);
}

class Empty extends StatelessWidget {
  final String text;
  const Empty(this.text, {super.key});
  @override
  Widget build(BuildContext c) => Padding(padding: const EdgeInsets.all(48), child: Center(child: Fade(Column(mainAxisSize: MainAxisSize.min, children: [Float(const LidLogo(size: 56)), const SizedBox(height: 16), Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey))]))));
}

/// Layar loading: tokoh berlari
class LoadingScreen extends StatelessWidget {
  final String? label;
  const LoadingScreen({super.key, this.label});
  @override
  Widget build(BuildContext c) => Scaffold(body: Center(child: RunnerLoader(size: 100, label: label)));
}

Route fadeRoute(Widget w) => PageRouteBuilder(pageBuilder: (_, __, ___) => w, transitionsBuilder: (_, a, __, ch) => FadeTransition(opacity: a, child: SlideTransition(position: Tween(begin: const Offset(0, .03), end: Offset.zero).animate(a), child: ch)));


Future<String?> pickOption(BuildContext c, String title, Map<String, String> opts, String cur) => showModalBottomSheet<String>(
    context: c, showDragHandle: true,
    builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
          for (final e in opts.entries) ListTile(title: Text(e.value), trailing: e.key == cur ? const Ic('check', size: 20) : null, onTap: () => Navigator.pop(c, e.key)),
        ])));

class Row2 extends StatelessWidget {
  final String? icon; final String title; final String? value; final VoidCallback? onTap; final bool danger;
  const Row2(this.title, {super.key, this.icon, this.value, this.onTap, this.danger = false});
  @override
  Widget build(BuildContext c) => InkWell(
      onTap: onTap,
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15), child: Row(children: [
        if (icon != null) Padding(padding: const EdgeInsets.only(right: 14), child: Ic(icon!, size: 20, color: danger ? Colors.red : null)),
        Expanded(child: Text(title, style: TextStyle(fontSize: 15, color: danger ? Colors.red : null))),
        if (value != null) Text(value!, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        if (onTap != null) const Padding(padding: EdgeInsets.only(left: 6), child: Ic('chev', size: 16, color: Colors.grey)),
      ])));
}

class Seg extends StatelessWidget {
  final List<(String, String)> items; final int sel; final ValueChanged<int> on;
  const Seg(this.items, this.sel, this.on, {super.key});
  @override
  Widget build(BuildContext c) {
    final cs = Theme.of(c).colorScheme;
    return Container(
      padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: cs.onSurface.withOpacity(.06), borderRadius: BorderRadius.circular(16)),
      child: Row(children: [for (var i = 0; i < items.length; i++) Expanded(child: GestureDetector(
        onTap: () => on(i),
        child: AnimatedContainer(duration: const Duration(milliseconds: 250), curve: Curves.easeOut, padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(color: sel == i ? cs.onSurface : Colors.transparent, borderRadius: BorderRadius.circular(12)),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Ic(items[i].$1, size: 18, color: sel == i ? cs.surface : cs.onSurface), if (items[i].$2.isNotEmpty) ...[const SizedBox(width: 6), Text(items[i].$2, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: sel == i ? cs.surface : cs.onSurface))]])),
      ))]),
    );
  }
}
