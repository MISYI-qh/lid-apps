import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'auth.dart';
import 'icons.dart';
import 'profile.dart';
import 'posts.dart';
import 'store.dart';
import 'widgets.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  Widget head(String s) => Padding(padding: const EdgeInsets.fromLTRB(20, 24, 20, 4), child: Text(s, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.grey, fontSize: 13)));
  void sheetInput(BuildContext c, String hint, String initial, String? Function(String) onSave, {bool obscure = false}) {
    final ctl = TextEditingController(text: initial);
    String? err;
    showModalBottomSheet(context: c, isScrollControlled: true, showDragHandle: true, builder: (ctx) => StatefulBuilder(builder: (ctx, set) => Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: ctl, autofocus: true, obscureText: obscure, autocorrect: false, decoration: InputDecoration(hintText: hint)),
          if (err != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(err!, style: const TextStyle(color: Colors.red, fontSize: 13))),
          const SizedBox(height: 14),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: () { final e = onSave(ctl.text); if (e == null) { Navigator.pop(ctx); } else { set(() => err = e); } }, child: Text(t('Simpan', 'Save')))),
        ]))));
  }

  @override
  Widget build(BuildContext c) => ListenableBuilder(listenable: S, builder: (_, __) {
        final themes = {'system': t('Sistem', 'System'), 'light': t('Terang', 'Light'), 'dark': t('Gelap', 'Dark')};
        final langs = {'system': t('Ikuti perangkat', 'Follow device'), 'id': 'Indonesia', 'en': 'English'};
        final comm = {'all': t('Semua orang', 'Everyone'), 'allrel': t('Hanya hubunganku', 'My relations only'), 'none': t('Tidak ada', 'No one')};
        final np = Map<String, dynamic>.from((S.me['notif'] as Map?) ?? {'comment': true, 'follow': true, 'rel': true});
        void setN(String k, bool v) { np[k] = v; S.me['notif'] = np; S.save(); }
        return Scaffold(
          appBar: AppBar(title: Text(t('Pengaturan', 'Settings')), leading: IconBtn('back', onTap: () => Navigator.pop(c))),
          body: ListView(children: [
            head(t('Tampilan', 'Appearance')),
            Row2(t('Tema', 'Theme'), icon: 'sliders', value: themes[S.theme], onTap: () async { final v = await pickOption(c, t('Tema', 'Theme'), themes, S.theme); if (v != null) { S.theme = v; S.save(); } }),
            Row2(t('Bahasa', 'Language'), icon: 'globe', value: langs[S.lang], onTap: () async { final v = await pickOption(c, t('Bahasa', 'Language'), langs, S.lang); if (v != null) { S.lang = v; S.save(); } }),
            SwitchRow(t('Sembunyikan tombol navigasi HP', 'Hide phone navigation buttons'), S.hideNav, (v) { S.hideNav = v; S.save(); }, icon: 'eyeoff', sub: t('Geser dari tepi bawah untuk memunculkannya', 'Swipe from the bottom edge to show them')),
            head(t('Privasi', 'Privacy')),
            Row2(t('Audiens post bawaan', 'Default audience'), icon: 'eye', value: audLabel(S.me['defAud'] ?? 'all'), onTap: () async { final v = await pickOption(c, t('Audiens post bawaan', 'Default audience'), {for (final k in audKeys.where((k) => k != 'pick')) k: audLabel(k)}, S.me['defAud'] ?? 'all'); if (v != null) { S.me['defAud'] = v; S.save(); } }),
            Row2(t('Yang bisa melihat tab Anonim', 'Who can see Anonymous tab'), icon: 'ghost', value: audLabel(S.me['anonVis'] ?? 'none'), onTap: () async { final v = await pickOption(c, t('Yang bisa melihat tab Anonim', 'Who can see Anonymous tab'), {for (final k in anonKeys) k: audLabel(k)}, S.me['anonVis'] ?? 'none'); if (v != null) { S.me['anonVis'] = v; S.save(); } }),
            Row2(t('Yang bisa berkomentar', 'Who can comment'), icon: 'chat', value: comm[S.me['commentAud'] ?? 'all'], onTap: () async { final v = await pickOption(c, t('Yang bisa berkomentar', 'Who can comment'), comm, S.me['commentAud'] ?? 'all'); if (v != null) { S.me['commentAud'] = v; S.save(); } }),
            Row2(t('Akun diblokir', 'Blocked accounts'), icon: 'ban', value: '${S.blockedOf(S.meId!).length}', onTap: () => Navigator.push(c, fadeRoute(const BlockedPage()))),
            head(t('Notifikasi', 'Notifications')),
            SwitchRow(t('Komentar dan balasan', 'Comments and replies'), np['comment'] != false, (v) => setN('comment', v), icon: 'bell'),
            SwitchRow(t('Pengikut baru', 'New followers'), np['follow'] != false, (v) => setN('follow', v), icon: 'user'),
            SwitchRow(t('Permintaan hubungan', 'Relation requests'), np['rel'] != false, (v) => setN('rel', v), icon: 'users'),
            head(t('Akun', 'Account')),
            Row2(t('Edit profil', 'Edit profile'), icon: 'edit', onTap: () => editProfile(c)),
            Row2('Username', icon: 'user', value: '@${S.me['username']}', onTap: () => sheetInput(c, 'Username', S.me['username'], (v) => S.setUsername(v))),
            Row2(t('Ganti sandi', 'Change password'), icon: 'lock', onTap: () => sheetInput(c, t('Sandi baru', 'New password'), '', (v) { if (v.isEmpty) return t('Sandi wajib diisi', 'Password is required'); S.me['pass'] = v; S.save(); return null; })),
            Row2(t('Salin data saya (JSON)', 'Copy my data (JSON)'), icon: 'download', onTap: () async { await Clipboard.setData(ClipboardData(text: S.exportJson())); if (c.mounted) toast(c, t('Data disalin', 'Data copied')); }),
            Row2(t('Keluar', 'Log out'), icon: 'logout', onTap: () { S.logout(); Navigator.pushAndRemoveUntil(c, fadeRoute(const AuthPage()), (_) => false); }),
            Row2(t('Hapus akun', 'Delete account'), icon: 'trash', danger: true, onTap: () async {
              if (!await confirm(c, t('Hapus akun?', 'Delete account?'), body: t('Semua postingan dan data akunmu akan dihapus permanen.', 'All your posts and account data will be permanently deleted.'), ok: t('Hapus', 'Delete'), danger: true)) return;
              await S.deleteAccount();
              if (c.mounted) Navigator.pushAndRemoveUntil(c, fadeRoute(const AuthPage()), (_) => false);
            }),
            head(t('Tentang', 'About')),
            Row2(t('Kebijakan privasi', 'Privacy policy'), icon: 'shield', onTap: () => Navigator.push(c, fadeRoute(const LegalPage('privacy')))),
            Row2(t('Ketentuan layanan', 'Terms of service'), icon: 'file', onTap: () => Navigator.push(c, fadeRoute(const LegalPage('terms')))),
            Row2(t('Bantuan', 'Help'), icon: 'help', onTap: () => Navigator.push(c, fadeRoute(const LegalPage('help')))),
            Row2(t('Tentang lid', 'About lid'), icon: 'info', onTap: () => Navigator.push(c, fadeRoute(const LegalPage('about')))),
            const SizedBox(height: 36),
            const Center(child: LidLogo(size: 34)),
            const SizedBox(height: 8),
            const Center(child: Text('lid · Misyi · v1.2.0', style: TextStyle(color: Colors.grey, fontSize: 12))),
            const SizedBox(height: 30),
          ]),
        );
      });
}

