import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'camera.dart';
import 'icons.dart';
import 'media.dart';
import 'mediaview.dart';
import 'platform.dart';
import 'store.dart';
import 'widgets.dart';

class CreatePage extends StatefulWidget {
  final M? edit;
  const CreatePage({super.key, this.edit});
  @override
  State<CreatePage> createState() => _CP();
}
class _CP extends State<CreatePage> {
  final text = TextEditingController();
  String type = 'text', aud = 'all';
  bool anon = false, real = true, posting = false, recording = false;
  List<String> media = [], picks = [];
  String? sound;
  final fresh = <String>{};
  final rec = AudioRecorder();
  int recSec = 0; Timer? rt;
  bool recForSound = false;

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
  void dispose() { rt?.cancel(); rec.dispose(); MediaStore.remove(fresh); super.dispose(); }

  Future<void> dropMedia(Iterable<String> keys) async {
    final k = keys.where(fresh.contains).toList();
    fresh.removeAll(k);
    await MediaStore.remove(k);
  }

  Future<void> shoot() async {
    final r = await Navigator.push<List<XFile>>(context, MaterialPageRoute(builder: (_) => CameraPage(video: type == 'video')));
    if (r == null || r.isEmpty) return;
    final keys = <String>[for (final x in r) await keepXFile(x, type)];
    await dropMedia(media);
    fresh.addAll(keys);
    if (mounted) setState(() => media = keys);
  }

  Future<String?> pickAudio() async {
    final r = await FilePicker.platform.pickFiles(type: FileType.audio, withData: true);
    final f = r?.files.single;
    final bytes = f?.bytes;
    if (f == null || bytes == null) return null;
    final pl = AudioPlayer();
    try {
      await pl.setSource(BytesSource(bytes, mimeType: mimeOf('x.${f.extension ?? 'mp3'}')));
      final d = await pl.getDuration();
      if (d != null && d.inSeconds > 120) { if (mounted) toast(context, t('Audio maksimal 2 menit', 'Audio max 2 minutes')); await pl.dispose(); return null; }
    } catch (_) {}
    await pl.dispose();
    final k = await MediaStore.put(bytes, (f.extension ?? 'mp3').toLowerCase());
    fresh.add(k);
    return k;
  }

