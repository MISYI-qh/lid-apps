import 'package:flutter/material.dart';
import 'icons.dart';
import 'media.dart';
import 'mediaview.dart';
import 'store.dart';
import 'widgets.dart';

/// Media ganda (kamera depan + belakang). Item: {k, k2, kind, swap, ox, oy}
/// k = kamera belakang, k2 = kamera depan. swap=true -> depan jadi latar, belakang jadi kotak kecil.
/// ox/oy = posisi kotak kecil (0..1) di dalam area latar.
bool isDual(M it) => it['k2'] != null;

Widget _layer(String k, bool video, {bool overlay = true}) => video ? VideoThumb(k, overlay: overlay) : MediaImage(k);

class DualMedia extends StatefulWidget {
  final M item; final bool editable; final VoidCallback? onChanged, onInsetTap;
  const DualMedia(this.item, {super.key, this.editable = false, this.onChanged, this.onInsetTap});
  @override
  State<DualMedia> createState() => _DMS();
}
class _DMS extends State<DualMedia> {
  @override
  Widget build(BuildContext c) {
    final it = widget.item;
    final video = it['kind'] == 'video';
    final swap = it['swap'] == true;
    final mainK = (swap ? it['k2'] : it['k']) as String, smallK = (swap ? it['k'] : it['k2']) as String;
    final ox = ((it['ox'] ?? .04) as num).toDouble(), oy = ((it['oy'] ?? .03) as num).toDouble();
    return LayoutBuilder(builder: (_, bc) {
      final w = bc.maxWidth, h = bc.maxHeight;
      final iw = w * .32, ih = iw * 4 / 3;
      final rx = (w - iw).clamp(1.0, 9999.0), ry = (h - ih).clamp(1.0, 9999.0);
      return Stack(fit: StackFit.expand, children: [
        Positioned.fill(child: _layer(mainK, video, overlay: !widget.editable)),
        Positioned(
          left: ox.clamp(0.0, 1.0) * rx, top: oy.clamp(0.0, 1.0) * ry, width: iw, height: ih,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onInsetTap,
            onPanUpdate: widget.editable ? (d) {
              it['ox'] = (ox + d.delta.dx / rx).clamp(0.0, 1.0);
              it['oy'] = (oy + d.delta.dy / ry).clamp(0.0, 1.0);
              setState(() {});
              widget.onChanged?.call();
            } : null,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white, width: 2.4),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(.45), blurRadius: 14, offset: const Offset(0, 5))],
              ),
              child: ClipRRect(borderRadius: BorderRadius.circular(13.5), child: SizedBox.expand(child: _layer(smallK, video, overlay: false))),
            ),
          ),
        ),
      ]);
    });
  }
}

/// Editor: pilih mana latar dan mana yang kecil, lalu geser kotak kecil ke posisi yang diinginkan.
class DualEditor extends StatefulWidget {
  final M item;
  const DualEditor(this.item, {super.key});
  @override
  State<DualEditor> createState() => _DES();
}
class _DES extends State<DualEditor> {
  late final M it = M.from(widget.item);
  void swap() => setState(() => it['swap'] = it['swap'] != true);
  @override
  Widget build(BuildContext c) => Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(child: Column(children: [
          Padding(padding: const EdgeInsets.all(6), child: Row(children: [
            IconBtn('x', color: Colors.white, onTap: () => Navigator.pop(c)),
            const Spacer(),
            Text(t('Atur tampilan', 'Arrange'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
            const Spacer(),
            const SizedBox(width: 48),
          ])),
          Expanded(child: Padding(padding: const EdgeInsets.fromLTRB(18, 8, 18, 8), child: Center(child: AspectRatio(
            aspectRatio: 3 / 4,
            child: Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: Colors.white.withOpacity(.08), blurRadius: 40)]),
              child: ClipRRect(borderRadius: BorderRadius.circular(28), child: DualMedia(it, editable: true, onInsetTap: swap)),
            ),
          )))),
          Padding(padding: const EdgeInsets.fromLTRB(24, 0, 24, 6), child: Text(t('Geser kotak kecil ke mana saja. Ketuk kotak kecil atau tombol Tukar untuk menukar latar.', 'Drag the small box anywhere. Tap it or press Swap to switch which is the background.'), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white60, fontSize: 12.5, height: 1.4))),
          Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 16), child: Row(children: [
            Expanded(child: OutlinedButton.icon(
              icon: const Ic('swap', size: 18, color: Colors.white), label: Text(t('Tukar', 'Swap'), style: const TextStyle(color: Colors.white)),
              style: OutlinedButton.styleFrom(backgroundColor: Colors.white12, foregroundColor: Colors.white, elevation: 0, side: const BorderSide(color: Colors.white30, width: 1.4)), onPressed: swap)),
            const SizedBox(width: 12),
            Expanded(child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
              onPressed: () => Navigator.pop(c, it), child: Text(t('Selesai', 'Done')))),
          ])),
        ])),
      );
}
