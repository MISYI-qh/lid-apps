import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'browser.dart';
import 'camera.dart';
import 'icons.dart';
import 'media.dart';
import 'pages.dart';
import 'posts.dart';
import 'settings.dart';
import 'store.dart';
import 'widgets.dart';

class ProfilePage extends StatefulWidget {
  final String id; final bool embedded;
  const ProfilePage(this.id, {super.key, this.embedded = false});
  @override
  State<ProfilePage> createState() => _PS();
}
class _PS extends State<ProfilePage> {
  int tab = 0;
  void list(BuildContext c, String title, List<String> ids) => showModalBottomSheet(context: c, showDragHandle: true, isScrollControlled: true, builder: (_) => SafeArea(child: ConstrainedBox(constraints: BoxConstraints(maxHeight: MediaQuery.of(c).size.height * .7), child: ListView(shrinkWrap: true, children: [
        Center(child: Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)))),
        if (ids.isEmpty) Padding(padding: const EdgeInsets.all(28), child: Center(child: Text(t('Kosong', 'Empty'), style: const TextStyle(color: Colors.grey)))),
        for (final x in ids) if (S.user(x) != null) ListTile(leading: Avatar(S.user(x), r: 18), title: Text(S.user(x)!['name']), subtitle: Text('@${S.user(x)!['username']}'), onTap: () { Navigator.pop(c); Navigator.push(c, fadeRoute(ProfilePage(x))); }),
      ]))));

  void userMenu(BuildContext c, String id) {
    final isBlocked = S.blockedOf(S.meId!).contains(id);
    showModalBottomSheet(context: c, showDragHandle: true, builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Row2(isBlocked ? t('Buka blokir', 'Unblock') : t('Blokir', 'Block'), icon: 'ban', danger: !isBlocked, onTap: () async {
        Navigator.pop(ctx);
        if (isBlocked) { S.unblock(id); } else if (await confirm(c, t('Blokir akun ini?', 'Block this account?'), body: t('Postingannya disembunyikan dan ikutan/hubungan diputus.', 'Their posts are hidden and follows/relations removed.'), ok: t('Blokir', 'Block'), danger: true)) { S.block(id); }
      }),
      Row2(t('Laporkan akun', 'Report account'), icon: 'flag', danger: true, onTap: () async { Navigator.pop(ctx); final r = await pickOption(c, t('Alasan laporan', 'Report reason'), reportReasons(), ''); if (r != null) { S.report('user', id, r); if (c.mounted) toast(c, t('Laporan terkirim', 'Report sent')); } }),
    ])));
  }

  @override
  Widget build(BuildContext c) => ListenableBuilder(listenable: S, builder: (_, __) {
        final id = widget.id, u = S.user(id);
        if (u == null) return Scaffold(appBar: AppBar(leading: IconBtn('back', onTap: () => Navigator.pop(c))), body: Empty(t('Akun tidak tersedia', 'Account not available')));
        final mine = id == S.meId;
        if (!mine && S.blockedEither(S.meId!, id)) {
          final iBlocked = S.blockedOf(S.meId!).contains(id);
          return Scaffold(appBar: AppBar(leading: IconBtn('back', onTap: () => Navigator.pop(c))), body: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Empty(iBlocked ? t('Kamu memblokir akun ini', 'You blocked this account') : t('Akun tidak tersedia', 'Account not available')), if (iBlocked) FilledButton(onPressed: () => S.unblock(id), child: Text(t('Buka blokir', 'Unblock')))]));
        }
        final showAnon = S.canSeeAnonTab(id);
        final t0 = showAnon ? tab : 0;
        final posts = S.postsOf(id, anon: t0 == 1);
        final rel = S.relBetween(S.meId!, id);
        final body = ListView(children: [
          Padding(padding: const EdgeInsets.fromLTRB(20, 14, 20, 12), child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(u['name'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -.5)), const SizedBox(height: 2), Text('@${u['username']}', style: const TextStyle(color: Colors.grey))])),
            Avatar(u, r: 34),
          ])),
          if ((u['bio'] ?? '').toString().isNotEmpty) Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 8), child: LinkText(u['bio'])),
          Padding(padding: const EdgeInsets.fromLTRB(12, 4, 12, 12), child: Row(children: [
            for (final s in [(t('Pengikut', 'Followers'), S.followersOf(id)), (t('Mengikuti', 'Following'), S.followingOf(id)), (t('Hubungan', 'Relations'), S.relsOf(id))])
              InkWell(onTap: () => list(c, s.$1, s.$2), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), child: Row(children: [Text('${s.$2.length} ', style: const TextStyle(fontWeight: FontWeight.w800)), Text(s.$1, style: const TextStyle(color: Colors.grey, fontSize: 14))]))),
          ])),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Row(children: mine
              ? [Expanded(child: OutlinedButton(onPressed: () => editProfile(c), child: Text(t('Edit profil', 'Edit profile')))), const SizedBox(width: 10), Expanded(child: OutlinedButton(onPressed: () => Navigator.push(c, fadeRoute(const SettingsPage())), child: Text(t('Pengaturan', 'Settings'))))]
              : [Expanded(child: S.following(id) ? OutlinedButton(onPressed: () => S.toggleFollow(id), child: Text(t('Mengikuti', 'Following'))) : FilledButton(onPressed: () => S.toggleFollow(id), child: Text(t('Ikuti', 'Follow')))), const SizedBox(width: 10), Expanded(child: OutlinedButton(onPressed: rel != null ? null : () => addRel(c, id), child: Text(rel == null ? t('Hubungan', 'Relation') : rel['status'] == 'ok' ? relLabel(rel['type']) : t('Menunggu', 'Pending'))))])),
          const SizedBox(height: 18),
          if (showAnon) Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Seg([('grid', t('Postingan', 'Posts')), ('ghost', t('Anonim', 'Anonymous'))], t0, (i) => setState(() => tab = i))),
          if (mine && t0 == 1) Row2(t('Yang bisa melihat tab Anonim', 'Who can see Anonymous tab'), icon: 'eye', value: audLabel(u['anonVis'] ?? 'none'), onTap: () async { final v = await pickOption(c, t('Yang bisa melihat tab Anonim', 'Who can see Anonymous tab'), {for (final k in anonKeys) k: audLabel(k)}, u['anonVis'] ?? 'none'); if (v != null) { u['anonVis'] = v; S.save(); } }),
          const SizedBox(height: 8),
          AnimatedSwitcher(duration: const Duration(milliseconds: 350), child: Column(key: ValueKey('$t0${posts.length}'), children: [if (posts.isEmpty) Empty(t('Belum ada postingan', 'No posts yet')), for (var k = 0; k < posts.length; k++) PostCard(posts[k], key: ValueKey(posts[k]['id']), i: k)])),
        ]);
        return widget.embedded ? body : Scaffold(appBar: AppBar(leading: IconBtn('back', onTap: () => Navigator.pop(c)), actions: [if (!mine) IconBtn('more', onTap: () => userMenu(c, id))]), body: body);
      });
}

