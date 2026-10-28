import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'icons.dart';
import 'store.dart';
import 'widgets.dart';

/// Peramban khusus lid (hanya http/https)
class LidBrowser extends StatefulWidget {
  final String url;
  const LidBrowser(this.url, {super.key});
  @override
  State<LidBrowser> createState() => _BS();
}
class _BS extends State<LidBrowser> {
  late final WebViewController w;
  int prog = 0; late String cur; String title = ''; bool canBack = false, canFwd = false;

  @override
  void initState() {
    super.initState();
    cur = widget.url.startsWith('http') ? widget.url : 'https://${widget.url}';
    w = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (p) => setState(() => prog = p),
        onPageStarted: (u) => setState(() => cur = u),
        onPageFinished: (u) async { final tt = await w.getTitle(); final b = await w.canGoBack(), f = await w.canGoForward(); if (mounted) setState(() { title = tt ?? ''; canBack = b; canFwd = f; }); },
        onNavigationRequest: (r) => r.url.startsWith('http') ? NavigationDecision.navigate : NavigationDecision.prevent,
      ))
      ..loadRequest(Uri.parse(cur));
  }

  @override
  Widget build(BuildContext c) {
    final host = Uri.tryParse(cur)?.host ?? cur;
    return Scaffold(
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
            IconBtn('copy', onTap: () { Clipboard.setData(ClipboardData(text: cur)); ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(t('Link disalin', 'Link copied')))); }),
            IconBtn('share', onTap: () => Share.share(cur)),
          ]),
        ),
      ])),
    );
  }
}

final _urlRe = RegExp(r'((?:https?://|www\.)[^\s]+)', caseSensitive: false);

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
      final g = TapGestureRecognizer()..onTap = () => Navigator.push(c, fadeRoute(LidBrowser(u)));
      _gs.add(g);
      spans.add(TextSpan(text: u, recognizer: g, style: const TextStyle(decoration: TextDecoration.underline, fontWeight: FontWeight.w600)));
      i = m.end;
    }
    if (i < widget.text.length) spans.add(TextSpan(text: widget.text.substring(i)));
    return Text.rich(TextSpan(children: spans), style: widget.style);
  }
}
