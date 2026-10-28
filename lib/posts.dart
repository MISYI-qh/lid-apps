import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import 'browser.dart';
import 'create.dart';
import 'icons.dart';
import 'pages.dart';
import 'store.dart';
import 'widgets.dart';

String ago(int ms) {
  final d = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ms));
  if (d.inMinutes < 1) return t('baru saja', 'now');
  if (d.inHours < 1) return '${d.inMinutes}m';
  if (d.inDays < 1) return '${d.inHours}${t('j', 'h')}';
  return '${d.inDays}${t('h', 'd')}';
}

class Avatar extends StatelessWidget {
  final M? u; final double r;
  const Avatar(this.u, {super.key, this.r = 20});
  @override
  Widget build(BuildContext c) {
    final cs = Theme.of(c).colorScheme;
    if (u == null) return CircleAvatar(radius: r, backgroundColor: cs.onSurface.withOpacity(.08), child: Ic('ghost', size: r * 1.1, color: cs.onSurface.withOpacity(.6)));
    if (u!['avatar'] != null && File(u!['avatar']).existsSync()) return CircleAvatar(radius: r, backgroundImage: FileImage(File(u!['avatar'])));
    return CircleAvatar(radius: r, backgroundColor: cs.onSurface, child: Text((u!['name'] as String)[0].toUpperCase(), style: TextStyle(color: cs.surface, fontSize: r * .85, fontWeight: FontWeight.w700)));
  }
}

class PostCard extends StatelessWidget {
  final M p; final int i;
  const PostCard(this.p, {super.key, this.i = 0});

  @override
  Widget build(BuildContext c) {
    final anon = p['anon'] == true;
    final a = anon ? null : S.user(p['author']);
    final ncom = S.comments.where((x) => x['post'] == p['id']).length;
    void open() { if (a != null) Navigator.push(c, fadeRoute(ProfilePage(a['id']))); }
    return Fade(delay: (i > 6 ? 6 : i) * 70, Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 10, 6),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Theme.of(c).dividerColor))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GestureDetector(onTap: open, child: Avatar(a, r: 19)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            GestureDetector(onTap: open, child: Text(anon ? t('Anonim', 'Anonymous') : a?['name'] ?? '?', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
            const SizedBox(width: 8),
            Text(ago(p['time']) + (p['edited'] == true ? ' · ${t('diedit', 'edited')}' : ''), style: const TextStyle(fontSize: 12.5, color: Colors.grey)),
            const Spacer(),
            IconBtn('more', size: 20, onTap: () => _menu(c)),
          ]),
          if ((p['text'] ?? '').toString().isNotEmpty) Padding(padding: const EdgeInsets.only(top: 2, bottom: 10, right: 8), child: LinkText(p['text'], style: const TextStyle(fontSize: 15.5, height: 1.4))),
          if (p['type'] == 'photo' || p['type'] == 'video') Padding(padding: const EdgeInsets.only(bottom: 8), child: MediaCarousel(id: p['id'], video: p['type'] == 'video', media: List<String>.from(p['media']))),
          if (p['type'] == 'audio') Padding(padding: const EdgeInsets.only(right: 8), child: AudioTile(p['media'][0])),
          if (p['sound'] != null) Padding(padding: const EdgeInsets.only(right: 8), child: AudioTile(p['sound'], label: 'backsound')),
          Row(children: [
            IconBtn('chat', size: 21, onTap: () => comments(c, p)),
            Text(ncom == 0 ? '' : '$ncom', style: const TextStyle(fontSize: 13, color: Colors.grey)),
            IconBtn('share', size: 21, onTap: () => Share.share('lid://post/${p['id']}')),
          ]),
        ])),
      ]),
    ));
  }

  void _menu(BuildContext c) {
    final mine = p['author'] == S.meId;
    showModalBottomSheet(context: c, showDragHandle: true, builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Row2(t('Salin link', 'Copy link'), icon: 'link', onTap: () async { Navigator.pop(ctx); await Clipboard.setData(ClipboardData(text: 'lid://post/${p['id']}')); if (c.mounted) ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(t('Link disalin', 'Link copied')))); }),
      if (mine) Row2(t('Edit', 'Edit'), icon: 'edit', onTap: () { Navigator.pop(ctx); Navigator.push(c, fadeRoute(CreatePage(edit: p))); }),
      if (mine) Row2(t('Hapus', 'Delete'), icon: 'trash', danger: true, onTap: () { Navigator.pop(ctx); S.posts.remove(p); S.comments.removeWhere((x) => x['post'] == p['id']); S.save(); }),
      if (!mine) Row2(t('Laporkan', 'Report'), icon: 'flag', danger: true, onTap: () async {
        Navigator.pop(ctx);
        final r = await pickOption(c, t('Alasan laporan', 'Report reason'), {for (final x in [t('Spam', 'Spam'), t('Pelecehan', 'Harassment'), t('Konten tidak pantas', 'Inappropriate'), t('Informasi palsu', 'False info'), t('Lainnya', 'Other')]) x: x}, '');
        if (r != null) { S.reports.add({'id': uid(), 'post': p['id'], 'by': S.meId, 'reason': r}); S.save(); if (c.mounted) ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(t('Laporan terkirim', 'Report sent')))); }
      }),
    ])));
  }
}

