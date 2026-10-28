import 'dart:math';
import 'package:flutter/material.dart';
import 'auth.dart';
import 'create.dart';
import 'icons.dart';
import 'posts.dart';
import 'store.dart';
import 'widgets.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellS();
}
class _ShellS extends State<Shell> {
  int i = 0;
  @override
  Widget build(BuildContext c) => ListenableBuilder(listenable: S, builder: (_, __) {
        final cs = Theme.of(c).colorScheme;
        const icons = ['home', 'shuffle', 'plus', 'users', 'user'];
        return Scaffold(
          appBar: AppBar(
            leading: IconBtn('search', onTap: () => Navigator.push(c, fadeRoute(const SearchPage()))),
            title: const LidLogo(size: 30),
            actions: [Stack(alignment: Alignment.center, children: [IconBtn('bell', onTap: () => Navigator.push(c, fadeRoute(const NotifPage()))), if (S.unread > 0) Positioned(right: 10, top: 12, child: Container(width: 8, height: 8, decoration: BoxDecoration(color: cs.onSurface, shape: BoxShape.circle, border: Border.all(color: cs.surface, width: 1.5))))])],
          ),
          body: Stack(children: [for (final e in [const FeedPage(), const RealPage(), const CreatePage(), const RelationsPage(), ProfilePage(S.meId!, key: ValueKey(S.meId))].asMap().entries) IgnorePointer(ignoring: i != e.key, child: AnimatedOpacity(opacity: i == e.key ? 1 : 0, duration: const Duration(milliseconds: 280), child: AnimatedSlide(offset: i == e.key ? Offset.zero : const Offset(0, .02), duration: const Duration(milliseconds: 280), curve: Curves.easeOut, child: e.value)))]),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(border: Border(top: BorderSide(color: Theme.of(c).dividerColor))),
            child: SafeArea(child: SizedBox(height: 58, child: Row(children: [
              for (var k = 0; k < 5; k++) Expanded(child: GestureDetector(
                behavior: HitTestBehavior.opaque, onTap: () => setState(() => i = k),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  AnimatedScale(scale: i == k ? 1.12 : 1, duration: const Duration(milliseconds: 220), child: Ic(icons[k], size: 25, sw: i == k ? 2.3 : 1.5, color: i == k ? cs.onSurface : Colors.grey)),
                  const SizedBox(height: 5),
                  AnimatedContainer(duration: const Duration(milliseconds: 220), width: i == k ? 14 : 0, height: 2.5, decoration: BoxDecoration(color: cs.onSurface, borderRadius: BorderRadius.circular(2))),
                ]),
              )),
            ]))),
          ),
        );
      });
}

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});
  @override
  State<FeedPage> createState() => _FeedS();
}
class _FeedS extends State<FeedPage> {
  bool loading = true;
  @override
  void initState() { super.initState(); Future.delayed(const Duration(milliseconds: 900), () { if (mounted) setState(() => loading = false); }); }
  @override
  Widget build(BuildContext c) => ListenableBuilder(listenable: S, builder: (_, __) {
        if (loading) return const Center(child: RunnerLoader(size: 80));
        final l = S.feed();
        return RefreshIndicator(
          color: Theme.of(c).colorScheme.onSurface, onRefresh: () => Future.delayed(const Duration(milliseconds: 900), () => S.save()),
          child: l.isEmpty ? ListView(children: [SizedBox(height: 420, child: Empty(t('Belum ada postingan', 'No posts yet')))]) : ListView.builder(physics: const AlwaysScrollableScrollPhysics(), itemCount: l.length, itemBuilder: (_, i) => PostCard(l[i], key: ValueKey(l[i]['id']), i: i)),
        );
      });
}