class BlockedPage extends StatelessWidget {
  const BlockedPage({super.key});
  @override
  Widget build(BuildContext c) => ListenableBuilder(listenable: S, builder: (_, __) {
        final l = S.blockedOf(S.meId!).where((x) => S.user(x) != null).toList();
        return Scaffold(
          appBar: AppBar(title: Text(t('Akun diblokir', 'Blocked accounts')), leading: IconBtn('back', onTap: () => Navigator.pop(c))),
          body: l.isEmpty ? Empty(t('Tidak ada akun diblokir', 'No blocked accounts')) : ListView(children: [for (final x in l) ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 20), leading: Avatar(S.user(x)), title: Text(S.user(x)!['name']), subtitle: Text('@${S.user(x)!['username']}'), trailing: OutlinedButton(style: OutlinedButton.styleFrom(minimumSize: const Size(0, 36)), onPressed: () => S.unblock(x), child: Text(t('Buka blokir', 'Unblock'))))]),
        );
      });
}

class LegalPage extends StatelessWidget {
  final String kind;
  const LegalPage(this.kind, {super.key});
  @override
  Widget build(BuildContext c) {
    final data = {
      'privacy': (t('Kebijakan privasi', 'Privacy policy'), t(
          'lid adalah produk Misyi.\n\nData yang disimpan: nama, username, sandi, usia, bio, postingan, komentar, hubungan, dan pengaturanmu. Pada versi ini semua data disimpan lokal di perangkat atau peramban yang kamu pakai dan tidak dikirim ke server.\n\nMedia (foto, video, audio) diambil lewat kamera lid atau diunggah olehmu dan disimpan lokal. Kamera dan mikrofon hanya aktif saat kamu memakainya.\n\nAudiens: kamu mengatur siapa yang boleh melihat tiap postingan. Postingan anonim tampil sebagai "Anonim" bagi orang lain; tab Anonim di profil hanya terlihat oleh orang yang kamu izinkan.\n\nKamu bisa mengedit, menghapus postingan, mengekspor data, dan menghapus akun kapan saja dari Pengaturan.\n\nUsia minimal pengguna adalah 10 tahun.',
          'lid is a Misyi product.\n\nData stored: your name, username, password, age, bio, posts, comments, relations and settings. In this version all data is stored locally on your device or browser and is not sent to any server.\n\nMedia (photos, videos, audio) is captured with the lid camera or uploaded by you and stored locally. Camera and microphone are only active while you use them.\n\nAudience: you control who can see each post. Anonymous posts appear as "Anonymous" to others; the Anonymous tab on your profile is visible only to people you allow.\n\nYou can edit or delete posts, export your data and delete your account at any time in Settings.\n\nMinimum age is 10.')),
      'terms': (t('Ketentuan layanan', 'Terms of service'), t(
          'Dengan memakai lid kamu setuju untuk:\n\n1. Tidak memposting konten yang melanggar hukum, melecehkan, mengancam, atau mengeksploitasi anak.\n2. Tidak menyamar sebagai orang lain atau mengganggu pengguna lain.\n3. Bertanggung jawab atas isi postingan dan komentarmu, termasuk yang anonim.\n4. Menghormati hubungan: hubungan hanya aktif jika disetujui kedua pihak.\n\nKonten yang dilaporkan dapat ditinjau dan dihapus. Misyi dapat memperbarui ketentuan ini.',
          'By using lid you agree to:\n\n1. Not post unlawful, harassing, threatening content or content exploiting children.\n2. Not impersonate others or harass other users.\n3. Be responsible for your posts and comments, including anonymous ones.\n4. Respect relations: a relation is only active when both sides agree.\n\nReported content may be reviewed and removed. Misyi may update these terms.')),
      'help': (t('Bantuan', 'Help'), t(
          'Feed: semua postingan yang boleh kamu lihat. Tab "Mengikuti" hanya dari akun yang kamu ikuti.\n\nReal: tekan tombol untuk melihat satu postingan acak. Pembuat postingan memilih apakah postingannya boleh masuk Real.\n\nBuat: pilih teks, foto, video (maks 10 detik), atau audio (maks 2 menit). Foto dan video hanya lewat kamera lid (belakang, depan, atau keduanya). Audio boleh upload atau rekam, dan bisa jadi backsound.\n\nHubungan: ajukan hubungan lewat username. Hubungan aktif setelah disetujui.\n\nLink di teks dibuka di peramban lid.\n\nPostingan bisa diedit lewat menu titik tiga.',
          'Feed: every post you may see. The "Following" tab only shows accounts you follow.\n\nReal: press the button for one random post. Authors choose whether their post can appear in Real.\n\nCreate: pick text, photo, video (max 10 s) or audio (max 2 min). Photo and video only through the lid camera (back, front or both). Audio can be uploaded or recorded and can be a backsound.\n\nRelations: request a relation by username. It becomes active once approved.\n\nLinks in text open in the lid browser.\n\nPosts can be edited from the three-dot menu.')),
      'about': (t('Tentang lid', 'About lid'), t('lid v1.2.0\nProduk Misyi.\n\nPlatform sosial bergaya Threads dengan postingan teks, foto, video, audio, postingan anonim, Real acak, dan hubungan dua arah.', 'lid v1.2.0\nA Misyi product.\n\nA Threads-style social platform with text, photo, video and audio posts, anonymous posts, random Real and two-way relations.')),
    }[kind]!;
    return Scaffold(
      appBar: AppBar(title: Text(data.$1), leading: IconBtn('back', onTap: () => Navigator.pop(c))),
      body: ListView(padding: const EdgeInsets.all(22), children: [Fade(Text(data.$2, style: const TextStyle(fontSize: 15, height: 1.55)))]),
    );
  }
}
