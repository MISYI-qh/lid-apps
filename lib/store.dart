import 'dart:convert';
import 'dart:math';
import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef M = Map<String, dynamic>;
final S = Store();
String t(String id, String en) => S.langCode == 'id' ? id : en;
String uid() => '${DateTime.now().microsecondsSinceEpoch}${Random().nextInt(999)}';
int ageOf(DateTime b) {
  final n = DateTime.now();
  var a = n.year - b.year;
  if (n.month < b.month || (n.month == b.month && n.day < b.day)) a--;
  return a;
}

const audKeys = ['all', 'friend', 'best', 'partner', 'family', 'allrel', 'pick'];
String audLabel(String k) => {
      'all': t('Semua orang', 'Everyone'),
      'friend': t('Teman', 'Friends'),
      'best': t('Sahabat', 'Best friends'),
      'partner': t('Pasangan', 'Partner'),
      'family': t('Keluarga', 'Family'),
      'allrel': t('Semua hubungan', 'All relations'),
      'pick': t('Pilih orang', 'Pick people'),
      'none': t('Hanya saya', 'Only me'),
    }[k]!;
String relLabel(String k) => audLabel(k == 'best' ? 'best' : k);

class Store extends ChangeNotifier {
  late SharedPreferences _p;
  List<M> users = [], posts = [], rels = [], follows = [], notifs = [], comments = [], reports = [];
  String? meId;
  String lang = 'system', theme = 'system';
  String get langCode => lang == 'system' ? (PlatformDispatcher.instance.locale.languageCode == 'id' ? 'id' : 'en') : lang;

  Future<void> load() async {
    _p = await SharedPreferences.getInstance();
    List<M> l(String k) => (jsonDecode(_p.getString(k) ?? '[]') as List).map((e) => M.from(e)).toList();
    users = l('users'); posts = l('posts'); rels = l('rels'); follows = l('follows');
    notifs = l('notifs'); comments = l('comments'); reports = l('reports');
    meId = _p.getString('me'); lang = _p.getString('lang') ?? 'system'; theme = _p.getString('theme') ?? 'system';
    if (meId != null && user(meId!) == null) meId = null;
  }

  void save() {
    for (final e in {'users': users, 'posts': posts, 'rels': rels, 'follows': follows, 'notifs': notifs, 'comments': comments, 'reports': reports}.entries) {
      _p.setString(e.key, jsonEncode(e.value));
    }
    _p.setString('lang', lang); _p.setString('theme', theme);
    if (meId == null) { _p.remove('me'); } else { _p.setString('me', meId!); }
    notifyListeners();
  }

  M? user(String id) { for (final u in users) { if (u['id'] == id) return u; } return null; }
  M get me => user(meId!)!;

  String? register(String name, String username, String pass, DateTime? birth) {
    final un = username.trim().toLowerCase();
    if (name.trim().isEmpty) return t('Nama wajib diisi', 'Name is required');
    if (!RegExp(r'^[a-z0-9_.]{3,20}$').hasMatch(un)) return t('Username 3-20 karakter (huruf, angka, _ .)', 'Username 3-20 chars (letters, numbers, _ .)');
    if (users.any((u) => u['username'] == un)) return t('Username sudah dipakai', 'Username already taken');
    if (pass.isEmpty) return t('Sandi wajib diisi', 'Password is required');
    if (birth == null) return t('Pilih usia dulu', 'Pick your age first');
    if (ageOf(birth) < 10) return t('Usia minimal 10 tahun', 'Minimum age is 10');
    final u = {'id': uid(), 'name': name.trim(), 'username': un, 'pass': pass, 'bio': '', 'birth': birth.toIso8601String(), 'avatar': null, 'defAud': 'all', 'anonVis': 'none'};
    users.add(u); meId = u['id'] as String; save();
    return null;
  }

  String? login(String username, String pass) {
    for (final u in users) {
      if (u['username'] == username.trim().toLowerCase() && u['pass'] == pass) { meId = u['id']; save(); return null; }
    }
    return t('Username atau sandi salah', 'Wrong username or password');
  }

  void logout() { meId = null; save(); }

  // ---- hubungan ----
  M? relBetween(String a, String b) {
    for (final r in rels) { if ((r['a'] == a && r['b'] == b) || (r['a'] == b && r['b'] == a)) return r; }
    return null;
  }
  String? relType(String a, String b) { final r = relBetween(a, b); return (r != null && r['status'] == 'ok') ? r['type'] as String : null; }
  void requestRel(String to, String type) {
    if (relBetween(meId!, to) != null) return;
    rels.add({'id': uid(), 'a': meId, 'b': to, 'type': type, 'status': 'pending'});
    notify(to, 'rel_req'); save();
  }
  void answerRel(M r, bool ok) {
    if (ok) { r['status'] = 'ok'; notify(r['a'], 'rel_ok'); } else { rels.remove(r); }
    save();
  }

  // ---- follow ----
  bool following(String id) => follows.any((f) => f['from'] == meId && f['to'] == id);
  void toggleFollow(String id) {
    final i = follows.indexWhere((f) => f['from'] == meId && f['to'] == id);
    if (i >= 0) { follows.removeAt(i); } else { follows.add({'from': meId, 'to': id}); notify(id, 'follow'); }
    save();
  }
  List<String> followersOf(String id) => [for (final f in follows) if (f['to'] == id) f['from'] as String];
  List<String> followingOf(String id) => [for (final f in follows) if (f['from'] == id) f['to'] as String];
  List<String> relsOf(String id) => [for (final r in rels) if (r['status'] == 'ok' && (r['a'] == id || r['b'] == id)) (r['a'] == id ? r['b'] : r['a']) as String];

  // ---- privasi ----
  bool canSee(String aud, String owner, String viewer, [List? picks]) {
    if (owner == viewer || aud == 'all') return true;
    if (aud == 'none') return false;
    if (aud == 'pick') return (picks ?? []).contains(viewer);
    final r = relType(owner, viewer);
    if (aud == 'allrel') return r != null;
    return r == aud;
  }
  bool visible(M p) => canSee(p['aud'], p['author'], meId!, p['picks']);
  List<M> feed() => posts.where(visible).toList()..sort((a, b) => (b['time'] as int).compareTo(a['time'] as int));
  List<M> realPool() => feed().where((p) => p['real'] == true).toList();
  List<M> postsOf(String id, {bool anon = false}) => feed().where((p) => p['author'] == id && (p['anon'] == true) == anon).toList();
  bool canSeeAnonTab(String id) => id == meId || canSee(user(id)?['anonVis'] ?? 'none', id, meId!);

  // ---- notif ----
  void notify(String to, String type, {String? post}) {
    if (to == meId) return;
    notifs.add({'id': uid(), 'to': to, 'type': type, 'from': meId, 'post': post, 'time': DateTime.now().millisecondsSinceEpoch, 'read': false});
  }
  int get unread => notifs.where((n) => n['to'] == meId && n['read'] != true).length;
}
