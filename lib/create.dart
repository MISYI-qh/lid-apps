import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'camera.dart';
import 'dual.dart';
import 'icons.dart';
import 'media.dart';
import 'mediaview.dart';
import 'platform.dart';
import 'store.dart';
import 'widgets.dart';

/// Composer: satu postingan bisa campur teks (tanpa batas), foto, video (maks 10 dtk), dan audio (maks 2 menit).
class CreatePage extends StatefulWidget {
  final M? edit;
  const CreatePage({super.key, this.edit});
  @override
  State<CreatePage> createState() => _CP();
}
class _CP extends State<CreatePage> {
  final text = TextEditingController();
  String aud = 'all';
  bool anon = false, real = true, posting = false, recording = false;
  List<M> items = [];
  M? audio;
  List<String> picks = [];
  final fresh = <String>{};
  final rec = AudioRecorder();
  int recSec = 0; Timer? rt;

  @override
  void initState() {
    super.initState();
    final e = widget.edit;
    if (e != null) {
      text.text = e['text'] ?? ''; aud = e['aud']; anon = e['anon'] == true; real = e['real'] == true;
      items = itemsOf(e); audio = audioOf(e); picks = List<String>.from(e['picks'] ?? []);
    } else { aud = S.me['defAud'] ?? 'all'; }
  }
  @override
  void dispose() { rt?.cancel(); rec.dispose(); MediaStore.remove(fresh.toList()); super.dispose(); }

  Future<void> dropKeys(Iterable<String> keys) async {
    final k = keys.where(fresh.contains).toList();
    fresh.removeAll(k);
    await MediaStore.remove(k);
  }

  Future<void> addMedia(String kind) async {
    if (items.length >= 10) return toast(context, t('Maksimal 10 foto/video per postingan', 'Max 10 photos/videos per post'));
    final r = await Navigator.push<List<XFile>>(context, MaterialPageRoute(builder: (_) => CameraPage(video: kind == 'video')));
    if (r == null || r.isEmpty) return;
    final added = <M>[];
    if (r.length >= 2) {
      final k1 = await keepXFile(r[0], kind), k2 = await keepXFile(r[1], kind);
      fresh..add(k1)..add(k2);
      final it = <String, dynamic>{'k': k1, 'k2': k2, 'kind': kind, 'swap': false, 'ox': .04, 'oy': .03};
      final e = await Navigator.push<M>(context, MaterialPageRoute(builder: (_) => DualEditor(it)));
      added.add(e ?? it);
    } else {
      for (final x in r) { final k = await keepXFile(x, kind); fresh.add(k); added.add({'k': k, 'kind': kind}); }
    }
    if (mounted) setState(() => items.addAll(added));
  }

  Future<void> removeItem(int i) async {
    final ks = [items[i]['k'] as String, if (items[i]['k2'] != null) items[i]['k2'] as String];
    setState(() => items.removeAt(i));
    await dropKeys(ks);
  }

  Future<void> setAudio(String k) async {
    final old = audio?['k'];
    if (mounted) setState(() => audio = {'k': k, 'back': audio?['back'] == true});
    if (old != null) await dropKeys([old as String]);
  }

  Future<void> pickAudio() async {
    final r = await FilePicker.pickFiles(type: FileType.audio, withData: true);
    final f = r?.files.single;
    final bytes = f?.bytes;
    if (f == null || bytes == null) return;
    final pl = AudioPlayer();
    try {
      await pl.setSource(BytesSource(bytes, mimeType: mimeOf('x.${f.extension ?? 'mp3'}')));
      final d = await pl.getDuration();
      if (d != null && d.inSeconds > 120) { if (mounted) toast(context, t('Audio maksimal 2 menit', 'Audio max 2 minutes')); await pl.dispose(); return; }
    } catch (_) {}
    await pl.dispose();
    final k = await MediaStore.put(bytes, (f.extension ?? 'mp3').toLowerCase());
    fresh.add(k);
    await setAudio(k);
  }

