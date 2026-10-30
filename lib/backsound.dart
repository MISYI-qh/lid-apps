import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'icons.dart';
import 'media.dart';
import 'store.dart';
import 'widgets.dart';

/// Pemutar backsound global. Lagu diputar berulang (loop) selama post-nya masih jadi post aktif di layar,
/// dan berganti/berhenti saat pengguna pindah ke post lain.
class Backsound extends ChangeNotifier {
  static final I = Backsound._();
  Backsound._();
  final AudioPlayer _pl = AudioPlayer();
  String? key, _loaded;
  Object? owner;
  bool on = true, playing = false;
  int _holds = 0, _gen = 0;

  /// Jeda sementara (mis. saat pemutar video layar penuh terbuka).
  static void hold(bool h) {
    I._holds = max(0, I._holds + (h ? 1 : -1));
    I._sync();
  }

  void toggle() { on = !on; _sync(); }

  void claim(String? k, Object o) {
    owner = o;
    if (key == k) return;
    key = k;
    _sync();
  }

  void release(Object o) {
    if (owner != o) return;
    owner = null; key = null;
    _sync();
  }

  Future<void> _sync() async {
    final want = key != null && on && _holds == 0;
    try {
      if (want) {
        if (_loaded != key) {
          final g = ++_gen; final k = key!;
          final b = await MediaStore.get(k);
          if (g != _gen || b == null) return;
          await _pl.setReleaseMode(ReleaseMode.loop);
          await _pl.play(BytesSource(b, mimeType: mimeOf(k)));
          _loaded = k; playing = true;
        } else if (!playing) {
          await _pl.resume(); playing = true;
        }
      } else {
        _gen++;
        if (playing) { await _pl.pause(); playing = false; }
        if (key == null && _loaded != null) { await _pl.stop(); _loaded = null; }
      }
    } catch (_) { playing = false; }
    notifyListeners();
  }
}

/// Menandai tab/halaman mana yang sedang tampil (halaman tersembunyi tidak boleh memutar backsound).
class TabScope extends InheritedWidget {
  final bool active;
  const TabScope({super.key, required this.active, required super.child});
  static bool of(BuildContext c) => c.dependOnInheritedWidgetOfExactType<TabScope>()?.active ?? true;
  @override
  bool updateShouldNotify(TabScope o) => o.active != active;
}

/// Membungkus satu post: bila post ini ada di tengah layar, dialah yang menentukan backsound
/// (lagu miliknya, atau hening bila tidak punya backsound).
class BacksoundWatch extends StatefulWidget {
  final String? k; final bool always; final Widget child;
  const BacksoundWatch({super.key, required this.k, required this.child, this.always = false});
  @override
  State<BacksoundWatch> createState() => _BWS();
}
class _BWS extends State<BacksoundWatch> {
  ScrollPosition? pos;
  bool live = true, pending = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final np = Scrollable.maybeOf(context)?.position;
    if (np != pos) { pos?.removeListener(_soon); pos = np; pos?.addListener(_soon); }
    live = TabScope.of(context) && (ModalRoute.of(context)?.isCurrent ?? true);
    if (!live) { Backsound.I.release(this); } else { _soon(); }
  }
  @override
  void didUpdateWidget(BacksoundWatch o) {
    super.didUpdateWidget(o);
    if (o.k != widget.k) _soon();
  }
  @override
  void dispose() {
    pos?.removeListener(_soon);
    Future.microtask(() => Backsound.I.release(this));
    super.dispose();
  }

  void _soon() {
    if (pending) return;
    pending = true;
    SchedulerBinding.instance.addPostFrameCallback((_) { pending = false; _check(); });
    SchedulerBinding.instance.scheduleFrame();
  }

  void _check() {
    if (!mounted || !live) return;
    if (widget.always) { Backsound.I.claim(widget.k, this); return; }
    final ro = context.findRenderObject();
    if (ro is! RenderBox || !ro.attached || !ro.hasSize) return;
    final top = ro.localToGlobal(Offset.zero).dy, h = ro.size.height;
    final mid = MediaQuery.sizeOf(context).height * .42;
    if (top <= mid && top + h >= mid) Backsound.I.claim(widget.k, this);
  }

  @override
  Widget build(BuildContext c) => widget.child;
}

/// Kartu backsound di dalam post: ketuk untuk menyalakan/mematikan suara (berlaku untuk semua post).
class BacksoundTile extends StatelessWidget {
  final String k;
  const BacksoundTile(this.k, {super.key});
  @override
  Widget build(BuildContext c) {
    final cs = Theme.of(c).colorScheme;
    return ListenableBuilder(listenable: Backsound.I, builder: (_, __) {
      final b = Backsound.I;
      final playing = b.on && b.playing && b.key == k;
      return Tap(
        onTap: b.toggle,
        child: Container(
          height: 50, padding: const EdgeInsets.fromLTRB(6, 0, 16, 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(colors: [cs.onSurface.withOpacity(.07), cs.onSurface.withOpacity(.03)]),
            border: Border.all(color: cs.onSurface.withOpacity(.06)),
          ),
          child: Row(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250), width: 38, height: 38,
              decoration: BoxDecoration(color: cs.onSurface, shape: BoxShape.circle, boxShadow: [BoxShadow(color: cs.onSurface.withOpacity(playing ? .35 : .15), blurRadius: playing ? 14 : 6, offset: const Offset(0, 3))]),
              child: Center(child: Ic(b.on ? (playing ? 'volume' : 'play') : 'volumeoff', size: 18, color: cs.surface)),
            ),
            const SizedBox(width: 12),
            _Eq(playing, cs.onSurface),
            const SizedBox(width: 12),
            Expanded(child: Text('Backsound', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.onSurface.withOpacity(.75)))),
            Text(b.on ? (playing ? t('Memutar', 'Playing') : t('Siap', 'Ready')) : t('Mati', 'Muted'), style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ]),
        ),
      );
    });
  }
}

class _Eq extends StatefulWidget {
  final bool on; final Color col;
  const _Eq(this.on, this.col);
  @override
  State<_Eq> createState() => _EqS();
}
class _EqS extends State<_Eq> with SingleTickerProviderStateMixin {
  late final AnimationController a = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat();
  @override
  void dispose() { a.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext c) => AnimatedBuilder(animation: a, builder: (_, __) => SizedBox(width: 30, height: 22, child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.center, children: [
        for (var i = 0; i < 5; i++) Container(width: 3.5, height: widget.on ? 5 + 15 * (0.5 + 0.5 * sin(a.value * 2 * pi + i * 1.3)) : 5, decoration: BoxDecoration(color: widget.col.withOpacity(widget.on ? .85 : .3), borderRadius: BorderRadius.circular(2))),
      ])));
}
