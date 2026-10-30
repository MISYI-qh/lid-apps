import 'package:flutter/material.dart';
import 'browser.dart';
import 'icons.dart';
import 'posts.dart';
import 'profile.dart';
import 'store.dart';
import 'widgets.dart';

class PostDetailPage extends StatefulWidget {
  final String id; final bool focus;
  const PostDetailPage(this.id, {super.key, this.focus = false});
  @override
  State<PostDetailPage> createState() => _PDS();
}
class _PDS extends State<PostDetailPage> {
  final ctl = TextEditingController();
  final fn = FocusNode();
  M? replyTo;
  @override
  void initState() { super.initState(); if (widget.focus) WidgetsBinding.instance.addPostFrameCallback((_) => fn.requestFocus()); }
  @override
  void dispose() { ctl.dispose(); fn.dispose(); super.dispose(); }

  void send(M p) {
    final x = ctl.text.trim();
    if (x.isEmpty) return;
    S.addComment(p, x, parent: replyTo);
    ctl.clear(); setState(() => replyTo = null);
  }

  Widget commentTile(BuildContext c, M p, M cm, {bool reply = false, bool last = false}) {
    final u = S.user(cm['by']);
    final mine = cm['by'] == S.meId;
    final cs = Theme.of(c).colorScheme;
    final dark = Theme.of(c).brightness == Brightness.dark;
    Widget act(String s, VoidCallback f, {bool strong = false}) => Padding(padding: const EdgeInsets.only(right: 6), child: Tap(onTap: f, child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(color: strong ? cs.onSurface.withOpacity(.08) : Colors.transparent, borderRadius: BorderRadius.circular(14)),
        child: Text(s, style: TextStyle(fontSize: 12.5, color: strong ? cs.onSurface : Colors.grey, fontWeight: FontWeight.w700)))));
    final bubble = Container(
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 6),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF151515) : Colors.white,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(22), bottomLeft: Radius.circular(22), bottomRight: Radius.circular(22)),
        border: Border.all(color: dark ? Colors.white.withOpacity(.07) : Colors.black.withOpacity(.04)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(dark ? .45 : .06), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Flexible(child: Text(u?['name'] ?? '?', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: -.1))),
          if (cm['by'] == p['author'] && p['anon'] != true) Container(margin: const EdgeInsets.only(left: 6), padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2), decoration: BoxDecoration(color: cs.onSurface, borderRadius: BorderRadius.circular(8)), child: Text(t('Penulis', 'Author'), style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: cs.surface))),
          const SizedBox(width: 8),
          Text(ago(cm['time']) + (cm['edited'] == true ? ' · ${t('diedit', 'edited')}' : ''), style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ]),
        const SizedBox(height: 3),
        LinkText(cm['text'], style: const TextStyle(fontSize: 14.5, height: 1.4)),
        const SizedBox(height: 4),
        Wrap(children: [
          if (S.canComment(p)) act(t('Balas', 'Reply'), () { setState(() => replyTo = cm); fn.requestFocus(); }, strong: true),
          if (mine) act(t('Edit', 'Edit'), () => _edit(c, cm)),
          if (mine || p['author'] == S.meId) act(t('Hapus', 'Delete'), () async { if (await confirm(c, t('Hapus komentar?', 'Delete comment?'), ok: t('Hapus', 'Delete'), danger: true)) S.deleteComment(cm); }),
          if (!mine) act(t('Laporkan', 'Report'), () async { final r = await pickOption(c, t('Alasan laporan', 'Report reason'), reportReasons(), ''); if (r != null) { S.report('comment', cm['id'], r); if (c.mounted) toast(c, t('Laporan terkirim', 'Report sent')); } }),
        ]),
      ]),
    );
    final r = reply ? 15.0 : 18.0;
    return Fade(Stack(clipBehavior: Clip.none, children: [
      if (reply) Positioned(left: 33, top: -8, bottom: last ? null : 0, height: last ? 34 : null, child: Container(width: 2, decoration: BoxDecoration(color: cs.onSurface.withOpacity(.1), borderRadius: BorderRadius.circular(2)))),
      Padding(
        padding: EdgeInsets.fromLTRB(reply ? 52 : 14, 7, 14, 5),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          GestureDetector(onTap: u == null ? null : () => Navigator.push(c, fadeRoute(ProfilePage(u['id']))), child: Container(
              decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(.14), blurRadius: 8, offset: const Offset(0, 3))]),
              child: Avatar(u, r: reply ? 14 : 17))),
          const SizedBox(width: 9),
          Expanded(child: bubble),
        ]),
      ),
    ]));
  }

  void _edit(BuildContext c, M cm) {
    final e = TextEditingController(text: cm['text']);
    showModalBottomSheet(context: c, isScrollControlled: true, showDragHandle: true, builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: e, maxLines: 4, minLines: 2, autofocus: true),
          const SizedBox(height: 14),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: () { if (e.text.trim().isNotEmpty) { cm['text'] = e.text.trim(); cm['edited'] = true; S.save(); } Navigator.pop(ctx); }, child: Text(t('Simpan', 'Save')))),
        ])));
  }

  @override
  Widget build(BuildContext c) => ListenableBuilder(listenable: S, builder: (_, __) {
        final p = S.post(widget.id);
        if (p == null || !S.visible(p)) return Scaffold(appBar: AppBar(leading: IconBtn('back', onTap: () => Navigator.pop(c))), body: Empty(t('Postingan tidak tersedia', 'Post not available')));
        final top = S.commentsOf(p['id']);
        final can = S.canComment(p);
        return Scaffold(
          appBar: AppBar(title: Text(t('Postingan', 'Post'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)), leading: IconBtn('back', onTap: () => Navigator.pop(c))),
          body: Column(children: [
            Expanded(child: ListView(children: [
              PostCard(p, detail: true),
              Padding(padding: const EdgeInsets.fromLTRB(22, 14, 22, 4), child: Row(children: [
                Text(t('Komentar', 'Comments'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, letterSpacing: -.3)),
                const SizedBox(width: 8),
                Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3), decoration: BoxDecoration(color: Theme.of(c).colorScheme.onSurface.withOpacity(.08), borderRadius: BorderRadius.circular(10)), child: Text('${S.commentCount(p['id'])}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800))),
              ])),
              if (top.isEmpty) Empty(t('Belum ada komentar', 'No comments yet')),
              for (final cm in top) ...[
                commentTile(c, p, cm),
                for (final (j, r) in S.commentsOf(p['id'], parent: cm['id']).indexed) commentTile(c, p, r, reply: true, last: j == S.commentsOf(p['id'], parent: cm['id']).length - 1),
              ],
              const SizedBox(height: 24),
            ])),
            Container(
              margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              decoration: cardDeco(c, radius: 30),
              child: SafeArea(top: false, child: can
                  ? Column(mainAxisSize: MainAxisSize.min, children: [
                      if (replyTo != null) Container(
                        margin: const EdgeInsets.only(bottom: 8, right: 8), padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                        decoration: BoxDecoration(color: Theme.of(c).colorScheme.onSurface.withOpacity(.05), borderRadius: BorderRadius.circular(16)),
                        child: Row(children: [
                          Container(width: 3, height: 18, decoration: BoxDecoration(color: Theme.of(c).colorScheme.onSurface, borderRadius: BorderRadius.circular(2))),
                          const SizedBox(width: 10),
                          Expanded(child: Text('${t('Membalas', 'Replying to')} ${S.user(replyTo!['by'])?['name'] ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600))),
                          IconBtn('x', size: 16, onTap: () => setState(() => replyTo = null)),
                        ])),
                      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Expanded(child: TextField(controller: ctl, focusNode: fn, minLines: 1, maxLines: 4, maxLength: 500, buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                            decoration: InputDecoration(hintText: t('Tulis komentar...', 'Write a comment...'), filled: false, border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none, isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 12)))),
                        const SizedBox(width: 6),
                        ListenableBuilder(listenable: ctl, builder: (_, __) {
                          final ok = ctl.text.trim().isNotEmpty;
                          final cs = Theme.of(c).colorScheme;
                          return Tap(onTap: ok ? () => send(p) : null, child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220), width: 44, height: 44,
                            decoration: BoxDecoration(color: ok ? cs.onSurface : cs.onSurface.withOpacity(.1), shape: BoxShape.circle, boxShadow: ok ? [BoxShadow(color: cs.onSurface.withOpacity(.35), blurRadius: 12, offset: const Offset(0, 5))] : null),
                            child: Center(child: Ic('send', size: 20, color: ok ? cs.surface : Colors.grey))));
                        }),
                      ]),
                    ])
                  : Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Center(child: Text(t('Komentar dibatasi oleh pemilik postingan', 'Comments are restricted by the author'), style: const TextStyle(color: Colors.grey, fontSize: 13))))),
            ),
            const SizedBox(height: 8),
          ]),
        );
      });
}