  Future<void> toggleRecord() async {
    if (recording) {
      rt?.cancel();
      final p = await rec.stop();
      if (mounted) setState(() => recording = false);
      if (p == null) return;
      final b = await XFile(p).readAsBytes();
      final k = await MediaStore.put(b, kIsWeb ? 'webm' : 'm4a');
      fresh.add(k);
      await setAudio(k);
      return;
    }
    if (!await rec.hasPermission()) { if (mounted) toast(context, t('Izin mikrofon ditolak', 'Microphone denied')); return; }
    final path = kIsWeb ? '' : '${await tempDirPath()}/rec_${uid()}.m4a';
    await rec.start(RecordConfig(encoder: kIsWeb ? AudioEncoder.opus : AudioEncoder.aacLc), path: path);
    setState(() { recording = true; recSec = 0; });
    rt = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!mounted) return;
      setState(() => recSec++);
      if (recSec >= 120) await toggleRecord();
    });
  }

  Future<void> pickPeople() async {
    final others = S.users.where((u) => u['id'] != S.meId && !S.blockedEither(u['id'], S.meId!)).toList();
    final sel = Set<String>.from(picks);
    await showModalBottomSheet(context: context, showDragHandle: true, isScrollControlled: true, builder: (_) => StatefulBuilder(builder: (ctx, set) => SafeArea(child: ConstrainedBox(constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * .7), child: others.isEmpty ? Empty(t('Belum ada pengguna lain', 'No other users yet')) : ListView(shrinkWrap: true, children: [
      for (final u in others) CheckboxListTile(value: sel.contains(u['id']), title: Text(u['name']), subtitle: Text('@${u['username']}'), onChanged: (v) => set(() => v! ? sel.add(u['id']) : sel.remove(u['id']))),
    ])))));
    setState(() => picks = sel.toList());
  }

  Future<void> post() async {
    if (posting) return;
    if (recording) await toggleRecord();
    if (text.text.trim().isEmpty && items.isEmpty && audio == null) return toast(context, t('Tulis sesuatu atau tambahkan media', 'Write something or add media'));
    if (aud == 'pick' && picks.isEmpty) return toast(context, t('Pilih orang dulu', 'Pick people first'));
    setState(() => posting = true);
    await Future.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    final d = <String, dynamic>{'type': 'mixed', 'text': text.text.trim(), 'items': items, 'audio': audio, 'media': [], 'sound': null, 'aud': aud, 'picks': picks, 'anon': anon, 'real': real};
    if (widget.edit != null) {
      final old = keysOf(widget.edit!).toSet();
      widget.edit!..addAll(d)..['edited'] = true;
      final now = keysOf(widget.edit!).toSet();
      await MediaStore.remove(old.difference(now));
    } else {
      S.posts.add({'id': uid(), 'author': S.meId, 'time': DateTime.now().millisecondsSinceEpoch, ...d});
    }
    fresh.clear();
    S.save();
    if (!mounted) return;
    setState(() => posting = false);
    if (widget.edit != null) { Navigator.pop(context); } else { text.clear(); setState(() { items = []; audio = null; picks = []; }); toast(context, t('Terposting', 'Posted')); }
  }

  Widget attach(String icon, String label, VoidCallback f) => Expanded(child: OutlinedButton.icon(icon: Ic(icon, size: 18), label: Text(label), onPressed: f, style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6))));

  @override
  Widget build(BuildContext c) {
    return Scaffold(
      appBar: widget.edit != null ? AppBar(title: Text(t('Edit post', 'Edit post')), leading: IconBtn('back', onTap: () => Navigator.pop(c))) : null,
      body: Stack(children: [
        SafeArea(child: ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 40), children: [
          if (widget.edit == null) Padding(padding: const EdgeInsets.only(bottom: 16), child: Text(t('Buat postingan', 'New post'), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -.5))),
          TextField(controller: text, maxLines: null, minLines: 5, keyboardType: TextInputType.multiline, decoration: InputDecoration(hintText: t('Apa yang kamu pikirkan?', "What's on your mind?"))),
          const SizedBox(height: 12),
          Row(children: [
            attach('camera', t('Foto', 'Photo'), () => addMedia('photo')), const SizedBox(width: 8),
            attach('video', 'Video', () => addMedia('video')), const SizedBox(width: 8),
            attach('mic', recording ? '$recSec/120s' : 'Audio', () { if (recording) { toggleRecord(); } else { _audioSheet(c); } }),
          ]),
          if (items.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 14), child: SizedBox(height: 104, child: ReorderableListView.builder(
            scrollDirection: Axis.horizontal, buildDefaultDragHandles: true, itemCount: items.length,
            onReorder: (a, b) => setState(() { if (b > a) b--; items.insert(b, items.removeAt(a)); }),
            proxyDecorator: (w, _, __) => Material(color: Colors.transparent, child: w),
            itemBuilder: (_, i) => Padding(key: ValueKey(items[i]['k']), padding: const EdgeInsets.only(right: 8), child: Stack(children: [
              GestureDetector(
                onTap: isDual(items[i]) ? () async { final e = await Navigator.push<M>(context, MaterialPageRoute(builder: (_) => DualEditor(items[i]))); if (e != null && mounted) setState(() => items[i] = e); } : null,
                child: ClipRRect(borderRadius: BorderRadius.circular(14), child: SizedBox(width: 82, height: 104, child: isDual(items[i]) ? DualMedia(items[i]) : items[i]['kind'] == 'video' ? VideoThumb(items[i]['k']) : MediaImage(items[i]['k'])))),
              Positioned(top: 4, right: 4, child: GestureDetector(onTap: () => removeItem(i), child: Container(width: 22, height: 22, decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Center(child: Ic('x', size: 13, color: Colors.white))))),
            ])),
          ))),
          if (items.length > 1) Padding(padding: const EdgeInsets.only(top: 2), child: Text(t('Tahan dan geser untuk mengurutkan · ketuk media ganda untuk mengatur', 'Hold and drag to reorder · tap a dual media to arrange'), style: const TextStyle(color: Colors.grey, fontSize: 12))),
          if (audio != null) ...[
            const SizedBox(height: 14),
            Row(children: [Expanded(child: AudioTile(audio!['k'], label: audio!['back'] == true ? 'backsound' : null)), IconBtn('x', onTap: () async { final k = audio!['k'] as String; setState(() => audio = null); await dropKeys([k]); })]),
            SwitchRow(t('Jadikan backsound', 'Use as backsound'), audio!['back'] == true, (v) => setState(() => audio = {'k': audio!['k'], 'back': v})),
          ],
          const SizedBox(height: 22),
          Text(t('Tampil sebagai', 'Post as'), style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Seg([('user', t('Nama saya', 'My name')), ('ghost', t('Anonim', 'Anonymous'))], anon ? 1 : 0, (i) => setState(() => anon = i == 1)),
          if (anon) Padding(padding: const EdgeInsets.only(top: 8), child: Text(t('Muncul sebagai "Anonim" di feed dan real, dan masuk tab Anonim di profilmu.', 'Shown as "Anonymous" in feed and real, and goes in the Anonymous tab of your profile.'), style: const TextStyle(color: Colors.grey, fontSize: 13))),
          const SizedBox(height: 8),
          Row2(t('Yang bisa melihat', 'Who can see'), value: audLabel(aud) + (aud == 'pick' ? ' (${picks.length})' : ''), onTap: () async { final v = await pickOption(c, t('Yang bisa melihat', 'Who can see'), {for (final k in audKeys) k: audLabel(k)}, aud); if (v != null) { setState(() => aud = v); if (v == 'pick') pickPeople(); } }),
          if (aud == 'pick') Row2(t('Pilih orang', 'Pick people'), value: '${picks.length}', onTap: pickPeople),
          SwitchRow(t('Boleh masuk Real', 'Allow in Real'), real, (v) => setState(() => real = v), sub: t('Bisa muncul di tab Real (acak)', 'Can appear in the Real tab (random)')),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: post, child: Text(widget.edit == null ? t('Posting', 'Post') : t('Simpan perubahan', 'Save changes')))),
        ])),
        if (posting) Positioned.fill(child: Container(color: Theme.of(c).colorScheme.surface.withOpacity(.92), child: Center(child: RunnerLoader(size: 90, label: t('Mengirim...', 'Posting...'))))),
      ]),
    );
  }

  void _audioSheet(BuildContext c) => showModalBottomSheet(context: c, showDragHandle: true, builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row2(t('Upload audio (maks 2 menit)', 'Upload audio (max 2 min)'), icon: 'upload', onTap: () { Navigator.pop(ctx); pickAudio(); }),
        Row2(t('Rekam suara (maks 2 menit)', 'Record voice (max 2 min)'), icon: 'mic', onTap: () { Navigator.pop(ctx); toggleRecord(); }),
      ])));
}
