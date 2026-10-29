import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'browser.dart';
import 'create.dart';
import 'detail.dart';
import 'icons.dart';
import 'media.dart';
import 'mediaview.dart';
import 'profile.dart';
import 'store.dart';
import 'widgets.dart';

String ago(int ms) {
  final d = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ms));
  if (d.inMinutes < 1) return t('baru saja', 'now');
  if (d.inHours < 1) return '${d.inMinutes}m';
  if (d.inDays < 1) return '${d.inHours}${t('j', 'h')}';
  if (d.inDays < 30) return '${d.inDays}${t('h', 'd')}';
  return '${d.inDays ~/ 30}${t('bln', 'mo')}';
}

Future<void> shareText(BuildContext c, String text) async {
  try { await Share.share(text); } catch (_) { await Clipboard.setData(ClipboardData(text: text)); if (c.mounted) toast(c, t('Link disalin', 'Link copied')); }
}

class Avatar extends StatelessWidget {
  final M? u; final double r;
  const Avatar(this.u, {super.key, this.r = 20});
  @override
  Widget build(BuildContext c) {
    final cs = Theme.of(c).colorScheme;
    if (u == null) return CircleAvatar(radius: r, backgroundColor: cs.onSurface.withOpacity(.08), child: Ic('ghost', size: r * 1.1, color: cs.onSurface.withOpacity(.6)));
    if (u!['avatar'] != null) return ClipOval(child: SizedBox(width: r * 2, height: r * 2, child: MediaImage(u!['avatar'])));
    return CircleAvatar(radius: r, backgroundColor: cs.onSurface, child: Text((u!['name'] as String).isEmpty ? '?' : (u!['name'] as String)[0].toUpperCase(), style: TextStyle(color: cs.surface, fontSize: r * .85, fontWeight: FontWeight.w700)));
  }
}

class PostCard extends StatelessWidget {
  final M p; final int i; final bool detail;
  const PostCard(this.p, {super.key, this.i = 0, this.detail = false});

  @override
  Widget build(BuildContext c) {
    final anon = p['anon'] == true;
    final a = anon ? null : S.user(p['author']);
    final ncom = S.commentCount(p['id']);
    void openProfile() { if (a != null) Navigator.push(c, fadeRoute(ProfilePage(a['id']))); }
    void openDetail({bool focus = false}) { if (!detail || focus) Navigator.push(c, fadeRoute(PostDetailPage(p['id'], focus: focus))); }
    return Fade(delay: (i > 6 ? 6 : i) * 70, GestureDetector(
      behavior: HitTestBehavior.opaque, onTap: detail ? null : openDetail,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 10, 6),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Theme.of(c).dividerColor))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          GestureDetector(onTap: openProfile, child: Avatar(a, r: 19)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              GestureDetector(onTap: openProfile, child: Text(anon ? t('Anonim', 'Anonymous') : a?['name'] ?? '?', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
              const SizedBox(width: 8),
              Text(ago(p['time']) + (p['edited'] == true ? ' · ${t('diedit', 'edited')}' : ''), style: const TextStyle(fontSize: 12.5, color: Colors.grey)),
              const Spacer(),
              IconBtn('more', size: 20, onTap: () => _menu(c)),
            ]),
            if ((p['text'] ?? '').toString().isNotEmpty) Padding(padding: const EdgeInsets.only(top: 2, bottom: 10, right: 8), child: LinkText(p['text'], style: const TextStyle(fontSize: 15.5, height: 1.4))),
            if (p['type'] == 'photo' || p['type'] == 'video') Padding(padding: const EdgeInsets.only(bottom: 8), child: MediaCarousel(id: p['id'], video: p['type'] == 'video', media: List<String>.from(p['media']))),
            if (p['type'] == 'audio') Padding(padding: const EdgeInsets.only(right: 8), child: AudioTile(p['media'][0])),
            if (p['sound'] != null) Padding(padding: const EdgeInsets.only(right: 8), child: AudioTile(p['sound'], label: 'backsound')),
            Row(children: [
              IconBtn('chat', size: 21, onTap: () => openDetail(focus: true)),
              Text(ncom == 0 ? '' : '$ncom', style: const TextStyle(fontSize: 13, color: Colors.grey)),
              IconBtn('share', size: 21, onTap: () => shareText(c, linkOf(p['id']))),
            ]),
          ])),
        ]),
      ),
    ));
  }

  void _menu(BuildContext c) {
    final mine = p['author'] == S.meId;
    final canBlock = !mine && p['anon'] != true;
    showModalBottomSheet(context: c, showDragHandle: true, builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Row2(t('Salin link', 'Copy link'), icon: 'link', onTap: () async { Navigator.pop(ctx); await Clipboard.setData(ClipboardData(text: linkOf(p['id']))); if (c.mounted) toast(c, t('Link disalin', 'Link copied')); }),
      Row2(t('Bagikan', 'Share'), icon: 'share', onTap: () { Navigator.pop(ctx); shareText(c, linkOf(p['id'])); }),
      if (mine) Row2(t('Edit', 'Edit'), icon: 'edit', onTap: () { Navigator.pop(ctx); Navigator.push(c, fadeRoute(CreatePage(edit: p))); }),
      if (mine) Row2(t('Hapus', 'Delete'), icon: 'trash', danger: true, onTap: () async { Navigator.pop(ctx); if (await confirm(c, t('Hapus postingan?', 'Delete post?'), ok: t('Hapus', 'Delete'), danger: true)) { await S.deletePost(p); if (c.mounted && detail) Navigator.pop(c); } }),
      if (!mine) Row2(t('Laporkan', 'Report'), icon: 'flag', danger: true, onTap: () async {
        Navigator.pop(ctx);
        final r = await pickOption(c, t('Alasan laporan', 'Report reason'), reportReasons(), '');
        if (r != null) { S.report('post', p['id'], r); if (c.mounted) toast(c, t('Laporan terkirim', 'Report sent')); }
      }),
      if (canBlock) Row2(t('Blokir akun ini', 'Block this account'), icon: 'ban', danger: true, onTap: () async { Navigator.pop(ctx); if (await confirm(c, t('Blokir akun ini?', 'Block this account?'), body: t('Postingannya tidak akan muncul lagi dan hubungan/ikutan diputus.', 'Their posts will be hidden and follows/relations removed.'), ok: t('Blokir', 'Block'), danger: true)) { S.block(p['author']); if (c.mounted && detail) Navigator.pop(c); } }),
    ])));
  }
}

Map<String, String> reportReasons() => {for (final x in [t('Spam', 'Spam'), t('Pelecehan', 'Harassment'), t('Konten tidak pantas', 'Inappropriate'), t('Informasi palsu', 'False info'), t('Lainnya', 'Other')]) x: x};