  Future<String?> record() async {
    if (recording) {
      rt?.cancel();
      final p = await rec.stop();
      if (mounted) setState(() => recording = false);
      if (p == null) return null;
      final b = await XFile(p).readAsBytes();
      final k = await MediaStore.put(b, kIsWeb ? 'webm' : 'm4a');
      fresh.add(k);
      return k;
    }
    if (!await rec.hasPermission()) { if (mounted) toast(context, t('Izin mikrofon ditolak', 'Microphone denied')); return null; }
    final path = kIsWeb ? '' : '${await tempDirPath()}/rec_${uid()}.m4a';
    await rec.start(RecordConfig(encoder: kIsWeb ? AudioEncoder.opus : AudioEncoder.aacLc), path: path);
    setState(() { recording = true; recSec = 0; });
    rt = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!mounted) return;
      setState(() => recSec++);
      if (recSec >= 120) { final k = await record(); if (k != null) applyRecorded(k); }
    });
    return null;
  }
  void applyRecorded(String k) { if (!mounted) return; setState(() { if (recForSound) { sound = k; } else { media = [k]; } }); }

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
    if (type == 'text' && text.text.trim().isEmpty) return toast(context, t('Tulis sesuatu dulu', 'Write something'));
    if (type != 'text' && media.isEmpty) return toast(context, t('Tambahkan media dulu', 'Add media first'));
    if (aud == 'pick' && picks.isEmpty) return toast(context, t('Pilih orang dulu', 'Pick people first'));
    setState(() => posting = true);
    await Future.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    final d = {'type': type, 'text': text.text.trim(), 'media': media, 'sound': (type == 'audio' || type == 'video') ? null : sound, 'aud': aud, 'picks': picks, 'anon': anon, 'real': real};
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
    if (widget.edit != null) { Navigator.pop(context); } else { text.clear(); setState(() { media = []; sound = null; type = 'text'; picks = []; }); toast(context, t('Terposting', 'Posted')); }
  }

  @override
  Widget build(BuildContext c) {
    final types = ['text', 'photo', 'video', 'audio'];
    return Scaffold(
      appBar: widget.edit != null ? AppBar(title: Text(t('Edit post', 'Edit post')), leading: IconBtn('back', onTap: () => Navigator.pop(c))) : null,
      body: Stack(children: [
        SafeArea(child: ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 40), children: [
          if (widget.edit == null) Padding(padding: const EdgeInsets.only(bottom: 16), child: Text(t('Buat postingan', 'New post'), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -.5))),
          Seg([('text', t('Teks', 'Text')), ('camera', t('Foto', 'Photo')), ('video', 'Video'), ('mic', 'Audio')], types.indexOf(type), (i) async { if (types[i] == type) return; await dropMedia(media); setState(() { type = types[i]; media = []; }); }),
          const SizedBox(height: 16),
          TextField(controller: text, maxLines: 6, minLines: 4, maxLength: 1000, decoration: InputDecoration(hintText: t('Apa yang kamu pikirkan?', "What's on your mind?"))),
          const SizedBox(height: 6),
          if (type == 'photo' || type == 'video') OutlinedButton.icon(icon: const Ic('camera', size: 20), label: Text(media.isEmpty ? t('Buka kamera lid', 'Open lid camera') : t('Ulangi (${media.length} media)', 'Retake (${media.length} media)')), onPressed: shoot),
          if ((type == 'photo' || type == 'video') && media.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 12), child: SizedBox(height: 100, child: ListView(scrollDirection: Axis.horizontal, children: [
            for (final k in media) Padding(padding: const EdgeInsets.only(right: 8), child: ClipRRect(borderRadius: BorderRadius.circular(14), child: SizedBox(width: 80, height: 100, child: type == 'photo' ? MediaImage(k) : VideoThumb(k)))),
          ]))),
          if (type == 'audio') Row(children: [
            Expanded(child: OutlinedButton.icon(icon: const Ic('upload', size: 18), label: const Text('Upload'), onPressed: recording ? null : () async { final p = await pickAudio(); if (p != null) { await dropMedia(media); setState(() => media = [p]); } })),
            const SizedBox(width: 10),
            Expanded(child: OutlinedButton.icon(icon: Ic(recording && !recForSound ? 'stop' : 'mic', size: 18), label: Text(recording && !recForSound ? '$recSec/120s' : t('Rekam', 'Record')), onPressed: () async { recForSound = false; final k = await record(); if (k != null) { await dropMedia(media); applyRecorded(k); } })),
          ]),
          if (type == 'audio' && media.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 10), child: AudioTile(media[0])),
          if (type == 'text' || type == 'photo') ...[
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: OutlinedButton.icon(icon: const Ic('music', size: 18), label: Text(sound == null ? 'Backsound' : t('Ganti', 'Change')), onPressed: recording ? null : () async { final p = await pickAudio(); if (p != null) { if (sound != null) await dropMedia([sound!]); setState(() => sound = p); } })),
              const SizedBox(width: 10),
              Expanded(child: OutlinedButton.icon(icon: Ic(recording && recForSound ? 'stop' : 'mic', size: 18), label: Text(recording && recForSound ? '$recSec/120s' : t('Rekam', 'Record')), onPressed: () async { recForSound = true; final k = await record(); if (k != null) { if (sound != null) await dropMedia([sound!]); applyRecorded(k); } })),
              if (sound != null) IconBtn('x', onTap: () async { await dropMedia([sound!]); setState(() => sound = null); }),
            ]),
            if (sound != null) Padding(padding: const EdgeInsets.only(top: 10), child: AudioTile(sound!, label: 'backsound')),
          ],
          const SizedBox(height: 26),
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
}
