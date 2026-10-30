import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'backsound.dart';
import 'dual.dart';
import 'icons.dart';
import 'media.dart';
import 'store.dart';
import 'widgets.dart';

/// Media ala Threads: ukuran tetap, bisa digeser, campur foto + video, ketuk untuk preview layar penuh
class MediaCarousel extends StatefulWidget {
  final String id; final List<M> items;
  const MediaCarousel({super.key, required this.id, required this.items});
  @override
  State<MediaCarousel> createState() => _MCS();
}
class _MCS extends State<MediaCarousel> {
  final pc = PageController(viewportFraction: .84);
  int cur = 0;
  late final String ht = '${widget.id}_${identityHashCode(this)}';
  @override
  void dispose() { pc.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext c) => LayoutBuilder(builder: (_, bc) {
        final h = (bc.maxWidth * .84 * 1.2).clamp(260.0, 400.0);
        return SizedBox(height: h, child: Stack(children: [
          PageView.builder(
            controller: pc, padEnds: false, itemCount: widget.items.length, onPageChanged: (i) => setState(() => cur = i),
            itemBuilder: (_, i) {
              final it = widget.items[i];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Tap(
                  onTap: () => Navigator.push(c, PageRouteBuilder(opaque: false, transitionDuration: const Duration(milliseconds: 280), reverseTransitionDuration: const Duration(milliseconds: 220), pageBuilder: (_, __, ___) => MediaViewer(id: ht, items: widget.items, start: i), transitionsBuilder: (_, a, __, ch) => FadeTransition(opacity: a, child: ch))),
                  child: Hero(tag: '${ht}_$i', child: ClipRRect(borderRadius: BorderRadius.circular(20), child: SizedBox.expand(child: isDual(it) ? DualMedia(it) : it['kind'] == 'video' ? VideoThumb(it['k']) : MediaImage(it['k'])))),
                ),
              );
            },
          ),
          if (widget.items.length > 1) Positioned(right: 18, top: 10, child: AnimatedSwitcher(duration: const Duration(milliseconds: 200), child: Container(key: ValueKey(cur), padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)), child: Text('${cur + 1}/${widget.items.length}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))))),
        ]));
      });
}

class VideoThumb extends StatefulWidget {
  final String k; final bool overlay;
  const VideoThumb(this.k, {super.key, this.overlay = true});
  @override
  State<VideoThumb> createState() => _VTh();
}
class _VTh extends State<VideoThumb> {
  VideoPlayerController? v;
  bool dead = false;
  @override
  void initState() {
    super.initState();
    () async {
      try {
        final c = await videoController(widget.k);
        await c.setVolume(0);
        await c.initialize();
        if (dead) { c.dispose(); return; }
        setState(() => v = c);
      } catch (_) {}
    }();
  }
  @override
  void dispose() { dead = true; v?.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext c) {
    final ok = v != null && v!.value.isInitialized;
    return Stack(fit: StackFit.expand, children: [
      Container(color: Colors.black),
      if (ok) FittedBox(fit: BoxFit.cover, clipBehavior: Clip.hardEdge, child: SizedBox(width: v!.value.size.width, height: v!.value.size.height, child: VideoPlayer(v!))),
      if (widget.overlay) Center(child: Container(width: 52, height: 52, decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle), child: const Ic('play', color: Colors.white, size: 22))),
      if (ok && widget.overlay) Positioned(left: 12, bottom: 10, child: Text('0:${v!.value.duration.inSeconds.toString().padLeft(2, '0')}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))),
    ]);
  }
}

/// Preview layar penuh: geser antar media, cubit untuk zoom foto, tarik ke atas/bawah untuk menutup
class MediaViewer extends StatefulWidget {
  final String id; final List<M> items; final int start;
  const MediaViewer({super.key, required this.id, required this.items, required this.start});
  @override
  State<MediaViewer> createState() => _MVS();
}
class _MVS extends State<MediaViewer> {
  late final PageController pc = PageController(initialPage: widget.start);
  late int cur = widget.start;
  double dy = 0;
  @override
  void initState() { super.initState(); Backsound.hold(true); }
  @override
  void dispose() { pc.dispose(); Backsound.hold(false); super.dispose(); }
  @override
  Widget build(BuildContext c) => Scaffold(
        backgroundColor: Colors.black.withOpacity((1 - dy.abs() / 400).clamp(0.2, 1.0)),
        body: GestureDetector(
          onVerticalDragUpdate: (d) => setState(() => dy += d.delta.dy),
          onVerticalDragEnd: (d) { if (dy.abs() > 120 || (d.primaryVelocity ?? 0).abs() > 700) { Navigator.pop(c); } else { setState(() => dy = 0); } },
          child: Stack(children: [
            Transform.translate(offset: Offset(0, dy), child: PageView.builder(
              controller: pc, itemCount: widget.items.length, onPageChanged: (i) => setState(() => cur = i),
              itemBuilder: (_, i) => isDual(widget.items[i])
                  ? ViewerDual(widget.items[i], active: i == cur)
                  : widget.items[i]['kind'] == 'video'
                  ? ViewerVideo(widget.items[i]['k'], active: i == cur, tag: '${widget.id}_$i')
                  : InteractiveViewer(minScale: 1, maxScale: 4, child: Center(child: Hero(tag: '${widget.id}_$i', child: MediaImage(widget.items[i]['k'], fit: BoxFit.contain)))),
            )),
            SafeArea(child: Padding(padding: const EdgeInsets.all(6), child: Row(children: [
              IconBtn('x', color: Colors.white, onTap: () => Navigator.pop(c)),
              const Spacer(),
              if (widget.items.length > 1) Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5), decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(14)), child: Text('${cur + 1} / ${widget.items.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
              const SizedBox(width: 12),
            ]))),
          ]),
        ),
      );
}

class ViewerVideo extends StatefulWidget {
  final String k, tag; final bool active;
  const ViewerVideo(this.k, {super.key, required this.active, required this.tag});
  @override
  State<ViewerVideo> createState() => _VV();
}
class _VV extends State<ViewerVideo> {
  VideoPlayerController? v;
  bool muted = false, dead = false;
  @override
  void initState() {
    super.initState();
    () async {
      try {
        final c = await videoController(widget.k);
        await c.setLooping(true);
        await c.initialize();
        if (dead) { c.dispose(); return; }
        setState(() => v = c);
        if (widget.active) c.play();
      } catch (_) {}
    }();
  }
  @override
  void didUpdateWidget(ViewerVideo o) {
    super.didUpdateWidget(o);
    final c = v; if (c == null || !c.value.isInitialized) return;
    widget.active ? c.play() : c.pause();
  }
  @override
  void dispose() { dead = true; v?.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext c) {
    final p = v;
    if (p == null || !p.value.isInitialized) return const Center(child: RunnerLoader(size: 70));
    return GestureDetector(
      onTap: () => setState(() => p.value.isPlaying ? p.pause() : p.play()),
      child: Stack(alignment: Alignment.center, children: [
        Hero(tag: widget.tag, child: AspectRatio(aspectRatio: p.value.aspectRatio, child: VideoPlayer(p))),
        AnimatedOpacity(opacity: p.value.isPlaying ? 0 : 1, duration: const Duration(milliseconds: 200), child: Container(width: 64, height: 64, decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Ic('play', color: Colors.white, size: 28))),
        Positioned(left: 16, right: 16, bottom: 28, child: Row(children: [
          Expanded(child: VideoProgressIndicator(p, allowScrubbing: true, colors: const VideoProgressColors(playedColor: Colors.white, bufferedColor: Colors.white24, backgroundColor: Colors.white12))),
          IconBtn(muted ? 'volumeoff' : 'volume', color: Colors.white, onTap: () => setState(() { muted = !muted; p.setVolume(muted ? 0 : 1); })),
        ])),
      ]),
    );
  }
}

/// Viewer media ganda: foto = latar + kotak kecil (ketuk kotak untuk menukar); video = dua video diputar bersamaan.
class ViewerDual extends StatefulWidget {
  final M it; final bool active;
  const ViewerDual(this.it, {super.key, required this.active});
  @override
  State<ViewerDual> createState() => _VD();
}
class _VD extends State<ViewerDual> {
  VideoPlayerController? a, b;
  late bool swap = widget.it['swap'] == true;
  bool muted = false, dead = false; Duration last = Duration.zero;
  bool get video => widget.it['kind'] == 'video';
  @override
  void initState() {
    super.initState();
    if (!video) return;
    () async {
      try {
        final ca = await videoController(widget.it['k']), cb = await videoController(widget.it['k2']);
        await ca.setLooping(true); await cb.setLooping(true);
        await ca.initialize(); await cb.initialize();
        if (dead) { ca.dispose(); cb.dispose(); return; }
        ca.addListener(() {
          final p = ca.value.position;
          if (p + const Duration(milliseconds: 800) < last && cb.value.isInitialized) { cb.seekTo(Duration.zero); }
          last = p;
        });
        setState(() { a = ca; b = cb; });
        _vol();
        if (widget.active) { ca.play(); cb.play(); }
      } catch (_) {}
    }();
  }
  void _vol() {
    final x = a, y = b; if (x == null || y == null) return;
    final main = swap ? y : x, small = swap ? x : y;
    main.setVolume(muted ? 0 : 1); small.setVolume(0);
  }
  @override
  void didUpdateWidget(ViewerDual o) {
    super.didUpdateWidget(o);
    final x = a, y = b; if (x == null || y == null) return;
    if (widget.active) { x.play(); y.play(); } else { x.pause(); y.pause(); }
  }
  @override
  void dispose() { dead = true; a?.dispose(); b?.dispose(); super.dispose(); }

