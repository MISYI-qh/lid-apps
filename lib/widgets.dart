import 'dart:math';
import 'package:flutter/material.dart';
import 'icons.dart';
import 'store.dart';

/// Manusia lidi: mode 'run' (berlari) atau 'wave' (menyapa)
void drawLidi(Canvas c, Size sz, Color col, {double ph = 0, String mode = 'run', double jump = 0}) {
  final s = sz.height, cx = sz.width / 2;
  final sw = s * 0.05;
  final p = Paint()..color = col..style = PaintingStyle.stroke..strokeWidth = sw..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;
  final run = mode == 'run';
  final a = sin(ph * 2 * pi);
  final bob = run ? cos(ph * 4 * pi).abs() * s * 0.03 : sin(ph * 2 * pi) * s * 0.006;
  final lean = run ? s * 0.05 : 0.0;
  final base = s * 0.95 - bob - jump;
  c.drawOval(Rect.fromCenter(center: Offset(cx, s * 0.97), width: max(4.0, s * 0.34 - jump * 0.6), height: s * 0.035), Paint()..color = col.withOpacity(.1));
  final hip = Offset(cx, base - s * 0.40), neck = Offset(cx + lean, base - s * 0.68), sh = Offset(cx + lean * .9, base - s * 0.63);
  final head = Offset(cx + lean * 1.4, base - s * 0.80);
  final r = s * 0.115;
  Offset pt(Offset o, double ang, double len) => o + Offset(sin(ang) * len, cos(ang) * len);
  c.drawLine(neck, hip, p);
  for (final k in [1, -1]) {
    final ang = run ? k * a * 0.85 : k * 0.16;
    final knee = pt(hip, ang, s * 0.2);
    final bend = run ? 0.15 + 0.9 * max(0.0, -k * a) : 0.0;
    final foot = pt(knee, ang - bend, s * 0.2);
    c.drawPath(Path()..moveTo(hip.dx, hip.dy)..lineTo(knee.dx, knee.dy)..lineTo(foot.dx, foot.dy), p);
  }
  for (final k in [1, -1]) {
    double a1, a2;
    if (run) { a1 = -k * a * 0.8; a2 = a1 + 0.9; }
    else if (k == -1) { a1 = -2.3 + a * 0.1; a2 = -2.9 + a * 0.55; }
    else { a1 = 0.22; a2 = 0.12; }
    final el = pt(sh, a1, s * 0.16);
    final hand = pt(el, a2, s * 0.15);
    c.drawPath(Path()..moveTo(sh.dx, sh.dy)..lineTo(el.dx, el.dy)..lineTo(hand.dx, hand.dy), p);
  }
  c.drawCircle(head, r, p);
  final f = Paint()..color = col..style = PaintingStyle.stroke..strokeWidth = sw * 0.6..strokeCap = StrokeCap.round;
  final fx = head.dx + (run ? r * .15 : 0);
  c.drawLine(Offset(fx - r * .38, head.dy - r * .22), Offset(fx - r * .38, head.dy + r * .02), f);
  c.drawLine(Offset(fx + r * .38, head.dy - r * .22), Offset(fx + r * .38, head.dy + r * .02), f);
  c.drawArc(Rect.fromCenter(center: Offset(fx, head.dy + r * .22), width: r * .7, height: r * .5), 0.35, 2.4, false, f);
  c.drawLine(Offset(head.dx + r * .55, head.dy - r * .85), Offset(head.dx + r * .95, head.dy - r * 1.35), f);
  c.drawLine(Offset(head.dx + r * .55, head.dy - r * .85), Offset(head.dx + r * 1.2, head.dy - r * 1.0), f);
}

class _FigPainter extends CustomPainter {
  final double ph, jump; final Color col; final String mode;
  _FigPainter(this.ph, this.col, {this.mode = 'run', this.jump = 0});
  @override
  void paint(Canvas c, Size s) => drawLidi(c, s, col, ph: ph, mode: mode, jump: jump);
  @override
  bool shouldRepaint(_FigPainter o) => true;
}

/// Manusia lidi interaktif: menyapa terus, ketuk untuk melompat
class LidiFigure extends StatefulWidget {
  final double size;
  const LidiFigure({super.key, this.size = 90});
  @override
  State<LidiFigure> createState() => _LFS();
}
class _LFS extends State<LidiFigure> with TickerProviderStateMixin {
  late final AnimationController a = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();
  late final AnimationController j = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  @override
  void dispose() { a.dispose(); j.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext c) {
    final col = Theme.of(c).colorScheme.onSurface;
    return GestureDetector(
      onTap: () => j.forward(from: 0),
      child: AnimatedBuilder(animation: Listenable.merge([a, j]), builder: (_, __) => CustomPaint(size: Size(widget.size * 0.9, widget.size), painter: _FigPainter(a.value * 3, col, mode: 'wave', jump: sin(j.value * pi) * widget.size * 0.18))),
    );
  }
}

