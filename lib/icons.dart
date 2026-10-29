import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'widgets.dart';

const _p = <String, String>{
  'home': '<path d="M3 10.5 12 3l9 7.5V20a1 1 0 0 1-1 1h-5v-6H9v6H4a1 1 0 0 1-1-1z"/>',
  'shuffle': '<path d="M16 3h5v5M4 20 21 3M21 16v5h-5M15 15l6 6M4 4l5 5"/>',
  'plus': '<path d="M12 5v14M5 12h14"/>',
  'users': '<circle cx="9" cy="8" r="3.5"/><path d="M2.5 20c0-3.6 2.9-6 6.5-6s6.5 2.4 6.5 6M16 4.6a3.5 3.5 0 0 1 0 6.8M18 14.3c2.2.7 3.5 2.6 3.5 5.7"/>',
  'user': '<circle cx="12" cy="8" r="4"/><path d="M4 21c0-4.4 3.6-7 8-7s8 2.6 8 7"/>',
  'userplus': '<circle cx="9" cy="8" r="4"/><path d="M2 21c0-4 3.1-6.5 7-6.5M18 8v6M15 11h6"/>',
  'search': '<circle cx="11" cy="11" r="7"/><path d="m20 20-3.5-3.5"/>',
  'bell': '<path d="M6 8a6 6 0 0 1 12 0c0 7 3 8 3 8H3s3-1 3-8M10 20a2 2 0 0 0 4 0"/>',
  'chat': '<path d="M21 12a8 8 0 0 1-11.6 7.1L3 21l1.9-5.4A8 8 0 1 1 21 12z"/>',
  'share': '<path d="M12 15V3M7 8l5-5 5 5M5 13v6a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2v-6"/>',
  'more': '<circle cx="5" cy="12" r="1"/><circle cx="12" cy="12" r="1"/><circle cx="19" cy="12" r="1"/>',
  'eye': '<path d="M2 12s3.6-7 10-7 10 7 10 7-3.6 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/>',
  'eyeoff': '<path d="M3 3l18 18M10.6 5.1A9.7 9.7 0 0 1 12 5c6.4 0 10 7 10 7a17 17 0 0 1-3.2 4M6.5 6.6C3.7 8.5 2 12 2 12s3.6 7 10 7a9.6 9.6 0 0 0 4.4-1.1"/>',
  'camera': '<path d="M4 8h3l2-3h6l2 3h3a1 1 0 0 1 1 1v10a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V9a1 1 0 0 1 1-1z"/><circle cx="12" cy="13.5" r="3.5"/>',
  'video': '<rect x="2.5" y="6" width="13" height="12" rx="2"/><path d="m15.5 10.5 6-3.5v10l-6-3.5"/>',
  'mic': '<rect x="9" y="3" width="6" height="11" rx="3"/><path d="M5 11a7 7 0 0 0 14 0M12 18v3"/>',
  'text': '<path d="M5 6h14M5 12h14M5 18h9"/>',
  'x': '<path d="M6 6l12 12M18 6 6 18"/>',
  'check': '<path d="m5 12.5 4.5 4.5L19 7"/>',
  'play': '<path d="M7 4.5v15l13-7.5z"/>',
  'pause': '<path d="M8 5v14M16 5v14"/>',
  'stop': '<rect x="6" y="6" width="12" height="12" rx="2"/>',
  'music': '<path d="M9 18V5l11-2v13"/><circle cx="6" cy="18" r="3"/><circle cx="17" cy="16" r="3"/>',
  'upload': '<path d="M12 16V4M7 9l5-5 5 5M4 16v3a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-3"/>',
  'download': '<path d="M12 4v12M7 11l5 5 5-5M4 20h16"/>',
  'flip': '<path d="M4 9a8 8 0 0 1 14-3l2 2M20 4v4h-4M20 15a8 8 0 0 1-14 3l-2-2M4 20v-4h4"/>',
  'link': '<path d="M10 14a4 4 0 0 0 5.7 0l3-3a4 4 0 0 0-5.7-5.7l-1 1M14 10a4 4 0 0 0-5.7 0l-3 3a4 4 0 0 0 5.7 5.7l1-1"/>',
  'copy': '<rect x="9" y="9" width="11" height="11" rx="2"/><path d="M5 15V6a2 2 0 0 1 2-2h9"/>',
  'trash': '<path d="M4 7h16M10 11v6M14 11v6M6 7l1 13h10l1-13M9 7V4h6v3"/>',
  'edit': '<path d="M4 20h4L19 9l-4-4L4 16z"/>',
  'flag': '<path d="M5 21V4M5 4h11l-2 4 2 4H5"/>',
  'lock': '<rect x="5" y="11" width="14" height="10" rx="2"/><path d="M8 11V8a4 4 0 0 1 8 0v3"/>',
  'logout': '<path d="M9 4H5a1 1 0 0 0-1 1v14a1 1 0 0 0 1 1h4M16 8l4 4-4 4M20 12H9"/>',
  'back': '<path d="M19 12H5M11 6l-6 6 6 6"/>',
  'fwd': '<path d="M5 12h14M13 6l6 6-6 6"/>',
  'refresh': '<path d="M20 11a8 8 0 1 0-2.3 5.7M20 4v7h-7"/>',
  'globe': '<circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3c3 3 3 15 0 18M12 3c-3 3-3 15 0 18"/>',
  'ghost': '<path d="M5 21V11a7 7 0 0 1 14 0v10l-3.5-2.5L12 21l-3.5-2.5z"/><circle cx="9.5" cy="11" r="1"/><circle cx="14.5" cy="11" r="1"/>',
  'sliders': '<path d="M4 7h10M18 7h2M4 17h2M10 17h10"/><circle cx="16" cy="7" r="2"/><circle cx="8" cy="17" r="2"/>',
  'calendar': '<rect x="3.5" y="5" width="17" height="15" rx="2"/><path d="M3.5 10h17M8 3v4M16 3v4"/>',
  'send': '<path d="M21 3 10 14M21 3l-7 18-4-7-7-4z"/>',
  'chev': '<path d="m9 6 6 6-6 6"/>',
  'grid': '<rect x="4" y="4" width="7" height="7" rx="1.5"/><rect x="13" y="4" width="7" height="7" rx="1.5"/><rect x="4" y="13" width="7" height="7" rx="1.5"/><rect x="13" y="13" width="7" height="7" rx="1.5"/>',
  'volume': '<path d="M4 9v6h4l5 4V5L8 9z"/><path d="M16.5 8.5a5 5 0 0 1 0 7M19 6a8.5 8.5 0 0 1 0 12"/>',
  'volumeoff': '<path d="M4 9v6h4l5 4V5L8 9z"/><path d="M17 9l5 6M22 9l-5 6"/>',
  'ban': '<circle cx="12" cy="12" r="9"/><path d="M5.6 5.6l12.8 12.8"/>',
  'info': '<circle cx="12" cy="12" r="9"/><path d="M12 11v5M12 8h.01"/>',
  'shield': '<path d="M12 3l8 3v6c0 5-3.5 8-8 9-4.5-1-8-4-8-9V6z"/>',
  'file': '<path d="M7 3h7l5 5v13H7z"/><path d="M14 3v5h5M10 13h6M10 17h6"/>',
  'help': '<circle cx="12" cy="12" r="9"/><path d="M9.5 9.5a2.5 2.5 0 1 1 3.5 2.3c-.7.4-1 .9-1 1.7M12 17h.01"/>',
  'reply': '<path d="M9 7 4 12l5 5M4 12h10a6 6 0 0 1 6 6"/>',
  'flash': '<path d="M13 3 5 14h6l-1 7 8-11h-6z"/>',
  'flashoff': '<path d="M13 3 5 14h6l-1 7 8-11h-6z"/><path d="M3 3l18 18"/>',
  'bellring': '<path d="M6 8a6 6 0 0 1 12 0c0 7 3 8 3 8H3s3-1 3-8M10 20a2 2 0 0 0 4 0M3 3l2 2M21 3l-2 2"/>',
};

