import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'icons.dart';
import 'store.dart';
import 'widgets.dart';

Future<String> keepFile(String src) async {
  final dir = Directory('${(await getApplicationDocumentsDirectory()).path}/media')..createSync(recursive: true);
  final ext = src.contains('.') ? src.substring(src.lastIndexOf('.')) : '';
  final dst = '${dir.path}/${uid()}$ext';
  await File(src).copy(dst);
  return dst;
}

class CreatePage extends StatefulWidget {
  final M? edit;
  const CreatePage({super.key, this.edit});
  @override
  State<CreatePage> createState() => _CP();
}
class _CP extends State<CreatePage> {
  final text = TextEditingController();
  String type = 'text', aud = 'all';
  bool anon = false, real = true;
  List<String> media = [], picks = [];
  String? sound;
  final rec = AudioRecorder();
  bool recording = false, posting = false; int recSec = 0; Timer? rt;

  @override
  void initState() {
    super.initState();
    final e = widget.edit;
    if (e != null) {
      text.text = e['text'] ?? ''; type = e['type']; aud = e['aud']; anon = e['anon'] == true; real = e['real'] == true;
      media = List<String>.from(e['media'] ?? []); picks = List<String>.from(e['picks'] ?? []); sound = e['sound'];
    } else { aud = S.me['defAud'] ?? 'all'; }
  }
  @override
  void dispose() { rt?.cancel(); rec.dispose(); super.dispose(); }

