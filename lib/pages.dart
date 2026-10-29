import 'dart:math';
import 'package:flutter/material.dart';
import 'create.dart';
import 'detail.dart';
import 'icons.dart';
import 'posts.dart';
import 'profile.dart';
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
        final pages = <Widget>[const FeedPage(), const RealPage(), const CreatePage(), const RelationsPage(), ProfilePage(S.meId!, key: ValueKey(S.meId))];
        return PopScope(
          canPop: i == 0,
          onPopInvokedWithResult: (didPop, _) { if (!didPop) setState(() => i = 0); },
          child: Scaffold(
            appBar: AppBar(
              leading: IconBtn('search', onTap: () => Navigator.push(c, fadeRoute(const SearchPage()))),
              title: const LidLogo(size: 30),
              actions: [Stack(alignment: Alignment.center, children: [IconBtn('bell', onTap: () => Navigator.push(c, fadeRoute(const NotifPage()))), if (S.unread > 0) Positioned(right: 10, top: 12, child: Container(width: 8, height: 8, decoration: BoxDecoration(color: cs.onSurface, shape: BoxShape.circle, border: Border.all(color: cs.surface, width: 1.5))))])],
            ),
            body: Stack(children: [for (var k = 0; k < pages.length; k++) Positioned.fill(child: IgnorePointer(ignoring: i != k, child: AnimatedOpacity(opacity: i == k ? 1 : 0, duration: const Duration(milliseconds: 280), child: AnimatedSlide(offset: i == k ? Offset.zero : const Offset(0, .02), duration: const Duration(milliseconds: 280), curve: Curves.easeOut, child: pages[k]))))]),
            bottomNavigationBar: Container(
              decoration: BoxDecoration(color: cs.surface, border: Border(top: BorderSide(color: Theme.of(c).dividerColor))),
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
  bool loading = true; int tab = 0;
  @override
  void initState() { super.initState(); Future.delayed(const Duration(milliseconds: 900), () { if (mounted) setState(() => loading = false); }); }
  @override
  Widget build(BuildContext c) => ListenableBuilder(listenable: S, builder: (_, __) {
        if (loading) return const Center(child: RunnerLoader(size: 80));
        final l = S.feed(onlyFollowing: tab == 1);
        return Column(children: [
          Padding(padding: const EdgeInsets.fromLTRB(20, 4, 20, 10), child: Seg([('', t('Untuk kamu', 'For you')), ('', t('Mengikuti', 'Following'))], tab, (i) => setState(() => tab = i))),
          Expanded(child: RefreshIndicator(
            color: Theme.of(c).colorScheme.onSurface, onRefresh: () => Future.delayed(const Duration(milliseconds: 900), () => S.save()),
            child: l.isEmpty ? ListView(children: [SizedBox(height: 380, child: Empty(tab == 1 ? t('Ikuti orang untuk melihat postingannya di sini', 'Follow people to see their posts here') : t('Belum ada postingan', 'No posts yet')))]) : ListView.builder(physics: const AlwaysScrollableScrollPhysics(), itemCount: l.length, itemBuilder: (_, i) => PostCard(l[i], key: ValueKey('${l[i]['id']}$tab'), i: i)),
          )),
        ]);
      });
}

class RealPage extends StatefulWidget {
  const RealPage({super.key});
  @override
  State<RealPage> createState() => _RealS();
}
class _RealS extends State<RealPage> {
  M? p; bool loading = false, empty = false;
  Future<void> roll() async {
    setState(() => loading = true);
    await Future.delayed(const Duration(milliseconds: 900));
    final pool = S.realPool();
    setState(() { p = pool.isEmpty ? null : pool[Random().nextInt(pool.length)]; empty = pool.isEmpty; loading = false; });
  }
  @override
  Widget build(BuildContext c) => ListenableBuilder(listenable: S, builder: (_, __) => ListView(children: [
        const SizedBox(height: 24),
        Center(child: FilledButton.icon(icon: Ic('shuffle', size: 18, color: Theme.of(c).colorScheme.surface), label: Text(p == null ? t('Keluarkan Real', 'Show Real') : t('Acak lagi', 'Shuffle again')), onPressed: loading ? null : roll)),
        const SizedBox(height: 16),
        if (loading) const Padding(padding: EdgeInsets.all(48), child: Center(child: RunnerLoader())),
        if (!loading && p != null && S.posts.contains(p)) AnimatedSwitcher(duration: const Duration(milliseconds: 450), transitionBuilder: (w, a) => ScaleTransition(scale: Tween(begin: .94, end: 1.0).animate(a), child: FadeTransition(opacity: a, child: w)), child: PostCard(p!, key: ValueKey(p!['id']))),
        if (!loading && (p == null || !S.posts.contains(p))) Empty(empty ? t('Belum ada postingan yang masuk Real', 'No posts in Real yet') : t('Tekan tombol untuk melihat satu postingan acak', 'Press the button to see one random post')),
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
          for (final r in ok) tile(r, [IconBtn('x', onTap: () async { if (await confirm(c, t('Putuskan hubungan?', 'Remove relation?'), ok: t('Putuskan', 'Remove'), danger: true)) S.answerRel(r, false); })]),
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
            if (u.isEmpty || u.first['id'] == S.meId || S.blockedEither(u.first['id'], S.meId!)) { toast(c, t('User tidak ditemukan', 'User not found')); return; }
            if (S.relBetween(S.meId!, u.first['id']) != null) { toast(c, t('Sudah ada hubungan / permintaan', 'Relation or request already exists')); return; }
            S.requestRel(u.first['id'], type); Navigator.pop(ctx);
            toast(c, t('Permintaan dikirim, menunggu persetujuan', 'Request sent, awaiting approval'));
          }, child: Text(t('Kirim', 'Send')))),
        ]),
      )));
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override
  State<SearchPage> createState() => _SearchS();
}
class _SearchS extends State<SearchPage> {
  String q = ''; int tab = 0;
  @override
  Widget build(BuildContext c) {
    final k = q.trim().toLowerCase();
    final us = k.isEmpty ? <M>[] : S.users.where((u) => u['id'] != S.meId && !S.blockedEither(u['id'], S.meId!) && (u['name'].toString().toLowerCase().contains(k) || u['username'].toString().contains(k.replaceAll('@', '')))).toList();
    final ps = k.isEmpty ? <M>[] : S.feed().where((p) => p['anon'] != true && p['text'].toString().toLowerCase().contains(k)).toList();
    return Scaffold(
      appBar: AppBar(leading: IconBtn('back', onTap: () => Navigator.pop(c)), title: TextField(autofocus: true, onChanged: (v) => setState(() => q = v), decoration: InputDecoration(hintText: t('Cari orang atau post', 'Search people or posts'), contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10))), centerTitle: false),
      body: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(20, 4, 20, 8), child: Seg([('users', t('Orang', 'People')), ('text', t('Postingan', 'Posts'))], tab, (i) => setState(() => tab = i))),
        Expanded(child: k.isEmpty ? Empty(t('Ketik untuk mencari', 'Type to search')) : ListView(children: [
          if (tab == 0) ...[
            if (us.isEmpty) Empty(t('Tidak ada hasil', 'No results')),
            for (final u in us) Fade(ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 20), leading: Avatar(u), title: Text(u['name'], style: const TextStyle(fontWeight: FontWeight.w600)), subtitle: Text('@${u['username']}'), onTap: () => Navigator.push(c, fadeRoute(ProfilePage(u['id']))))),
          ] else ...[
            if (ps.isEmpty) Empty(t('Tidak ada hasil', 'No results')),
            for (var j = 0; j < ps.length; j++) PostCard(ps[j], key: ValueKey(ps[j]['id']), i: j),
          ],
        ])),
      ]),
    );
  }
}

