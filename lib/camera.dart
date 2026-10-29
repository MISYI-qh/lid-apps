import 'dart:async';
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
  CameraController? ctl;
  late String mode = widget.selfie ? 'front' : 'back';
  final got = <XFile>[];
  bool rec = false, flash = false, busy = false; int sec = 0; Timer? tm;
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
  void dispose() { tm?.cancel(); ctl?.dispose(); super.dispose(); }

  Future<void> open(CameraLensDirection d) async {
    final cam = find(d) ?? cams.first;
    final old = ctl;
    if (mounted) setState(() => ctl = null);
    await old?.dispose();
    final n = CameraController(cam, ResolutionPreset.max, enableAudio: widget.video);
    try {
      await n.initialize();
      try { minZ = await n.getMinZoomLevel(); maxZ = await n.getMaxZoomLevel(); zoom = minZ; } catch (_) {}
      flash = false;
      if (mounted) { setState(() => ctl = n); } else { await n.dispose(); }
    } catch (e) { if (mounted) setState(() => err = t('Kamera tidak bisa dibuka. Izinkan akses kamera.', 'Cannot open camera. Allow camera access.')); }
  }

  Future<void> toggleFlash() async {
    final c = ctl; if (c == null) return;
    try { await c.setFlashMode(flash ? FlashMode.off : (widget.video ? FlashMode.torch : FlashMode.always)); setState(() => flash = !flash); } catch (_) {}
  }

  Future<void> shutter() async {
    final c = ctl; if (c == null || busy) return;
    busy = true;
    try {
      if (widget.video) {
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
    if (mode == 'both' && got.length == 1) { await open(CameraLensDirection.front); }
    else if (mounted) Navigator.pop(context, got);
  }

  @override
  Widget build(BuildContext c) {
    final ready = ctl != null && ctl!.value.isInitialized;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(child: Column(children: [
        Padding(padding: const EdgeInsets.all(6), child: Row(children: [
          IconBtn('x', color: Colors.white, onTap: () => Navigator.pop(c)),
          const Spacer(),
          if (mode == 'both') Text(got.isEmpty ? '${t('Belakang', 'Back')} 1/2' : '${t('Depan', 'Front')} 2/2', style: const TextStyle(color: Colors.white70)),
          const Spacer(),
          IconBtn(flash ? 'flash' : 'flashoff', color: Colors.white, onTap: ready ? toggleFlash : null),
        ])),
        Expanded(child: err != null
            ? Center(child: Padding(padding: const EdgeInsets.all(32), child: Text(err!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70))))
            : !ready ? const Center(child: RunnerLoader(size: 70))
            : GestureDetector(
                onScaleStart: (_) => baseZoom = zoom,
                onScaleUpdate: (d) async { final z = (baseZoom * d.scale).clamp(minZ, maxZ); zoom = z; try { await ctl!.setZoomLevel(z); } catch (_) {} },
                child: Center(child: CameraPreview(ctl!)))),
        if (rec) Padding(padding: const EdgeInsets.only(top: 8), child: Text('0:${sec.toString().padLeft(2, '0')} / 0:10', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700))),
        Padding(padding: const EdgeInsets.symmetric(vertical: 14), child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          const SizedBox(width: 48),
          GestureDetector(onTap: ready ? shutter : null, child: AnimatedContainer(duration: const Duration(milliseconds: 200), width: 74, height: 74, decoration: BoxDecoration(shape: rec ? BoxShape.rectangle : BoxShape.circle, borderRadius: rec ? BorderRadius.circular(14) : null, color: rec ? Colors.red : Colors.white, border: Border.all(color: Colors.white54, width: 5)))),
          widget.selfie ? const SizedBox(width: 48) : IconBtn('flip', color: Colors.white, size: 26, onTap: rec || cams.isEmpty ? null : () async {
            final v = await pickOption(c, t('Kamera', 'Camera'), {'back': t('Belakang', 'Back'), 'front': t('Depan', 'Front'), 'both': t('Keduanya', 'Both')}, mode);
            if (v != null) { mode = v; got.clear(); await open(v == 'front' ? CameraLensDirection.front : CameraLensDirection.back); }
          }),
        ])),
      ])),
    );
  }
}