  Widget inset(Widget child, double iw, double ih) => Container(
      width: iw, height: ih,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white, width: 2.4), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.5), blurRadius: 14, offset: const Offset(0, 5))]),
      child: ClipRRect(borderRadius: BorderRadius.circular(13.5), child: child));

  @override
  Widget build(BuildContext c) {
    final it = widget.it;
    final ox = ((it['ox'] ?? .04) as num).toDouble(), oy = ((it['oy'] ?? .03) as num).toDouble();
    if (!video) {
      final m = M.from(it)..['swap'] = swap;
      return Center(child: Padding(padding: const EdgeInsets.all(12), child: AspectRatio(aspectRatio: 3 / 4, child: ClipRRect(borderRadius: BorderRadius.circular(24), child: DualMedia(m, onInsetTap: () => setState(() => swap = !swap))))));
    }
    final x = a, y = b;
    if (x == null || y == null || !x.value.isInitialized || !y.value.isInitialized) return const Center(child: RunnerLoader(size: 70));
    final main = swap ? y : x, small = swap ? x : y;
    return GestureDetector(
      onTap: () => setState(() { if (x.value.isPlaying) { x.pause(); y.pause(); } else { x.play(); y.play(); } }),
      child: Stack(alignment: Alignment.center, children: [
        Center(child: AspectRatio(aspectRatio: main.value.aspectRatio, child: LayoutBuilder(builder: (_, bc) {
          final iw = bc.maxWidth * .32, ih = iw / small.value.aspectRatio;
          final rx = (bc.maxWidth - iw).clamp(1.0, 9999.0), ry = (bc.maxHeight - ih).clamp(1.0, 9999.0);
          return Stack(children: [
            Positioned.fill(child: VideoPlayer(main)),
            Positioned(left: ox.clamp(0.0, 1.0) * rx, top: oy.clamp(0.0, 1.0) * ry, child: GestureDetector(
              onTap: () => setState(() { swap = !swap; _vol(); }),
              child: inset(FittedBox(fit: BoxFit.cover, clipBehavior: Clip.hardEdge, child: SizedBox(width: small.value.size.width, height: small.value.size.height, child: VideoPlayer(small))), iw, ih))),
          ]);
        }))),
        AnimatedOpacity(opacity: x.value.isPlaying ? 0 : 1, duration: const Duration(milliseconds: 200), child: IgnorePointer(child: Container(width: 64, height: 64, decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Ic('play', color: Colors.white, size: 28)))),
        Positioned(left: 16, right: 16, bottom: 28, child: Row(children: [
          Expanded(child: VideoProgressIndicator(x, allowScrubbing: false, colors: const VideoProgressColors(playedColor: Colors.white, bufferedColor: Colors.white24, backgroundColor: Colors.white12))),
          IconBtn(muted ? 'volumeoff' : 'volume', color: Colors.white, onTap: () => setState(() { muted = !muted; _vol(); })),
        ])),
      ]),
    );
  }
}