class NotifPage extends StatelessWidget {
  const NotifPage({super.key});
  @override
  Widget build(BuildContext c) {
    final l = S.notifs.where((n) => n['to'] == S.meId && S.user(n['from']) != null).toList().reversed.toList();
    final unreadIds = l.where((n) => n['read'] != true).toList();
    for (final n in unreadIds) { n['read'] = true; }
    if (unreadIds.isNotEmpty) WidgetsBinding.instance.addPostFrameCallback((_) => S.save());
    String msg(M n) => {'comment': t('mengomentari postinganmu', 'commented on your post'), 'reply': t('membalas komentarmu', 'replied to your comment'), 'follow': t('mulai mengikutimu', 'followed you'), 'rel_req': t('mengajukan hubungan', 'sent a relation request'), 'rel_ok': t('menyetujui hubungan', 'accepted your relation')}[n['type']] ?? '';
    return Scaffold(
      appBar: AppBar(title: Text(t('Notifikasi', 'Notifications')), leading: IconBtn('back', onTap: () => Navigator.pop(c))),
      body: l.isEmpty ? Empty(t('Belum ada notifikasi', 'No notifications')) : ListView(children: [for (var k = 0; k < l.length; k++) Fade(delay: (k > 8 ? 8 : k) * 60, ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20), leading: Avatar(S.user(l[k]['from'])),
        title: Text('${S.user(l[k]['from'])?['name'] ?? '?'} ${msg(l[k])}', style: const TextStyle(fontSize: 14.5)), subtitle: Text(ago(l[k]['time'])),
        onTap: () { final n = l[k]; if (n['post'] != null && S.post(n['post']) != null) { Navigator.push(c, fadeRoute(PostDetailPage(n['post']))); } else { Navigator.push(c, fadeRoute(ProfilePage(n['from']))); } },
      ))]),
    );
  }
}