  void snack(String s) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));

  Future<void> shoot() async {
    final r = await Navigator.push<List<String>>(context, MaterialPageRoute(builder: (_) => CameraPage(video: type == 'video')));
    if (r != null && r.isNotEmpty) { final k = [for (final x in r) await keepFile(x)]; setState(() => media = k); }
  }

  Future<String?> pickAudio() async {
    final r = await FilePicker.platform.pickFiles(type: FileType.audio);
    final path = r?.files.single.path;
    if (path == null) return null;
    final pl = AudioPlayer();
    await pl.setSourceDeviceFile(path);
    final d = await pl.getDuration();
    await pl.dispose();
    if (d != null && d.inSeconds > 120) { snack(t('Audio maksimal 2 menit', 'Audio max 2 minutes')); return null; }
    return keepFile(path);
  }

  Future<String?> record() async {
    if (recording) { rt?.cancel(); final p = await rec.stop(); setState(() => recording = false); return p == null ? null : keepFile(p); }
    if (!await rec.hasPermission()) { snack(t('Izin mikrofon ditolak', 'Microphone denied')); return null; }
    final dir = await getTemporaryDirectory();
    await rec.start(const RecordConfig(), path: '${dir.path}/${uid()}.m4a');
    setState(() { recording = true; recSec = 0; });
    rt = Timer.periodic(const Duration(seconds: 1), (_) async {
      setState(() => recSec++);
      if (recSec >= 120) { final p = await record(); if (p != null) setState(() => type == 'audio' ? media = [p] : sound = p); }
    });
    return null;
  }

  Future<void> pickPeople() async {
    final others = S.users.where((u) => u['id'] != S.meId).toList();
    final sel = Set<String>.from(picks);
    await showModalBottomSheet(context: context, builder: (_) => StatefulBuilder(builder: (ctx, set) => ListView(children: [
      for (final u in others) CheckboxListTile(value: sel.contains(u['id']), title: Text(u['name']), subtitle: Text('@${u['username']}'), onChanged: (v) => set(() => v! ? sel.add(u['id']) : sel.remove(u['id']))),
    ])));
    setState(() => picks = sel.toList());
  }

  Future<void> post() async {
    if (type == 'text' && text.text.trim().isEmpty) return snack(t('Tulis sesuatu dulu', 'Write something'));
    if (type != 'text' && media.isEmpty) return snack(t('Tambahkan media dulu', 'Add media first'));
    setState(() => posting = true);
    await Future.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    setState(() => posting = false);
    final d = {'type': type, 'text': text.text.trim(), 'media': media, 'sound': type == 'audio' || type == 'video' ? null : sound, 'aud': aud, 'picks': picks, 'anon': anon, 'real': real};
    if (widget.edit != null) { widget.edit!..addAll(d)..['edited'] = true; } else { S.posts.add({'id': uid(), 'author': S.meId, 'time': DateTime.now().millisecondsSinceEpoch, 'likes': [], ...d}); }
    S.save();
    if (widget.edit != null) { Navigator.pop(context); } else { text.clear(); setState(() { media = []; sound = null; type = 'text'; }); snack(t('Terposting', 'Posted')); }
  }

  @override
  Widget build(BuildContext c) {
    final types = ['text', 'photo', 'video', 'audio'];
    return Scaffold(
      appBar: widget.edit != null ? AppBar(title: Text(t('Edit post', 'Edit post')), leading: IconBtn('back', onTap: () => Navigator.pop(c))) : null,
      body: Stack(children: [SafeArea(child: ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 40), children: [
        if (widget.edit == null) Padding(padding: const EdgeInsets.only(bottom: 16), child: Text(t('Buat postingan', 'New post'), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -.5))),
        Seg([('text', t('Teks', 'Text')), ('camera', t('Foto', 'Photo')), ('video', 'Video'), ('mic', 'Audio')], types.indexOf(type), (i) => setState(() { type = types[i]; media = []; })),
        const SizedBox(height: 16),
        TextField(controller: text, maxLines: 6, minLines: 4, decoration: InputDecoration(hintText: t('Apa yang kamu pikirkan?', "What's on your mind?"))),
        const SizedBox(height: 12),
        if (type == 'photo' || type == 'video') OutlinedButton.icon(icon: const Ic('camera', size: 20), label: Text(media.isEmpty ? t('Buka kamera lid', 'Open lid camera') : t('${media.length} media, ulangi', '${media.length} media, retake')), onPressed: shoot),
        if (type == 'audio') Row(children: [
          Expanded(child: OutlinedButton.icon(icon: const Ic('upload', size: 18), label: const Text('Upload'), onPressed: () async { final p = await pickAudio(); if (p != null) setState(() => media = [p]); })),
          const SizedBox(width: 10),
          Expanded(child: OutlinedButton.icon(icon: Ic(recording ? 'stop' : 'mic', size: 18), label: Text(recording ? '$recSec/120s' : t('Rekam', 'Record')), onPressed: () async { final p = await record(); if (p != null) setState(() => media = [p]); })),
        ]),
        if (type == 'audio' && media.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 10), child: Row(children: [const Ic('check', size: 18), const SizedBox(width: 8), Text(t('Audio siap', 'Audio ready'))])),
        if (type == 'text' || type == 'photo') ...[
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: OutlinedButton.icon(icon: const Ic('music', size: 18), label: Text(sound == null ? 'Backsound' : t('Ganti', 'Change')), onPressed: () async { final p = await pickAudio(); if (p != null) setState(() => sound = p); })),
            const SizedBox(width: 10),
            Expanded(child: OutlinedButton.icon(icon: Ic(recording ? 'stop' : 'mic', size: 18), label: Text(recording ? '$recSec/120s' : t('Rekam', 'Record')), onPressed: () async { final p = await record(); if (p != null) setState(() => sound = p); })),
            if (sound != null) IconBtn('x', onTap: () => setState(() => sound = null)),
          ]),
        ],
        const SizedBox(height: 26),
        Text(t('Tampil sebagai', 'Post as'), style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Seg([('user', t('Nama saya', 'My name')), ('ghost', t('Anonim', 'Anonymous'))], anon ? 1 : 0, (i) => setState(() => anon = i == 1)),
        if (anon) Padding(padding: const EdgeInsets.only(top: 8), child: Text(t('Muncul sebagai "Anonim" di feed dan real, dan masuk tab Anonim di profilmu.', 'Shown as "Anonymous" in feed and real, and goes in the Anonymous tab of your profile.'), style: const TextStyle(color: Colors.grey, fontSize: 13))),
        const SizedBox(height: 8),
        Row2(t('Yang bisa melihat', 'Who can see'), value: audLabel(aud) + (aud == 'pick' ? ' (${picks.length})' : ''), onTap: () async { final v = await pickOption(c, t('Yang bisa melihat', 'Who can see'), {for (final k in audKeys) k: audLabel(k)}, aud); if (v != null) { setState(() => aud = v); if (v == 'pick') pickPeople(); } }),
        SwitchListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 20), title: Text(t('Boleh masuk Real', 'Allow in Real'), style: const TextStyle(fontSize: 15)), value: real, onChanged: (v) => setState(() => real = v)),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, child: FilledButton(onPressed: post, child: Text(widget.edit == null ? t('Posting', 'Post') : t('Simpan perubahan', 'Save changes')))),
      ])),
        if (posting) Positioned.fill(child: Container(color: Theme.of(c).colorScheme.surface.withOpacity(.92), child: Center(child: RunnerLoader(size: 90, label: t('Mengirim...', 'Posting...'))))),
      ]),
    );
  }
}