class RealPage extends StatefulWidget {
  const RealPage({super.key});
  @override
  State<RealPage> createState() => _RealS();
}
class _RealS extends State<RealPage> {
  M? p; bool loading = false;
  Future<void> roll() async {
    setState(() => loading = true);
    await Future.delayed(const Duration(milliseconds: 900));
    final pool = S.realPool();
    setState(() { p = pool.isEmpty ? null : pool[Random().nextInt(pool.length)]; loading = false; });
  }
  @override
  Widget build(BuildContext c) => ListenableBuilder(listenable: S, builder: (_, __) => ListView(children: [
        const SizedBox(height: 24),
        Center(child: FilledButton.icon(icon: Ic('shuffle', size: 18, color: Theme.of(c).colorScheme.surface), label: Text(p == null ? t('Keluarkan Real', 'Show Real') : t('Acak lagi', 'Shuffle again')), onPressed: loading ? null : roll)),
        const SizedBox(height: 16),
        if (loading) const Padding(padding: EdgeInsets.all(48), child: Center(child: RunnerLoader())),
        if (!loading && p != null && S.posts.contains(p)) AnimatedSwitcher(duration: const Duration(milliseconds: 450), transitionBuilder: (w, a) => ScaleTransition(scale: Tween(begin: .94, end: 1.0).animate(a), child: FadeTransition(opacity: a, child: w)), child: PostCard(p!, key: ValueKey(p!['id']))),
        if (!loading && p == null) Empty(t('Tekan tombol untuk melihat satu postingan acak', 'Press the button to see one random post')),
      ]));
}

class RelationsPage extends StatelessWidget {
  const RelationsPage({super.key});
  @override
  Widget build(BuildContext c) => ListenableBuilder(listenable: S, builder: (_, __) {
        final me = S.meId!;
        final inc = S.rels.where((r) => r['b'] == me && r['status'] == 'pending').toList();
        final out = S.rels.where((r) => r['a'] == me && r['status'] == 'pending').toList();
        final ok = S.rels.where((r) => r['status'] == 'ok' && (r['a'] == me || r['b'] == me)).toList();
        String other(M r) => r['a'] == me ? r['b'] : r['a'];
        Widget head(String s) => Padding(padding: const EdgeInsets.fromLTRB(20, 22, 20, 6), child: Text(s, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.grey, fontSize: 13)));
        Widget tile(M r, List<Widget> tr) { final u = S.user(other(r)); return Fade(ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 20), leading: Avatar(u), title: Text(u?['name'] ?? '?', style: const TextStyle(fontWeight: FontWeight.w600)), subtitle: Text('@${u?['username']} · ${relLabel(r['type'])}'), trailing: Row(mainAxisSize: MainAxisSize.min, children: tr), onTap: u == null ? null : () => Navigator.push(c, fadeRoute(ProfilePage(u['id']))))); }
        return ListView(children: [
          Padding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 0), child: OutlinedButton.icon(icon: const Ic('userplus', size: 19), label: Text(t('Tambah hubungan', 'Add relation')), onPressed: () => addRel(c))),
          if (inc.isNotEmpty) head(t('Permintaan masuk', 'Requests')),
          for (final r in inc) tile(r, [IconBtn('check', onTap: () => S.answerRel(r, true)), IconBtn('x', onTap: () => S.answerRel(r, false))]),
          if (out.isNotEmpty) head(t('Menunggu persetujuan', 'Awaiting approval')),
          for (final r in out) tile(r, [IconBtn('x', onTap: () => S.answerRel(r, false))]),
          head(t('Hubunganmu', 'Your relations')),
          if (ok.isEmpty) Empty(t('Belum ada hubungan', 'No relations yet')),
          for (final r in ok) tile(r, [IconBtn('x', onTap: () => S.answerRel(r, false))]),
        ]);
      });
}

Future<void> addRel(BuildContext c, [String? target]) async {
  final ctl = TextEditingController(text: target == null ? '' : S.user(target)?['username']);
  String type = 'friend';
  await showModalBottomSheet(context: c, isScrollControlled: true, showDragHandle: true, builder: (_) => StatefulBuilder(builder: (ctx, set) => Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: ctl, autocorrect: false, decoration: const InputDecoration(hintText: 'Username')),
          const SizedBox(height: 12),
          Row2(t('Jenis hubungan', 'Relation type'), value: audLabel(type), onTap: () async { final v = await pickOption(ctx, t('Jenis hubungan', 'Relation type'), {for (final k in ['friend', 'best', 'partner', 'family']) k: audLabel(k)}, type); if (v != null) set(() => type = v); }),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: () {
            final u = S.users.where((x) => x['username'] == ctl.text.trim().toLowerCase()).toList();
            if (u.isEmpty || u.first['id'] == S.meId) { ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(t('User tidak ditemukan', 'User not found')))); return; }
            S.requestRel(u.first['id'], type); Navigator.pop(ctx);
            ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(t('Permintaan dikirim, menunggu persetujuan', 'Request sent, awaiting approval'))));
          }, child: Text(t('Kirim', 'Send')))),
        ]),
      )));
}

