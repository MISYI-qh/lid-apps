import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'icons.dart';
import 'store.dart';
import 'widgets.dart';

/// Kamera buatan lid: depan, belakang, atau keduanya (berurutan). Tanpa galeri.
/// Mengembalikan List<XFile>. Resolusi mengikuti kemampuan perangkat (preset max).
class CameraPage extends StatefulWidget {
  final bool video, selfie;
  const CameraPage({super.key, required this.video, this.selfie = false});
  @override
  State<CameraPage> createState() => _CamS();
}
class _CamS extends State<CameraPage> {
  List<CameraDescription> cams = [];
  CameraController? ctl, ctl2;
  late String mode = widget.selfie ? 'front' : 'back';
  final got = <XFile>[];
  bool rec = false, flash = false, busy = false; int sec = 0; Timer? tm;
  Uint8List? firstThumb;
  String? err; double zoom = 1, baseZoom = 1, minZ = 1, maxZ = 1;

  CameraDescription? find(CameraLensDirection d) { for (final x in cams) { if (x.lensDirection == d) return x; } return null; }

  @override
  void initState() {
    super.initState();
    () async {
      try {
        cams = await availableCameras();
        if (cams.isEmpty) { setState(() => err = t('Kamera tidak ditemukan', 'No camera found')); return; }
        await open(widget.selfie ? CameraLensDirection.front : CameraLensDirection.back);
      } catch (e) { if (mounted) setState(() => err = t('Kamera tidak bisa dibuka. Izinkan akses kamera.', 'Cannot open camera. Allow camera access.')); }
    }();
  }
  @override
  void dispose() { tm?.cancel(); ctl?.dispose(); ctl2?.dispose(); super.dispose(); }

  Future<void> open(CameraLensDirection d) async {
    final cam = find(d) ?? cams.first;
    final old = ctl, old2 = ctl2;
    if (mounted) setState(() { ctl = null; ctl2 = null; });
    await old?.dispose();
    await old2?.dispose();
    final n = CameraController(cam, ResolutionPreset.max, enableAudio: widget.video);
    try {
      await n.initialize();
      try { minZ = await n.getMinZoomLevel(); maxZ = await n.getMaxZoomLevel(); zoom = minZ; } catch (_) {}
      flash = false;
      if (mounted) { setState(() => ctl = n); } else { await n.dispose(); }
    } catch (e) { if (mounted) setState(() => err = t('Kamera tidak bisa dibuka. Izinkan akses kamera.', 'Cannot open camera. Allow camera access.')); }
  }

  /// Mode Keduanya: buka kamera belakang + depan SEKALIGUS (butuh dukungan kamera ganda dari HP).
  /// Bila HP tidak mendukung, otomatis turun ke mode berurutan (satu ketukan).
  Future<void> openBoth() async {
    final b = find(CameraLensDirection.back), f = find(CameraLensDirection.front);
    if (b == null || f == null || b == f) { await open(CameraLensDirection.back); return; }
    final old = ctl, old2 = ctl2;
    if (mounted) setState(() { ctl = null; ctl2 = null; });
    await old?.dispose();
    await old2?.dispose();
    CameraController? c1, c2;
    try {
      c1 = CameraController(b, ResolutionPreset.high, enableAudio: widget.video);
      await c1.initialize();
      c2 = CameraController(f, ResolutionPreset.medium, enableAudio: false);
      await c2.initialize();
      if (!c1.value.isInitialized || c1.value.hasError || !c2.value.isInitialized || c2.value.hasError) throw StateError('no concurrent');
      flash = false;
      if (mounted) { setState(() { ctl = c1; ctl2 = c2; }); } else { await c1.dispose(); await c2.dispose(); }
    } catch (_) {
      try { await c2?.dispose(); } catch (_) {}
      try { await c1?.dispose(); } catch (_) {}
      await open(CameraLensDirection.back);
      if (mounted) toast(context, t('HP ini tidak bisa membuka dua kamera sekaligus. Dipakai mode otomatis berurutan.', 'This phone cannot open two cameras at once. Using automatic sequential mode.'));
    }
  }

  Future<void> shutterDual(CameraController a, CameraController b) async {
    try {
      if (!widget.video) {
        final r = await Future.wait([a.takePicture(), b.takePicture()]).timeout(const Duration(seconds: 8));
        if (mounted) Navigator.pop(context, <XFile>[r[0], r[1]]);
        return;
      }
      if (!rec) {
        await Future.wait([a.startVideoRecording(), b.startVideoRecording()]);
        setState(() { rec = true; sec = 0; });
        tm = Timer.periodic(const Duration(seconds: 1), (_) { setState(() => sec++); if (sec >= 10) shutter(); });
      } else {
        tm?.cancel();
        final r = await Future.wait([a.stopVideoRecording(), b.stopVideoRecording()]);
        setState(() => rec = false);
        if (mounted) Navigator.pop(context, <XFile>[r[0], r[1]]);
      }
    } catch (_) {
      tm?.cancel(); rec = false;
      final o = ctl2; if (mounted) setState(() => ctl2 = null);
      try { await o?.dispose(); } catch (_) {}
      await open(CameraLensDirection.back);
      if (mounted) toast(context, t('Dua kamera sekaligus gagal. Dipakai mode otomatis berurutan, coba lagi.', 'Dual capture failed. Using automatic sequential mode, try again.'));
    }
  }

  Future<void> toggleFlash() async {
    final c = ctl; if (c == null) return;
    try { await c.setFlashMode(flash ? FlashMode.off : (widget.video ? FlashMode.torch : FlashMode.always)); setState(() => flash = !flash); } catch (_) {}
  }