class AudioTile extends StatefulWidget {
  final String k; final String? label;
  const AudioTile(this.k, {super.key, this.label});
  @override
  State<AudioTile> createState() => _AT();
}
class _AT extends State<AudioTile> {
  final pl = AudioPlayer();
  bool playing = false, loaded = false; Duration pos = Duration.zero, dur = Duration.zero;
  @override
  void initState() {
    super.initState();
    pl.onPositionChanged.listen((p) { if (mounted) setState(() => pos = p); });
    pl.onDurationChanged.listen((d) { if (mounted) setState(() => dur = d); });
    pl.onPlayerComplete.listen((_) { if (mounted) setState(() { playing = false; loaded = false; pos = Duration.zero; }); });
  }
  @override
  void dispose() { pl.dispose(); super.dispose(); }
  Future<void> toggle() async {
    if (playing) { await pl.pause(); setState(() => playing = false); return; }
    if (!loaded) {
      final b = await MediaStore.get(widget.k);
      if (b == null) return;
      await pl.play(BytesSource(b, mimeType: mimeOf(widget.k)));
      loaded = true;
    } else { await pl.resume(); }
    if (mounted) setState(() => playing = true);
  }
  String fmt(Duration d) => '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  @override
  Widget build(BuildContext c) => Container(
      margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.fromLTRB(4, 0, 16, 0),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), color: Theme.of(c).colorScheme.onSurface.withOpacity(.05)),
      child: Row(children: [
        IconBtn(playing ? 'pause' : 'play', size: 20, onTap: toggle),
        Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(minHeight: 3, backgroundColor: Colors.grey.withOpacity(.25), value: dur.inMilliseconds == 0 ? 0 : (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0)))),
        const SizedBox(width: 12),
        Text(widget.label ?? fmt(playing || pos > Duration.zero ? pos : dur), style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ]));
}
