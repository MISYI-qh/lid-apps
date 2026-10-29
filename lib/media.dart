import 'dart:math';
import 'dart:typed_data';
import 'package:camera/camera.dart' show XFile;
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:video_player/video_player.dart';
import 'platform.dart';

/// Penyimpanan media lokal (Hive/IndexedDB di web, Hive di Android). Kunci = nama media.
class MediaStore {
  static late LazyBox _box;
  static final _cache = <String, Uint8List>{};

  static Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openLazyBox('media');
  }

  static Uint8List? cached(String k) => _cache[k];

  static Future<String> put(Uint8List b, String ext) async {
    final k = 'm${DateTime.now().microsecondsSinceEpoch}${Random().nextInt(9999)}.$ext';
    await _box.put(k, b);
    _remember(k, b);
    return k;
  }

  static void _remember(String k, Uint8List b) {
    if (b.length > 4 * 1024 * 1024) return;
    _cache[k] = b;
    if (_cache.length > 40) _cache.remove(_cache.keys.first);
  }

  static Future<Uint8List?> get(String k) async {
    final c = _cache[k];
    if (c != null) return c;
    final v = await _box.get(k);
    if (v == null) return null;
    final b = v is Uint8List ? v : Uint8List.fromList((v as List).cast<int>());
    _remember(k, b);
    return b;
  }

  static Future<void> remove(Iterable<String> keys) async {
    for (final k in keys) { _cache.remove(k); await _box.delete(k); }
  }

  static Future<void> clear() async { _cache.clear(); await _box.clear(); }
}

Future<String> keepXFile(XFile x, String kind) async {
  final bytes = await x.readAsBytes();
  final mt = x.mimeType ?? '';
  String ext;
  if (mt.contains('webm')) { ext = 'webm'; }
  else if (mt.contains('png')) { ext = 'png'; }
  else {
    final n = x.name.contains('.') ? x.name.split('.').last.toLowerCase() : '';
    ext = (n.isNotEmpty && n.length <= 4) ? n : (kind == 'video' ? 'mp4' : kind == 'audio' ? 'm4a' : 'jpg');
  }
  return MediaStore.put(bytes, ext);
}

String mimeOf(String key) {
  final e = key.split('.').last;
  return {'mp3': 'audio/mpeg', 'm4a': 'audio/mp4', 'aac': 'audio/aac', 'wav': 'audio/wav', 'ogg': 'audio/ogg', 'webm': 'audio/webm', 'opus': 'audio/ogg', 'flac': 'audio/flac'}[e] ?? 'audio/mpeg';
}

Future<VideoPlayerController> videoController(String key) async {
  final b = await MediaStore.get(key);
  return makeVideoController(key, b ?? Uint8List(0));
}

class MediaImage extends StatefulWidget {
  final String k; final BoxFit fit; final double? w, h;
  const MediaImage(this.k, {super.key, this.fit = BoxFit.cover, this.w, this.h});
  @override
  State<MediaImage> createState() => _MIS();
}
class _MIS extends State<MediaImage> {
  late Future<Uint8List?> f = MediaStore.get(widget.k);
  @override
  void didUpdateWidget(MediaImage o) { super.didUpdateWidget(o); if (o.k != widget.k) f = MediaStore.get(widget.k); }
  @override
  Widget build(BuildContext c) {
    final b = MediaStore.cached(widget.k);
    if (b != null) return Image.memory(b, fit: widget.fit, width: widget.w, height: widget.h, gaplessPlayback: true);
    return FutureBuilder<Uint8List?>(future: f, builder: (_, s) => s.data == null
        ? Container(width: widget.w, height: widget.h, color: Colors.grey.withOpacity(.15))
        : Image.memory(s.data!, fit: widget.fit, width: widget.w, height: widget.h, gaplessPlayback: true));
  }
}