class ProfilePage extends StatefulWidget {
  final String id;
  const ProfilePage(this.id, {super.key});
  @override
  State<ProfilePage> createState() => _PS();
}
class _PS extends State<ProfilePage> {
  int tab = 0;
  void list(BuildContext c, String title, List<String> ids) => showModalBottomSheet(context: c, showDragHandle: true, builder: (_) => ListView(shrinkWrap: true, children: [Center(child: Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)))), for (final x in ids) ListTile(leading: Avatar(S.user(x), r: 18), title: Text(S.user(x)?['name'] ?? '?'), subtitle: Text('@${S.user(x)?['username']}'), onTap: () { Navigator.pop(c); Navigator.push(c, fadeRoute(ProfilePage(x))); })]));

  @override
  Widget build(BuildContext c) => ListenableBuilder(listenable: S, builder: (_, __) {
        final id = widget.id, u = S.user(id);
        if (u == null) return const Scaffold(body: SizedBox());
        final mine = id == S.meId, showAnon = S.canSeeAnonTab(id);
        final posts = S.postsOf(id, anon: tab == 1 && showAnon);
        final rel = S.relBetween(S.meId!, id);
        final body = ListView(children: [
          Padding(padding: const EdgeInsets.fromLTRB(20, 14, 20, 12), child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(u['name'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -.5)), const SizedBox(height: 2), Text('@${u['username']}', style: const TextStyle(color: Colors.grey))])),
            Avatar(u, r: 34),
          ])),
          if ((u['bio'] ?? '').toString().isNotEmpty) Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 8), child: Text(u['bio'])),
          Padding(padding: const EdgeInsets.fromLTRB(12, 4, 12, 12), child: Row(children: [
            for (final s in [(t('Pengikut', 'Followers'), S.followersOf(id)), (t('Mengikuti', 'Following'), S.followingOf(id)), (t('Hubungan', 'Relations'), S.relsOf(id))])
              InkWell(onTap: () => list(c, s.$1, s.$2), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), child: Row(children: [Text('${s.$2.length} ', style: const TextStyle(fontWeight: FontWeight.w800)), Text(s.$1, style: const TextStyle(color: Colors.grey, fontSize: 14))]))),
          ])),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Row(children: mine
              ? [Expanded(child: OutlinedButton(onPressed: () => editProfile(c), child: Text(t('Edit profil', 'Edit profile')))), const SizedBox(width: 10), Expanded(child: OutlinedButton(onPressed: () => Navigator.push(c, fadeRoute(const SettingsPage())), child: Text(t('Pengaturan', 'Settings'))))]
              : [Expanded(child: S.following(id) ? OutlinedButton(onPressed: () => S.toggleFollow(id), child: Text(t('Mengikuti', 'Following'))) : FilledButton(onPressed: () => S.toggleFollow(id), child: Text(t('Ikuti', 'Follow')))), const SizedBox(width: 10), Expanded(child: OutlinedButton(onPressed: rel != null ? null : () => addRel(c, id), child: Text(rel == null ? t('Hubungan', 'Relation') : rel['status'] == 'ok' ? relLabel(rel['type']) : t('Menunggu', 'Pending'))))])),
          const SizedBox(height: 18),
          if (showAnon) Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Seg([('grid', t('Postingan', 'Posts')), ('ghost', t('Anonim', 'Anonymous'))], tab, (i) => setState(() => tab = i))),
          if (mine && tab == 1) Row2(t('Yang bisa melihat tab Anonim', 'Who can see Anonymous tab'), icon: 'eye', value: audLabel(u['anonVis'] ?? 'none'), onTap: () async { final v = await pickOption(c, t('Yang bisa melihat tab Anonim', 'Who can see Anonymous tab'), {for (final k in ['none', 'all', 'friend', 'best', 'partner', 'family', 'allrel']) k: audLabel(k)}, u['anonVis'] ?? 'none'); if (v != null) { u['anonVis'] = v; S.save(); } }),
          const SizedBox(height: 8),
          AnimatedSwitcher(duration: const Duration(milliseconds: 350), child: Column(key: ValueKey('$tab${posts.length}'), children: [if (posts.isEmpty) Empty(t('Belum ada postingan', 'No posts yet')), for (var k = 0; k < posts.length; k++) PostCard(posts[k], key: ValueKey(posts[k]['id']), i: k)])),
        ]);
        return mine ? body : Scaffold(appBar: AppBar(leading: IconBtn('back', onTap: () => Navigator.pop(c))), body: body);
      });
}

