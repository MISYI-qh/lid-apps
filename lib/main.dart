import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'auth.dart';
import 'media.dart';
import 'pages.dart';
import 'store.dart';
import 'widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LidApp());
}

ThemeData _th(Brightness b) {
  final d = b == Brightness.dark;
  final bg = d ? Colors.black : Colors.white, fg = d ? const Color(0xFFFAFAFA) : const Color(0xFF0A0A0A);
  final line = d ? const Color(0xFF1F1F1F) : const Color(0xFFEDEDED);
  return ThemeData(
    useMaterial3: true, brightness: b, scaffoldBackgroundColor: bg, splashFactory: NoSplash.splashFactory, highlightColor: Colors.transparent,
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.black, brightness: b).copyWith(surface: bg, onSurface: fg, primary: fg, onPrimary: bg),
    appBarTheme: AppBarTheme(backgroundColor: bg, foregroundColor: fg, elevation: 0, scrolledUnderElevation: 0, centerTitle: true, surfaceTintColor: Colors.transparent),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: bg, surfaceTintColor: Colors.transparent, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28)))),
    filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(backgroundColor: fg, foregroundColor: bg, shape: const StadiumBorder(), minimumSize: const Size(0, 48), textStyle: const TextStyle(fontWeight: FontWeight.w600))),
    outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(foregroundColor: fg, side: BorderSide(color: line, width: 1.4), shape: const StadiumBorder(), minimumSize: const Size(0, 48), textStyle: const TextStyle(fontWeight: FontWeight.w600))),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: fg)),
    switchTheme: SwitchThemeData(thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? bg : Colors.grey), trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? fg : fg.withOpacity(.12)), trackOutlineColor: WidgetStateProperty.all(Colors.transparent)),
    inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: fg.withOpacity(.05), contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: fg.withOpacity(.5), width: 1))),
    snackBarTheme: SnackBarThemeData(behavior: SnackBarBehavior.floating, backgroundColor: fg, contentTextStyle: TextStyle(color: bg), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
    dividerColor: line,
  );
}

class LidApp extends StatefulWidget {
  const LidApp({super.key});
  @override
  State<LidApp> createState() => _LidAppS();
}
class _LidAppS extends State<LidApp> with WidgetsBindingObserver {
  bool ready = false;
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); _init(); }
  Future<void> _init() async {
    final t0 = DateTime.now();
    await MediaStore.init();
    await S.load();
    final ms = DateTime.now().difference(t0).inMilliseconds;
    if (ms < 900) await Future.delayed(Duration(milliseconds: 900 - ms));
    if (mounted) setState(() => ready = true);
  }
  @override
  void dispose() { WidgetsBinding.instance.removeObserver(this); super.dispose(); }
  @override
  void didChangeLocales(List<Locale>? l) => setState(() {});

  Widget _frame(BuildContext ctx, Widget? child) {
    final th = Theme.of(ctx);
    final dark = th.brightness == Brightness.dark;
    final wide = MediaQuery.of(ctx).size.width > 700;
    final ic = dark ? Brightness.light : Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(systemNavigationBarColor: th.scaffoldBackgroundColor, systemNavigationBarDividerColor: Colors.transparent, systemNavigationBarIconBrightness: ic, statusBarColor: Colors.transparent, statusBarIconBrightness: ic, statusBarBrightness: dark ? Brightness.dark : Brightness.light),
      child: Container(
        color: dark ? const Color(0xFF0A0A0A) : const Color(0xFFF7F7F7),
        child: Center(child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: DecoratedBox(
            decoration: BoxDecoration(color: th.scaffoldBackgroundColor, border: wide ? Border.symmetric(vertical: BorderSide(color: th.dividerColor)) : null),
            child: ClipRect(child: child ?? const SizedBox()),
          ),
        )),
      ),
    );
  }

  @override
  Widget build(BuildContext c) {
    if (!ready) {
      return MaterialApp(title: 'lid', debugShowCheckedModeBanner: false, themeMode: ThemeMode.system, theme: _th(Brightness.light), darkTheme: _th(Brightness.dark), builder: _frame, home: const LoadingScreen());
    }
    return ListenableBuilder(
        listenable: S,
        builder: (_, __) {
          SystemChrome.setEnabledSystemUIMode(S.hideNav ? SystemUiMode.immersiveSticky : SystemUiMode.manual, overlays: SystemUiOverlay.values);
          return MaterialApp(
              title: 'lid', debugShowCheckedModeBanner: false,
              themeMode: S.theme == 'dark' ? ThemeMode.dark : S.theme == 'light' ? ThemeMode.light : ThemeMode.system,
              theme: _th(Brightness.light), darkTheme: _th(Brightness.dark), builder: _frame,
              home: S.meId == null ? const AuthPage() : const Shell());
        });
  }
}