void comments(BuildContext c, M p) {
  final ctl = TextEditingController();
  showModalBottomSheet(isScrollControlled: true, showDragHandle: true, context: c, builder: (_) => ListenableBuilder(listenable: S, builder: (ctx, __) {
    final list = S.comments.where((x) => x['post'] == p['id']).toList();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: SizedBox(height: 460, child: Column(children: [
        Text(t('Komentar', 'Comments'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 8),
        Expanded(child: list.isEmpty ? Empty(t('Belum ada komentar', 'No comments yet')) : ListView(children: [for (final x in list) Fade(Padding(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Avatar(S.user(x['by']), r: 16), const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(S.user(x['by'])?['name'] ?? '?', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)), LinkText(x['text'])])),
          if (x['by'] == S.meId) IconBtn('trash', size: 18, onTap: () { S.comments.remove(x); S.save(); }),
        ])))])),
        Padding(padding: const EdgeInsets.fromLTRB(16, 8, 8, 16), child: Row(children: [
          Expanded(child: TextField(controller: ctl, decoration: InputDecoration(hintText: t('Tulis komentar', 'Write a comment')))),
          IconBtn('send', onTap: () { if (ctl.text.trim().isEmpty) return; S.comments.add({'id': uid(), 'post': p['id'], 'by': S.meId, 'text': ctl.text.trim(), 'time': DateTime.now().millisecondsSinceEpoch}); S.notify(p['author'], 'comment', post: p['id']); ctl.clear(); S.save(); }),
        ])),
      ])),
    );
  }));
}

