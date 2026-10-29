import 'dart:js_interop';
import 'dart:ui_web' as ui_web;
import 'package:flutter/widgets.dart';
import 'dart:typed_data';
import 'package:video_player/video_player.dart';
import 'package:web/web.dart' as web;

final _urls = <String, String>{};

Future<String> tempDirPath() async => '';

Future<VideoPlayerController> makeVideoController(String key, Uint8List b) async {
  final url = _urls.putIfAbsent(key, () => web.URL.createObjectURL(web.Blob([b.toJS].toJS, web.BlobPropertyBag(type: key.endsWith('webm') ? 'video/webm' : 'video/mp4'))));
  return VideoPlayerController.networkUrl(Uri.parse(url));
}

final _reg = <String>{};

/// Halaman dibuka di dalam aplikasi (iframe) agar pengguna tidak pindah tab.
Widget webFrame(String url) {
  final type = 'lid-frame-${url.hashCode}';
  if (_reg.add(type)) {
    ui_web.platformViewRegistry.registerViewFactory(type, (int _) {
      final f = web.document.createElement('iframe') as web.HTMLIFrameElement;
      f.src = url;
      f.style.border = 'none';
      f.style.width = '100%';
      f.style.height = '100%';
      f.allow = 'fullscreen; autoplay; encrypted-media; clipboard-write';
      return f;
    });
  }
  return HtmlElementView(viewType: type);
}
