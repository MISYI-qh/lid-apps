import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'detail.dart';
import 'icons.dart';
import 'platform.dart';
import 'store.dart';
import 'widgets.dart';

String _norm(String u) => u.toLowerCase().startsWith('http') ? u : 'https://$u';

/// Peramban khusus lid: selalu terbuka di dalam aplikasi (Android: WebView, Web: bingkai tertanam).
class LidBrowser extends StatelessWidget {
  final String url;
  const LidBrowser(this.url, {super.key});
  @override
  Widget build(BuildContext c) => kIsWeb ? _WebFrame(_norm(url)) : _NativeBrowser(_norm(url));
}

class _WebFrame extends StatefulWidget {
  final String url;
  const _WebFrame(this.url);
  @override
  State<_WebFrame> createState() => _WFS();
}
class _WFS extends State<_WebFrame> {
  int n = 0; bool loading = true;
  @override
  void initState() { super.initState(); Future.delayed(const Duration(milliseconds: 1400), () { if (mounted) setState(() => loading = false); }); }
  @override
  Widget build(BuildContext c) {
    final host = Uri.tryParse(widget.url)?.host ?? widget.url;
    return Scaffold(
      body: SafeArea(child: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(4, 4, 4, 4), child: Row(children: [
          IconBtn('x', onTap: () => Navigator.pop(c)),
          Expanded(child: Container(height: 40, padding: const EdgeInsets.symmetric(horizontal: 14), decoration: BoxDecoration(color: Theme.of(c).colorScheme.onSurface.withOpacity(.06), borderRadius: BorderRadius.circular(20)),
              child: Row(children: [Ic(widget.url.startsWith('https') ? 'lock' : 'globe', size: 15), const SizedBox(width: 8), Expanded(child: Text(host, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)))]))),
          IconBtn('refresh', onTap: () => setState(() { n++; loading = true; Future.delayed(const Duration(milliseconds: 1400), () { if (mounted) setState(() => loading = false); }); })),
        ])),
        Expanded(child: Stack(children: [
          Positioned.fill(child: KeyedSubtree(key: ValueKey(n), child: webFrame(widget.url))),
          if (loading) Positioned.fill(child: Container(color: Theme.of(c).colorScheme.surface, child: Center(child: RunnerLoader(size: 80, label: t('Membuka halaman...', 'Opening page...'))))),
        ])),
        Container(
          decoration: BoxDecoration(border: Border(top: BorderSide(color: Theme.of(c).dividerColor))),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            IconBtn('copy', onTap: () { Clipboard.setData(ClipboardData(text: widget.url)); toast(c, t('Link disalin', 'Link copied')); }),
            IconBtn('share', onTap: () => Share.share(widget.url).catchError((_) {})),
            Flexible(child: TextButton(onPressed: () => launchUrl(Uri.parse(widget.url), mode: LaunchMode.externalApplication), child: Text(t('Halaman kosong? Situs memblokir tampilan tertanam', 'Blank? The site blocks embedding'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 11.5, color: Colors.grey)))),
          ]),
        ),
      ])),
    );
  }
}

class _NativeBrowser extends StatefulWidget {
  final String url;
  const _NativeBrowser(this.url);
  @override
  State<_NativeBrowser> createState() => _BS();
}
class _BS extends State<_NativeBrowser> {
  late final WebViewController w;
  int prog = 0; late String cur; String title = ''; bool canBack = false, canFwd = false;

