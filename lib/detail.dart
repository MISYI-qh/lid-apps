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

  Widget commentTile(BuildContext c, M p, M cm, {bool reply = false}) {
    final u = S.user(cm['by']);
    final mine = cm['by'] == S.meId;
    Widget act(String s, VoidCallback f) => Padding(padding: const EdgeInsets.only(right: 16), child: GestureDetector(onTap: f, behavior: HitTestBehavior.opaque, child: Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text(s, style: const TextStyle(fontSize: 12.5, color: Colors.grey, fontWeight: FontWeight.w600)))));
    return Fade(Padding(
      padding: EdgeInsets.fromLTRB(reply ? 62 : 18, 10, 14, 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GestureDetector(onTap: u == null ? null : () => Navigator.push(c, fadeRoute(ProfilePage(u['id']))), child: Avatar(u, r: reply ? 14 : 17)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Text(u?['name'] ?? '?', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)), const SizedBox(width: 8), Text(ago(cm['time']) + (cm['edited'] == true ? ' · ${t('diedit', 'edited')}' : ''), style: const TextStyle(fontSize: 12, color: Colors.grey))]),
          const SizedBox(height: 2),
          LinkText(cm['text'], style: const TextStyle(fontSize: 14.5, height: 1.35)),
          Row(children: [
            if (S.canComment(p)) act(t('Balas', 'Reply'), () { setState(() => replyTo = cm); fn.requestFocus(); }),
            if (mine) act(t('Edit', 'Edit'), () => _edit(c, cm)),
            if (mine || p['author'] == S.meId) act(t('Hapus', 'Delete'), () async { if (await confirm(c, t('Hapus komentar?', 'Delete comment?'), ok: t('Hapus', 'Delete'), danger: true)) S.deleteComment(cm); }),
            if (!mine) act(t('Laporkan', 'Report'), () async { final r = await pickOption(c, t('Alasan laporan', 'Report reason'), reportReasons(), ''); if (r != null) { S.report('comment', cm['id'], r); if (c.mounted) toast(c, t('Laporan terkirim', 'Report sent')); } }),
          ]),
        ])),
      ]),
    ));
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
              if (top.isEmpty) Empty(t('Belum ada komentar', 'No comments yet')),
              for (final cm in top) ...[commentTile(c, p, cm), for (final r in S.commentsOf(p['id'], parent: cm['id'])) commentTile(c, p, r, reply: true)],
              const SizedBox(height: 20),
            ])),
            Container(
              decoration: BoxDecoration(border: Border(top: BorderSide(color: Theme.of(c).dividerColor))),
              padding: EdgeInsets.fromLTRB(14, 8, 6, 8 + MediaQuery.of(c).viewPadding.bottom * 0),
              child: SafeArea(top: false, child: can
                  ? Column(mainAxisSize: MainAxisSize.min, children: [
                      if (replyTo != null) Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(children: [Expanded(child: Text('${t('Membalas', 'Replying to')} ${S.user(replyTo!['by'])?['name'] ?? ''}', style: const TextStyle(color: Colors.grey, fontSize: 13))), IconBtn('x', size: 16, onTap: () => setState(() => replyTo = null))])),
                      Row(children: [
                        Expanded(child: TextField(controller: ctl, focusNode: fn, minLines: 1, maxLines: 4, maxLength: 500, buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null, decoration: InputDecoration(hintText: t('Tulis komentar', 'Write a comment')))),
                        IconBtn('send', onTap: () => send(p)),
                      ]),
                    ])
                  : Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Center(child: Text(t('Komentar dibatasi oleh pemilik postingan', 'Comments are restricted by the author'), style: const TextStyle(color: Colors.grey, fontSize: 13))))),
            ),
          ]),
        );
      });
}