void editProfile(BuildContext c) {
  final n = TextEditingController(text: S.me['name']), b = TextEditingController(text: S.me['bio']);
  showModalBottomSheet(isScrollControlled: true, showDragHandle: true, context: c, builder: (ctx) => ListenableBuilder(listenable: S, builder: (_, __) => Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
        child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Avatar(S.me, r: 44), const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            TextButton.icon(icon: const Ic('camera', size: 18), label: Text(t('Ganti foto', 'Change photo')), onPressed: () async {
              final r = await Navigator.push<List<XFile>>(ctx, MaterialPageRoute(builder: (_) => const CameraPage(video: false, selfie: true)));
              if (r != null && r.isNotEmpty) { final k = await keepXFile(r.first, 'photo'); await S.setAvatar(k); }
            }),
            if (S.me['avatar'] != null) TextButton(onPressed: () => S.setAvatar(null), child: Text(t('Hapus', 'Remove'), style: const TextStyle(color: Colors.red))),
          ]),
          const SizedBox(height: 8),
          TextField(controller: n, maxLength: 40, decoration: InputDecoration(hintText: t('Nama', 'Name'))), const SizedBox(height: 4),
          TextField(controller: b, maxLines: 3, maxLength: 150, decoration: const InputDecoration(hintText: 'Bio')), const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: () { if (n.text.trim().isNotEmpty) S.me['name'] = n.text.trim(); S.me['bio'] = b.text.trim(); S.save(); Navigator.pop(ctx); }, child: Text(t('Simpan', 'Save')))),
        ])),
      )));
}