/// Media ala Threads: ukuran tetap, bisa digeser, ketuk untuk preview layar penuh
class MediaCarousel extends StatefulWidget {
  final String id; final bool video; final List<String> media;
  const MediaCarousel({super.key, required this.id, required this.video, required this.media});
  @override
  State<MediaCarousel> createState() => _MCS();
}
class _MCS extends State<MediaCarousel> {
  final pc = PageController(viewportFraction: .84);
  int cur = 0;
  @override
  void dispose() { pc.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext c) => LayoutBuilder(builder: (_, bc) {
        final h = (bc.maxWidth * .84 * 1.2).clamp(260.0, 400.0);
        return SizedBox(height: h, child: Stack(children: [
          PageView.builder(
            controller: pc, padEnds: false, itemCount: widget.media.length, onPageChanged: (i) => setState(() => cur = i),
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Tap(
                onTap: () => Navigator.push(c, PageRouteBuilder(opaque: false, transitionDuration: const Duration(milliseconds: 280), reverseTransitionDuration: const Duration(milliseconds: 220), pageBuilder: (_, __, ___) => MediaViewer(id: widget.id, video: widget.video, media: widget.media, start: i), transitionsBuilder: (_, a, __, ch) => FadeTransition(opacity: a, child: ch))),
                child: Hero(tag: '${widget.id}_$i', child: ClipRRect(borderRadius: BorderRadius.circular(18), child: SizedBox.expand(child: widget.video ? VideoThumb(widget.media[i]) : Image.file(File(widget.media[i]), fit: BoxFit.cover, cacheWidth: 900)))),
              ),
            ),
          ),
          if (widget.media.length > 1) Positioned(right: 18, top: 10, child: AnimatedSwitcher(duration: const Duration(milliseconds: 200), child: Container(key: ValueKey(cur), padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)), child: Text('${cur + 1}/${widget.media.length}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))))),
        ]));
      });
}

class VideoThumb extends StatefulWidget {
  final String path;
  const VideoThumb(this.path, {super.key});
  @override
  State<VideoThumb> createState() => _VTh();
}
class _VTh extends State<VideoThumb> {
  late final VideoPlayerController v = VideoPlayerController.file(File(widget.path))..setVolume(0)..initialize().then((_) { if (mounted) setState(() {}); });
  @override
  void dispose() { v.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext c) {
    final ok = v.value.isInitialized;
    return Stack(fit: StackFit.expand, children: [
      Container(color: Colors.black),
      if (ok) FittedBox(fit: BoxFit.cover, clipBehavior: Clip.hardEdge, child: SizedBox(width: v.value.size.width, height: v.value.size.height, child: VideoPlayer(v))),
      Center(child: Container(width: 52, height: 52, decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle), child: const Ic('play', color: Colors.white, size: 22))),
      if (ok) Positioned(left: 12, bottom: 10, child: Text('0:${v.value.duration.inSeconds.toString().padLeft(2, '0')}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))),
    ]);
  }
}

/// Preview layar penuh: geser antar media, cubit untuk zoom foto, tarik ke bawah/atas untuk menutup
class MediaViewer extends StatefulWidget {
  final String id; final bool video; final List<String> media; final int start;
  const MediaViewer({super.key, required this.id, required this.video, required this.media, required this.start});
  @override
  State<MediaViewer> createState() => _MVS();
}
class _MVS extends State<MediaViewer> {
  late final PageController pc = PageController(initialPage: widget.start);
  late int cur = widget.start;
  double dy = 0;
  @override
  void dispose() { pc.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext c) => Scaffold(
        backgroundColor: Colors.black.withOpacity((1 - dy.abs() / 400).clamp(0.2, 1.0)),
        body: GestureDetector(
          onVerticalDragUpdate: (d) => setState(() => dy += d.delta.dy),
          onVerticalDragEnd: (d) { if (dy.abs() > 120 || (d.primaryVelocity ?? 0).abs() > 700) { Navigator.pop(c); } else { setState(() => dy = 0); } },
          child: Stack(children: [
            Transform.translate(offset: Offset(0, dy), child: PageView.builder(
              controller: pc, itemCount: widget.media.length, onPageChanged: (i) => setState(() => cur = i),
              itemBuilder: (_, i) => widget.video
                  ? ViewerVideo(widget.media[i], active: i == cur, tag: '${widget.id}_$i')
                  : InteractiveViewer(minScale: 1, maxScale: 4, child: Center(child: Hero(tag: '${widget.id}_$i', child: Image.file(File(widget.media[i]), fit: BoxFit.contain)))),
            )),
            SafeArea(child: Padding(padding: const EdgeInsets.all(6), child: Row(children: [
              IconBtn('x', color: Colors.white, onTap: () => Navigator.pop(c)),
              const Spacer(),
              if (widget.media.length > 1) Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5), decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(14)), child: Text('${cur + 1} / ${widget.media.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
              const SizedBox(width: 12),
            ]))),
          ]),
        ),
      );
}

class ViewerVideo extends StatefulWidget {
  final String path, tag; final bool active;
  const ViewerVideo(this.path, {super.key, required this.active, required this.tag});
  @override
  State<ViewerVideo> createState() => _VV();
}
class _VV extends State<ViewerVideo> {
  late final VideoPlayerController v = VideoPlayerController.file(File(widget.path))..setLooping(true)..initialize().then((_) { if (mounted) { setState(() {}); if (widget.active) v.play(); } });
  bool muted = false;
  @override
  void didUpdateWidget(ViewerVideo o) { super.didUpdateWidget(o); if (!v.value.isInitialized) return; widget.active ? v.play() : v.pause(); }
  @override
  void dispose() { v.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext c) {
    if (!v.value.isInitialized) return const Center(child: RunnerLoader(size: 70));
    return GestureDetector(
      onTap: () => setState(() => v.value.isPlaying ? v.pause() : v.play()),
      child: Stack(alignment: Alignment.center, children: [
        Hero(tag: widget.tag, child: AspectRatio(aspectRatio: v.value.aspectRatio, child: VideoPlayer(v))),
        AnimatedOpacity(opacity: v.value.isPlaying ? 0 : 1, duration: const Duration(milliseconds: 200), child: Container(width: 64, height: 64, decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Ic('play', color: Colors.white, size: 28))),
        Positioned(left: 16, right: 16, bottom: 28, child: Row(children: [
          Expanded(child: VideoProgressIndicator(v, allowScrubbing: true, colors: const VideoProgressColors(playedColor: Colors.white, bufferedColor: Colors.white24, backgroundColor: Colors.white12))),
          IconBtn(muted ? 'volumeoff' : 'volume', color: Colors.white, onTap: () => setState(() { muted = !muted; v.setVolume(muted ? 0 : 1); })),
        ])),
      ]),
    );
  }
}

class AudioTile extends StatefulWidget {
  final String path; final String? label;
  const AudioTile(this.path, {super.key, this.label});
  @override
  State<AudioTile> createState() => _AT();
}
class _AT extends State<AudioTile> {
  final pl = AudioPlayer();
  bool playing = false; Duration pos = Duration.zero, dur = Duration.zero;
  @override
  void initState() {
    super.initState();
    pl.onPositionChanged.listen((p) { if (mounted) setState(() => pos = p); });
    pl.onDurationChanged.listen((d) { if (mounted) setState(() => dur = d); });
    pl.onPlayerComplete.listen((_) { if (mounted) setState(() { playing = false; pos = Duration.zero; }); });
  }
  @override
  void dispose() { pl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext c) => Container(
      margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.fromLTRB(4, 0, 16, 0),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), color: Theme.of(c).colorScheme.onSurface.withOpacity(.05)),
      child: Row(children: [
        IconBtn(playing ? 'pause' : 'play', size: 20, onTap: () async { if (playing) { await pl.pause(); } else { await pl.play(DeviceFileSource(widget.path)); } setState(() => playing = !playing); }),
        Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(minHeight: 3, backgroundColor: Colors.grey.withOpacity(.25), value: dur.inMilliseconds == 0 ? 0 : pos.inMilliseconds / dur.inMilliseconds))),
        const SizedBox(width: 12),
        Text(widget.label ?? '${pos.inSeconds}s', style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ]));
}