/// Kamera buatan lid: depan, belakang, atau keduanya (berurutan). Tanpa galeri.
class CameraPage extends StatefulWidget {
  final bool video;
  const CameraPage({super.key, required this.video});
  @override
  State<CameraPage> createState() => _CamS();
}
class _CamS extends State<CameraPage> {
  List<CameraDescription> cams = [];
  CameraController? ctl;
  String mode = 'back';
  CameraLensDirection cur = CameraLensDirection.back;
  final got = <String>[];
  bool rec = false; int sec = 0; Timer? tm;

  CameraDescription? find(CameraLensDirection d) { for (final x in cams) { if (x.lensDirection == d) return x; } return null; }

  @override
  void initState() { super.initState(); () async { cams = await availableCameras(); await open(CameraLensDirection.back); }(); }
  @override
  void dispose() { tm?.cancel(); ctl?.dispose(); super.dispose(); }

  Future<void> open(CameraLensDirection d) async {
    final cam = find(d) ?? (cams.isNotEmpty ? cams.first : null);
    if (cam == null) return;
    await ctl?.dispose();
    final n = CameraController(cam, ResolutionPreset.max, enableAudio: widget.video);
    await n.initialize();
    cur = cam.lensDirection;
    if (mounted) setState(() => ctl = n);
  }

  Future<void> shutter() async {
    final c = ctl; if (c == null) return;
    if (widget.video) {
      if (!rec) {
        await c.startVideoRecording(); setState(() { rec = true; sec = 0; });
        tm = Timer.periodic(const Duration(seconds: 1), (_) { setState(() => sec++); if (sec >= 10) shutter(); });
        return;
      }
      tm?.cancel(); final f = await c.stopVideoRecording(); setState(() => rec = false); await done(f.path);
    } else { final f = await c.takePicture(); await done(f.path); }
  }

  Future<void> done(String path) async {
    got.add(path);
    if (mode == 'both' && got.length == 1) { await open(CameraLensDirection.front); if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('Sekarang kamera depan', 'Now the front camera')))); }
    else if (mounted) Navigator.pop(context, got);
  }

  @override
  Widget build(BuildContext c) => Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(child: Column(children: [
          Expanded(child: ctl == null || !ctl!.value.isInitialized ? const Center(child: Text('...', style: TextStyle(color: Colors.white))) : Center(child: CameraPreview(ctl!))),
          if (rec) Text('0:${sec.toString().padLeft(2, '0')} / 0:10', style: const TextStyle(color: Colors.red)),
          Padding(padding: const EdgeInsets.all(12), child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            IconBtn('x', color: Colors.white, onTap: () => Navigator.pop(c)),
            GestureDetector(onTap: shutter, child: AnimatedContainer(duration: const Duration(milliseconds: 200), width: 74, height: 74, decoration: BoxDecoration(shape: rec ? BoxShape.rectangle : BoxShape.circle, borderRadius: rec ? BorderRadius.circular(14) : null, color: rec ? Colors.red : Colors.white, border: Border.all(color: Colors.white54, width: 5)))),
            IconBtn('flip', color: Colors.white, onTap: () async {
              final v = await pickOption(c, t('Kamera', 'Camera'), {'back': t('Belakang', 'Back'), 'front': t('Depan', 'Front'), 'both': t('Keduanya', 'Both')}, mode);
              if (v != null) { mode = v; got.clear(); open(v == 'front' ? CameraLensDirection.front : CameraLensDirection.back); }
            }),
          ])),
        ])),
      );
}