String _hex(Color c) => '#${(c.value & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

class Ic extends StatelessWidget {
  final String n; final double size; final Color? color; final double sw;
  const Ic(this.n, {super.key, this.size = 22, this.color, this.sw = 1.7});
  @override
  Widget build(BuildContext c) {
    final col = color ?? Theme.of(c).colorScheme.onSurface;
    return SvgPicture.string(
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="${_hex(col)}" stroke-width="$sw" stroke-linecap="round" stroke-linejoin="round">${_p[n] ?? ''}</svg>',
        width: size, height: size);
  }
}

class IconBtn extends StatelessWidget {
  final String n; final VoidCallback? onTap; final double size; final Color? color;
  const IconBtn(this.n, {super.key, this.onTap, this.size = 22, this.color});
  @override
  Widget build(BuildContext c) => Tap(onTap: onTap, child: Padding(padding: const EdgeInsets.all(10), child: Ic(n, size: size, color: onTap == null ? Colors.grey : color)));
}

class LidLogo extends StatelessWidget {
  final double size;
  const LidLogo({super.key, this.size = 40});
  @override
  Widget build(BuildContext c) {
    final h = _hex(Theme.of(c).colorScheme.onSurface);
    return SvgPicture.string(
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" fill="none" stroke="$h" stroke-width="4" stroke-linecap="round" stroke-linejoin="round">'
        '<rect x="12" y="8" width="76" height="80"/><path d="M62 8v80M12 46h76M6 92h88M34 8 22 60"/><path stroke-width="2.5" d="M20 14l-2 36"/>'
        '<circle cx="46" cy="52" r="13"/><path stroke-width="2.5" d="M42 56q5 5 10 0M41 49v3M53 49v3M52 40l5-6"/><circle cx="24" cy="62" r="3.5"/><circle cx="44" cy="82" r="3.5"/></svg>',
        width: size, height: size);
  }
}