  Future<void> shutter() async {
    final c = ctl; if (c == null || busy) return;
    busy = true;
    try {
      final c2 = ctl2;
      if (mode == 'both' && c2 != null) { await shutterDual(c, c2); }
      else if (widget.video) {
        if (!rec) {
          await c.startVideoRecording();
          setState(() { rec = true; sec = 0; });
          tm = Timer.periodic(const Duration(seconds: 1), (_) { setState(() => sec++); if (sec >= 10) shutter(); });
        } else {
          tm?.cancel(); final f = await c.stopVideoRecording(); setState(() => rec = false); await done(f);
        }
      } else { final f = await c.takePicture(); await done(f); }
    } catch (_) {}
    busy = false;
  }

  Future<void> done(XFile f) async {
    got.add(f);
    if (mode == 'both' && got.length == 1) {
      if (!widget.video) { try { firstThumb = await f.readAsBytes(); } catch (_) {} }
      await open(CameraLensDirection.front);
      if (!widget.video && mounted && ctl != null) {
        await Future.delayed(const Duration(milliseconds: 700));
        try { got.add(await ctl!.takePicture()); } catch (_) {}
        if (mounted) Navigator.pop(context, got);
      }
    }
    else if (mounted) Navigator.pop(context, got);
  }

  Future<void> setMode(String v) async {
    if (rec || busy || v == mode) return;
    mode = v; got.clear(); firstThumb = null;
    if (v == 'both') { await openBoth(); } else { await open(v == 'front' ? CameraLensDirection.front : CameraLensDirection.back); }
  }

  Widget chip(String v, String label) {
    final on = mode == v;
    return GestureDetector(
      behavior: HitTestBehavior.opaque, onTap: () => setMode(v),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220), curve: Curves.easeOut, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(color: on ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(20)),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: on ? Colors.black : Colors.white70)),
      ),
    );
  }

  @override
  Widget build(BuildContext c) {
    final ready = ctl != null && ctl!.value.isInitialized;
    final second = mode == 'both' && got.isNotEmpty;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(child: Column(children: [
        Padding(padding: const EdgeInsets.all(6), child: Row(children: [
          IconBtn('x', color: Colors.white, onTap: () => Navigator.pop(c)),
          const Spacer(),
          if (mode == 'both') Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(16)),
            child: Text(ctl2 != null ? t('Belakang + Depan', 'Back + Front') : second ? '${t('Depan', 'Front')} 2/2' : '${t('Belakang', 'Back')} 1/2', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          const Spacer(),
          IconBtn(flash ? 'flash' : 'flashoff', color: Colors.white, onTap: ready ? toggleFlash : null),
        ])),
        Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: ClipRRect(borderRadius: BorderRadius.circular(28), child: Container(
          color: const Color(0xFF0E0E0E), width: double.infinity,
          child: err != null
            ? Center(child: Padding(padding: const EdgeInsets.all(32), child: Text(err!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70))))
            : !ready ? const Center(child: RunnerLoader(size: 70))
            : Stack(fit: StackFit.expand, children: [
                GestureDetector(
                  onScaleStart: (_) => baseZoom = zoom,
                  onScaleUpdate: (d) async { final z = (baseZoom * d.scale).clamp(minZ, maxZ); zoom = z; try { await ctl!.setZoomLevel(z); } catch (_) {} },
                  child: Center(child: CameraPreview(ctl!))),
                if (ctl2 != null && ctl2!.value.isInitialized) Positioned(left: 14, top: 14, width: 92, height: 122, child: Container(
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white, width: 2.2), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.5), blurRadius: 12)], color: Colors.black),
                  child: ClipRRect(borderRadius: BorderRadius.circular(13.5), child: FittedBox(fit: BoxFit.cover, clipBehavior: Clip.hardEdge, child: SizedBox(width: 92, height: 92 / ctl2!.value.aspectRatio, child: CameraPreview(ctl2!)))))),
                if (second && ctl2 == null) Positioned(left: 14, top: 14, width: 92, height: 122, child: Container(
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white, width: 2.2), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.5), blurRadius: 12)], color: Colors.black),
                  child: ClipRRect(borderRadius: BorderRadius.circular(13.5), child: firstThumb != null
                      ? Image.memory(firstThumb!, fit: BoxFit.cover)
                      : Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Ic('check', color: Colors.white, size: 26), const SizedBox(height: 4), Text(t('Belakang', 'Back'), style: const TextStyle(color: Colors.white70, fontSize: 11))])))))
              ]),
        )))),
        if (rec) Padding(padding: const EdgeInsets.only(top: 10), child: Text('0:${sec.toString().padLeft(2, '0')} / 0:10', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700))),
        if (!widget.selfie) Padding(padding: const EdgeInsets.only(top: 12), child: Center(child: Container(
          padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(24)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [chip('back', t('Belakang', 'Back')), chip('front', t('Depan', 'Front')), chip('both', t('Keduanya', 'Both'))]),
        ))),
        Padding(padding: const EdgeInsets.symmetric(vertical: 14), child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          const SizedBox(width: 48),
          GestureDetector(onTap: ready ? shutter : null, child: AnimatedContainer(duration: const Duration(milliseconds: 200), width: 74, height: 74, decoration: BoxDecoration(shape: rec ? BoxShape.rectangle : BoxShape.circle, borderRadius: rec ? BorderRadius.circular(14) : null, color: rec ? Colors.red : Colors.white, border: Border.all(color: Colors.white54, width: 5)))),
          widget.selfie || mode == 'both' ? const SizedBox(width: 48) : IconBtn('flip', color: Colors.white, size: 26, onTap: rec || cams.isEmpty ? null : () => setMode(mode == 'back' ? 'front' : 'back')),
        ])),
      ])),
    );
  }
}
