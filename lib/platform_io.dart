import 'package:flutter/widgets.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

Future<String> tempDirPath() async => (await getTemporaryDirectory()).path;

Future<VideoPlayerController> makeVideoController(String key, Uint8List b) async {
  final f = File('${await tempDirPath()}/$key');
  if (!f.existsSync()) await f.writeAsBytes(b, flush: true);
  return VideoPlayerController.file(f);
}

Widget webFrame(String url) => const SizedBox();
