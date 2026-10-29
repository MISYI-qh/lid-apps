import 'package:flutter/material.dart';
import 'icons.dart';
import 'pages.dart';
import 'store.dart';
import 'widgets.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override
  State<AuthPage> createState() => _AuthS();
}
class _AuthS extends State<AuthPage> {
  bool reg = false, show = false;
  final name = TextEditingController(), user = TextEditingController(), pass = TextEditingController();
  DateTime? birth;
  String? err;

  void go() {
    final e = reg ? S.register(name.text, user.text, pass.text, birth) : S.login(user.text, pass.text);
    if (e != null) { setState(() => err = e); return; }
    Navigator.pushAndRemoveUntil(context, fadeRoute(const Boot()), (_) => false);
  }

  @override
  Widget build(BuildContext c) => Scaffold(
        body: SafeArea(
          child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: ListView(shrinkWrap: true, padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40), children: [
            const Center(child: Float(LidLogo(size: 84))),
            const SizedBox(height: 14),
            const Center(child: Text('lid', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: 3))),
            const SizedBox(height: 40),
            Fade(Column(children: [
              AnimatedSize(duration: const Duration(milliseconds: 300), curve: Curves.easeOut, child: Column(children: [
                if (reg) ...[TextField(controller: name, textInputAction: TextInputAction.next, decoration: InputDecoration(hintText: t('Nama', 'Name'))), const SizedBox(height: 12)],
                TextField(controller: user, autocorrect: false, textInputAction: TextInputAction.next, decoration: const InputDecoration(hintText: 'Username')),
                const SizedBox(height: 12),
                TextField(controller: pass, obscureText: !show, onSubmitted: (_) { if (!reg) go(); }, decoration: InputDecoration(hintText: t('Sandi', 'Password'), suffixIcon: IconBtn(show ? 'eyeoff' : 'eye', size: 20, onTap: () => setState(() => show = !show)))),
                if (reg) ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async { final d = await pickBirth(c, birth); if (d != null) setState(() => birth = d); },
                    child: Container(height: 54, padding: const EdgeInsets.symmetric(horizontal: 18), decoration: BoxDecoration(color: Theme.of(c).colorScheme.onSurface.withOpacity(.05), borderRadius: BorderRadius.circular(18)),
                        child: Row(children: [const Ic('calendar', size: 20), const SizedBox(width: 12), Text(birth == null ? t('Pilih usia', 'Pick age') : t('Usia ${ageOf(birth!)} tahun', 'Age ${ageOf(birth!)}'), style: TextStyle(color: birth == null ? Colors.grey : null))])),
                  ),
                ],
              ])),
              if (err != null) Padding(padding: const EdgeInsets.only(top: 14), child: Text(err!, style: const TextStyle(color: Colors.red, fontSize: 13))),
              const SizedBox(height: 24),
              SizedBox(width: double.infinity, child: FilledButton(onPressed: go, child: Text(reg ? t('Daftar', 'Sign up') : t('Masuk', 'Log in')))),
              const SizedBox(height: 6),
              TextButton(onPressed: () => setState(() { reg = !reg; err = null; }), child: Text(reg ? t('Sudah punya akun? Masuk', 'Have an account? Log in') : t('Belum punya akun? Daftar', 'No account? Sign up'), style: const TextStyle(color: Colors.grey))),
            ])),
          ]))),
        ),
      );
}

/// Pemilih usia buatan sendiri (roda tanggal, bulan, tahun)
Future<DateTime?> pickBirth(BuildContext c, DateTime? init) {
  final now = DateTime.now();
  var d = init?.day ?? 1, m = init?.month ?? 1, y = init?.year ?? now.year - 18;
  final years = List.generate(101, (i) => now.year - i);
  final months = t('Jan,Feb,Mar,Apr,Mei,Jun,Jul,Agu,Sep,Okt,Nov,Des', 'Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec').split(',');
  return showModalBottomSheet<DateTime>(
    context: c, showDragHandle: true,
    builder: (_) => StatefulBuilder(builder: (ctx, set) {
      Widget wheel(List<String> items, int sel, ValueChanged<int> on) => Expanded(
          child: ListWheelScrollView.useDelegate(
              itemExtent: 46, perspective: .003, diameterRatio: 1.8, physics: const FixedExtentScrollPhysics(),
              controller: FixedExtentScrollController(initialItem: sel), onSelectedItemChanged: (i) => set(() => on(i)),
              childDelegate: ListWheelChildListDelegate(children: [for (final s in items) Center(child: Text(s, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500)))])));
      final age = ageOf(DateTime(y, m, d > 28 ? 28 : d));
      return SizedBox(height: 340, child: Column(children: [
        Text(t('Usia $age tahun', 'Age $age'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        Expanded(child: Row(children: [
          wheel([for (var i = 1; i <= 31; i++) '$i'], d - 1, (i) => d = i + 1),
          wheel(months, m - 1, (i) => m = i + 1),
          wheel([for (final x in years) '$x'], years.indexOf(y), (i) => y = years[i]),
        ])),
        Padding(padding: const EdgeInsets.fromLTRB(24, 8, 24, 24), child: SizedBox(width: double.infinity, child: FilledButton(onPressed: () => Navigator.pop(ctx, DateTime(y, m, d > 28 ? 28 : d)), child: Text(t('Simpan', 'Save'))))),
      ]));
    }),
  );
}

/// Layar loading setelah masuk / daftar
class Boot extends StatefulWidget {
  const Boot({super.key});
  @override
  State<Boot> createState() => _BootS();
}
class _BootS extends State<Boot> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1500), () { if (mounted) Navigator.pushReplacement(context, fadeRoute(const Shell())); });
  }
  @override
  Widget build(BuildContext c) => LoadingScreen(label: t('Menyiapkan lid...', 'Getting lid ready...'));
}