void editProfile(BuildContext c) {
  final n = TextEditingController(text: S.me['name']), b = TextEditingController(text: S.me['bio']);
  showModalBottomSheet(isScrollControlled: true, showDragHandle: true, context: c, builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: n, decoration: InputDecoration(hintText: t('Nama', 'Name'))), const SizedBox(height: 12),
          TextField(controller: b, maxLines: 3, decoration: const InputDecoration(hintText: 'Bio')), const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: () { if (n.text.trim().isNotEmpty) S.me['name'] = n.text.trim(); S.me['bio'] = b.text.trim(); S.save(); Navigator.pop(ctx); }, child: Text(t('Simpan', 'Save')))),
        ]),
      ));
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext c) => ListenableBuilder(listenable: S, builder: (_, __) {
        final themes = {'system': t('Sistem', 'System'), 'light': t('Terang', 'Light'), 'dark': t('Gelap', 'Dark')};
        final langs = {'system': t('Ikuti perangkat', 'Follow device'), 'id': 'Indonesia', 'en': 'English'};
        Widget head(String s) => Padding(padding: const EdgeInsets.fromLTRB(20, 24, 20, 4), child: Text(s, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.grey, fontSize: 13)));
        return Scaffold(
          appBar: AppBar(title: Text(t('Pengaturan', 'Settings')), leading: IconBtn('back', onTap: () => Navigator.pop(c))),
          body: ListView(children: [
            head(t('Tampilan', 'Appearance')),
            Row2(t('Tema', 'Theme'), icon: 'sliders', value: themes[S.theme], onTap: () async { final v = await pickOption(c, t('Tema', 'Theme'), themes, S.theme); if (v != null) { S.theme = v; S.save(); } }),
            Row2(t('Bahasa', 'Language'), icon: 'globe', value: langs[S.lang], onTap: () async { final v = await pickOption(c, t('Bahasa', 'Language'), langs, S.lang); if (v != null) { S.lang = v; S.save(); } }),
            head(t('Privasi', 'Privacy')),
            Row2(t('Audiens post bawaan', 'Default audience'), icon: 'eye', value: audLabel(S.me['defAud'] ?? 'all'), onTap: () async { final v = await pickOption(c, t('Audiens post bawaan', 'Default audience'), {for (final k in audKeys.where((k) => k != 'pick')) k: audLabel(k)}, S.me['defAud'] ?? 'all'); if (v != null) { S.me['defAud'] = v; S.save(); } }),
            Row2(t('Yang bisa melihat tab Anonim', 'Who can see Anonymous tab'), icon: 'ghost', value: audLabel(S.me['anonVis'] ?? 'none'), onTap: () async { final v = await pickOption(c, t('Yang bisa melihat tab Anonim', 'Who can see Anonymous tab'), {for (final k in ['none', 'all', 'friend', 'best', 'partner', 'family', 'allrel']) k: audLabel(k)}, S.me['anonVis'] ?? 'none'); if (v != null) { S.me['anonVis'] = v; S.save(); } }),
            head(t('Akun', 'Account')),
            Row2(t('Ganti sandi', 'Change password'), icon: 'lock', onTap: () { final p = TextEditingController(); showModalBottomSheet(context: c, isScrollControlled: true, showDragHandle: true, builder: (ctx) => Padding(padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom), child: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: p, decoration: InputDecoration(hintText: t('Sandi baru', 'New password'))), const SizedBox(height: 14), SizedBox(width: double.infinity, child: FilledButton(onPressed: () { if (p.text.isNotEmpty) { S.me['pass'] = p.text; S.save(); } Navigator.pop(ctx); }, child: Text(t('Simpan', 'Save'))))]))); }),
            Row2(t('Keluar', 'Log out'), icon: 'logout', onTap: () { S.logout(); Navigator.pushAndRemoveUntil(c, fadeRoute(const AuthPage()), (_) => false); }),
            Row2(t('Hapus akun', 'Delete account'), icon: 'trash', danger: true, onTap: () => showDialog(context: c, builder: (ctx) => AlertDialog(title: Text(t('Hapus akun?', 'Delete account?')), content: Text(t('Semua postinganmu ikut terhapus.', 'All your posts will be deleted.')), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t('Batal', 'Cancel'))), TextButton(onPressed: () { final id = S.meId; S.posts.removeWhere((p) => p['author'] == id); S.rels.removeWhere((r) => r['a'] == id || r['b'] == id); S.follows.removeWhere((f) => f['from'] == id || f['to'] == id); S.users.removeWhere((u) => u['id'] == id); S.meId = null; S.save(); Navigator.pushAndRemoveUntil(c, fadeRoute(const AuthPage()), (_) => false); }, child: Text(t('Hapus', 'Delete'), style: const TextStyle(color: Colors.red)))]))),
            const SizedBox(height: 36),
            const Center(child: LidLogo(size: 34)),
            const SizedBox(height: 8),
            const Center(child: Text('lid · Misyi · v0.3.1', style: TextStyle(color: Colors.grey, fontSize: 12))),
            const SizedBox(height: 30),
          ]),
        );
      });
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override
  State<SearchPage> createState() => _SearchS();
}
class _SearchS extends State<SearchPage> {
  String q = '';
  @override
  Widget build(BuildContext c) {
    final k = q.trim().toLowerCase();
    final us = k.isEmpty ? <M>[] : S.users.where((u) => u['name'].toString().toLowerCase().contains(k) || u['username'].toString().contains(k)).toList();
    final ps = k.isEmpty ? <M>[] : S.feed().where((p) => p['anon'] != true && p['text'].toString().toLowerCase().contains(k)).toList();
    return Scaffold(
      appBar: AppBar(leading: IconBtn('back', onTap: () => Navigator.pop(c)), title: TextField(autofocus: true, onChanged: (v) => setState(() => q = v), decoration: InputDecoration(hintText: t('Cari orang atau post', 'Search people or posts'), contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10))), centerTitle: false),
      body: ListView(children: [
        for (final u in us) ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 20), leading: Avatar(u), title: Text(u['name'], style: const TextStyle(fontWeight: FontWeight.w600)), subtitle: Text('@${u['username']}'), onTap: () => Navigator.push(c, fadeRoute(ProfilePage(u['id'])))),
        for (var k = 0; k < ps.length; k++) PostCard(ps[k], key: ValueKey(ps[k]['id']), i: k),
      ]),
    );
  }
}