class RunnerLoader extends StatefulWidget {
  final double size; final String? label;
  const RunnerLoader({super.key, this.size = 90, this.label});
  @override
  State<RunnerLoader> createState() => _RL();
}
class _RL extends State<RunnerLoader> with SingleTickerProviderStateMixin {
  late final AnimationController a = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat();
  @override
  void dispose() { a.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext c) {
    final col = Theme.of(c).colorScheme.onSurface;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      AnimatedBuilder(animation: a, builder: (_, __) => CustomPaint(size: Size(widget.size, widget.size), painter: _FigPainter(a.value, col))),
      AnimatedBuilder(animation: a, builder: (_, __) => CustomPaint(size: Size(widget.size * 1.6, 4), painter: _GroundPainter(a.value, col))),
      if (widget.label != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(widget.label!, style: const TextStyle(color: Colors.grey))),
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
  Widget build(BuildContext c) => Padding(padding: const EdgeInsets.all(48), child: Center(child: Fade(Column(mainAxisSize: MainAxisSize.min, children: [const LidiFigure(size: 96), const SizedBox(height: 14), Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey))]))));
}

class LoadingScreen extends StatelessWidget {
  final String? label;
  const LoadingScreen({super.key, this.label});
  @override
  Widget build(BuildContext c) => Scaffold(body: Center(child: RunnerLoader(size: 100, label: label)));
}

Route fadeRoute(Widget w) => PageRouteBuilder(pageBuilder: (_, __, ___) => w, transitionsBuilder: (_, a, __, ch) => FadeTransition(opacity: a, child: SlideTransition(position: Tween(begin: const Offset(0, .03), end: Offset.zero).animate(a), child: ch)));

void toast(BuildContext c, String msg) {
  if (!c.mounted) return;
  ScaffoldMessenger.of(c).hideCurrentSnackBar();
  ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(msg)));
}

Future<bool> confirm(BuildContext c, String title, {String? body, String? ok, bool danger = false}) async {
  final r = await showDialog<bool>(context: c, builder: (ctx) => AlertDialog(
        title: Text(title), content: body == null ? null : Text(body),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t('Batal', 'Cancel'))), TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(ok ?? 'OK', style: TextStyle(color: danger ? Colors.red : null)))]));
  return r ?? false;
}

Future<String?> pickOption(BuildContext c, String title, Map<String, String> opts, String cur) => showModalBottomSheet<String>(
    context: c, showDragHandle: true, isScrollControlled: true,
    builder: (_) => SafeArea(child: ConstrainedBox(constraints: BoxConstraints(maxHeight: MediaQuery.of(c).size.height * .7), child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
          for (final e in opts.entries) ListTile(title: Text(e.value), trailing: e.key == cur ? const Ic('check', size: 20) : null, onTap: () => Navigator.pop(c, e.key)),
        ])))));

class Row2 extends StatelessWidget {
  final String? icon; final String title; final String? value; final VoidCallback? onTap; final bool danger;
  const Row2(this.title, {super.key, this.icon, this.value, this.onTap, this.danger = false});
  @override
  Widget build(BuildContext c) => InkWell(
      onTap: onTap,
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15), child: Row(children: [
        if (icon != null) Padding(padding: const EdgeInsets.only(right: 14), child: Ic(icon!, size: 20, color: danger ? Colors.red : null)),
        Expanded(child: Text(title, style: TextStyle(fontSize: 15, color: danger ? Colors.red : null))),
        if (value != null) Flexible(child: Text(value!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey, fontSize: 14))),
        if (onTap != null) const Padding(padding: EdgeInsets.only(left: 6), child: Ic('chev', size: 16, color: Colors.grey)),
      ])));
}

class SwitchRow extends StatelessWidget {
  final String? icon; final String title; final String? sub; final bool value; final ValueChanged<bool> on;
  const SwitchRow(this.title, this.value, this.on, {super.key, this.icon, this.sub});
  @override
  Widget build(BuildContext c) => Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6), child: Row(children: [
        if (icon != null) Padding(padding: const EdgeInsets.only(right: 14), child: Ic(icon!, size: 20)),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 15)), if (sub != null) Text(sub!, style: const TextStyle(color: Colors.grey, fontSize: 12.5))])),
        Switch(value: value, onChanged: on),
      ]));
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
        behavior: HitTestBehavior.opaque, onTap: () => on(i),
        child: AnimatedContainer(duration: const Duration(milliseconds: 250), curve: Curves.easeOut, padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(color: sel == i ? cs.onSurface : Colors.transparent, borderRadius: BorderRadius.circular(12)),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (items[i].$1.isNotEmpty) Ic(items[i].$1, size: 18, color: sel == i ? cs.surface : cs.onSurface),
              if (items[i].$1.isNotEmpty && items[i].$2.isNotEmpty) const SizedBox(width: 6),
              if (items[i].$2.isNotEmpty) Text(items[i].$2, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: sel == i ? cs.surface : cs.onSurface)),
            ])),
      ))]),
    );
  }
}