  @override
  void initState() {
    super.initState();
    cur = widget.url;
    w = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (p) { if (mounted) setState(() => prog = p); },
        onPageStarted: (u) { if (mounted) setState(() => cur = u); },
        onPageFinished: (u) async { final tt = await w.getTitle(); final b = await w.canGoBack(), f = await w.canGoForward(); if (mounted) setState(() { title = tt ?? ' '; canBack = b; canFwd = f; }); },
        onNavigationRequest: (r) => r.url.startsWith('http') ? NavigationDecision.navigate : NavigationDecision.prevent,
      ))
      ..loadRequest(Uri.parse(cur));
  }

  @override
  Widget build(BuildContext c) {
    final host = Uri.tryParse(cur)?.host ?? cur;
    return PopScope(canPop: !canBack, onPopInvokedWithResult: (didPop, _) { if (!didPop) w.goBack(); }, child: Scaffold(
      body: SafeArea(child: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(4, 4, 4, 4), child: Row(children: [
          IconBtn('x', onTap: () => Navigator.pop(c)),
          Expanded(child: GestureDetector(
            onTap: () => showDialog(context: c, builder: (_) => AlertDialog(content: SelectableText(cur), actions: [TextButton(onPressed: () => Navigator.pop(c), child: Text(t('Tutup', 'Close')))])),
            child: Container(height: 40, padding: const EdgeInsets.symmetric(horizontal: 14), decoration: BoxDecoration(color: Theme.of(c).colorScheme.onSurface.withOpacity(.06), borderRadius: BorderRadius.circular(20)),
                child: Row(children: [Ic(cur.startsWith('https') ? 'lock' : 'globe', size: 15), const SizedBox(width: 8), Expanded(child: Text(host, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)))])),
          )),
          IconBtn('refresh', onTap: () => w.reload()),
        ])),
        SizedBox(height: 2, child: prog < 100 ? LinearProgressIndicator(value: prog / 100, minHeight: 2, backgroundColor: Colors.transparent) : null),
        Expanded(child: Stack(children: [WebViewWidget(controller: w), if (title.isEmpty && prog < 100) Positioned.fill(child: Container(color: Theme.of(c).colorScheme.surface, child: Center(child: RunnerLoader(size: 80, label: t('Membuka halaman...', 'Opening page...')))))])),
        Container(
          decoration: BoxDecoration(border: Border(top: BorderSide(color: Theme.of(c).dividerColor))),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            IconBtn('back', onTap: canBack ? () => w.goBack() : null),
            IconBtn('fwd', onTap: canFwd ? () => w.goForward() : null),
            IconBtn('copy', onTap: () { Clipboard.setData(ClipboardData(text: cur)); toast(c, t('Link disalin', 'Link copied')); }),
            IconBtn('share', onTap: () => Share.share(cur)),
          ]),
        ),
      ])),
    ));
  }
}

final _urlRe = RegExp(r'((?:https?://|www\.|lid://)[^\s]+|[a-z0-9-]+(?:\.[a-z0-9-]+)*\.(?:com|net|org|id|io|co|me|app|dev|link|xyz|info|gg|tv)(?:/[^\s]*)?)', caseSensitive: false);

void openLink(BuildContext c, String u) {
  final m = RegExp(r'(?:lid://post/|#/post/)([A-Za-z0-9]+)').firstMatch(u);
  if (u.startsWith('lid://') || (m != null && u.contains('#/post/'))) { final id = m?.group(1); if (id != null && S.post(id) != null) { Navigator.push(c, fadeRoute(PostDetailPage(id))); } else { toast(c, t('Postingan tidak ditemukan', 'Post not found')); } return; }
  Navigator.push(c, fadeRoute(LidBrowser(u)));
}

/// Teks dengan URL yang bisa diklik -> peramban lid
class LinkText extends StatefulWidget {
  final String text; final TextStyle? style;
  const LinkText(this.text, {super.key, this.style});
  @override
  State<LinkText> createState() => _LTS();
}
class _LTS extends State<LinkText> {
  final _gs = <TapGestureRecognizer>[];
  @override
  void dispose() { for (final g in _gs) { g.dispose(); } super.dispose(); }
  @override
  Widget build(BuildContext c) {
    for (final g in _gs) { g.dispose(); }
    _gs.clear();
    final spans = <InlineSpan>[]; var i = 0;
    for (final m in _urlRe.allMatches(widget.text)) {
      if (m.start > i) spans.add(TextSpan(text: widget.text.substring(i, m.start)));
      final u = m.group(0)!;
      final g = TapGestureRecognizer()..onTap = () => openLink(c, u);
      _gs.add(g);
      spans.add(TextSpan(text: u, recognizer: g, style: const TextStyle(decoration: TextDecoration.underline, fontWeight: FontWeight.w600)));
      i = m.end;
    }
    if (i < widget.text.length) spans.add(TextSpan(text: widget.text.substring(i)));
    return Text.rich(TextSpan(children: spans), style: widget.style);
  }
}
