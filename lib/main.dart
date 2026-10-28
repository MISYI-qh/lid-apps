import 'package:flutter/material.dart';
import 'auth.dart';
import 'pages.dart';
import 'store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await S.load();
  runApp(const LidApp());
}

ThemeData _th(Brightness b) {
  final d = b == Brightness.dark;
  final bg = d ? Colors.black : Colors.white, fg = d ? const Color(0xFFFAFAFA) : const Color(0xFF0A0A0A);
  final line = d ? const Color(0xFF1F1F1F) : const Color(0xFFEDEDED);
  return ThemeData(
    useMaterial3: true, brightness: b, scaffoldBackgroundColor: bg, splashFactory: NoSplash.splashFactory, highlightColor: Colors.transparent,
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.black, brightness: b).copyWith(surface: bg, onSurface: fg, primary: fg, onPrimary: bg, surfaceTint: Colors.transparent),
    textTheme: Typography.material2021().black.apply(bodyColor: fg, displayColor: fg).copyWith(bodyMedium: TextStyle(color: fg, letterSpacing: -.1, height: 1.35)),
    appBarTheme: AppBarTheme(backgroundColor: bg, foregroundColor: fg, elevation: 0, scrolledUnderElevation: 0, centerTitle: true),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: bg, surfaceTintColor: Colors.transparent, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28)))),
    dialogTheme: DialogTheme(backgroundColor: bg, surfaceTintColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
    filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(backgroundColor: fg, foregroundColor: bg, shape: const StadiumBorder(), minimumSize: const Size(0, 48), textStyle: const TextStyle(fontWeight: FontWeight.w600))),
    outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(foregroundColor: fg, side: BorderSide(color: line, width: 1.4), shape: const StadiumBorder(), minimumSize: const Size(0, 48), textStyle: const TextStyle(fontWeight: FontWeight.w600))),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: fg)),
    inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: fg.withOpacity(.05), contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: fg.withOpacity(.5), width: 1))),
    snackBarTheme: SnackBarThemeData(behavior: SnackBarBehavior.floating, backgroundColor: fg, contentTextStyle: TextStyle(color: bg), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
    dividerTheme: DividerThemeData(color: line, thickness: 1, space: 1),
    dividerColor: line,
  );
}

class LidApp extends StatefulWidget {
  const LidApp({super.key});
  @override
  State<LidApp> createState() => _LidAppS();
}
class _LidAppS extends State<LidApp> with WidgetsBindingObserver {
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); }
  @override
  void dispose() { WidgetsBinding.instance.removeObserver(this); super.dispose(); }
  @override
  void didChangeLocales(List<Locale>? l) => setState(() {});
  @override
  Widget build(BuildContext c) => ListenableBuilder(
      listenable: S,
      builder: (_, __) => MaterialApp(
          title: 'lid', debugShowCheckedModeBanner: false,
          themeMode: S.theme == 'dark' ? ThemeMode.dark : S.theme == 'light' ? ThemeMode.light : ThemeMode.system,
          theme: _th(Brightness.light), darkTheme: _th(Brightness.dark), home: S.meId == null ? const AuthPage() : const Shell()));
}