class NotifPage extends StatelessWidget {
  const NotifPage({super.key});
  @override
  Widget build(BuildContext c) {
    final l = S.notifs.where((n) => n['to'] == S.meId).toList().reversed.toList();
    for (final n in l) { n['read'] = true; }
    WidgetsBinding.instance.addPostFrameCallback((_) => S.save());
    String msg(M n) => {'comment': t('mengomentari postinganmu', 'commented on your post'), 'follow': t('mulai mengikutimu', 'followed you'), 'rel_req': t('mengajukan hubungan', 'sent a relation request'), 'rel_ok': t('menyetujui hubungan', 'accepted your relation')}[n['type']] ?? '';
    return Scaffold(
      appBar: AppBar(title: Text(t('Notifikasi', 'Notifications')), leading: IconBtn('back', onTap: () => Navigator.pop(c))),
      body: l.isEmpty ? Empty(t('Belum ada notifikasi', 'No notifications')) : ListView(children: [for (var k = 0; k < l.length; k++) Fade(delay: (k > 8 ? 8 : k) * 60, ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 20), leading: Avatar(S.user(l[k]['from'])), title: Text('${S.user(l[k]['from'])?['name'] ?? '?'} ${msg(l[k])}', style: const TextStyle(fontSize: 14.5)), subtitle: Text(ago(l[k]['time']))))]),
    );
  }
}
