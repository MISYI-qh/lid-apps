import 'dart:convert';
import 'dart:math';
import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'media.dart';

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
String linkOf(String postId) => kIsWeb ? '${Uri.base.origin}/#/post/$postId' : 'lid://post/$postId';

const audKeys = ['all', 'friend', 'best', 'partner', 'family', 'allrel', 'pick'];
const anonKeys = ['none', 'all', 'friend', 'best', 'partner', 'family', 'allrel'];
String audLabel(String k) => {
      'all': t('Semua orang', 'Everyone'),
      'friend': t('Teman', 'Friends'),
      'best': t('Sahabat', 'Best friends'),
      'partner': t('Pasangan', 'Partner'),
      'family': t('Keluarga', 'Family'),
      'allrel': t('Semua hubungan', 'All relations'),
      'pick': t('Pilih orang', 'Pick people'),
      'none': t('Hanya saya', 'Only me'),
    }[k] ?? k;
String relLabel(String k) => audLabel(k);
/// Isi media post (kompatibel dengan post lama): [{k, kind: photo|video}]
List<M> itemsOf(M p) {
  if (p['items'] != null) return [for (final e in (p['items'] as List)) M.from(e)];
  final ty = p['type'];
  if (ty == 'photo' || ty == 'video') return [for (final k in List<String>.from(p['media'] ?? [])) {'k': k, 'kind': ty}];
  return [];
}
/// Audio post: {k, back: true jika backsound}
M? audioOf(M p) {
  if (p['audio'] != null) return M.from(p['audio']);
  if (p['type'] == 'audio' && (p['media'] as List?)?.isNotEmpty == true) return {'k': p['media'][0], 'back': false};
  if (p['sound'] != null) return {'k': p['sound'], 'back': true};
  return null;
}
List<String> keysOf(M p) { final a = audioOf(p); return [for (final i in itemsOf(p)) i['k'] as String, if (a != null) a['k'] as String]; }

class Store extends ChangeNotifier {
  late SharedPreferences _p;
  List<M> users = [], posts = [], rels = [], follows = [], notifs = [], comments = [], reports = [];
  String? meId;
  String lang = 'system', theme = 'system';
  bool hideNav = false;
  String get langCode => lang == 'system' ? (PlatformDispatcher.instance.locale.languageCode == 'id' ? 'id' : 'en') : lang;

  Future<void> load() async {
    _p = await SharedPreferences.getInstance();
    List<M> l(String k) { try { return (jsonDecode(_p.getString(k) ?? '[]') as List).map((e) => M.from(e)).toList(); } catch (_) { return []; } }
    users = l('users'); posts = l('posts'); rels = l('rels'); follows = l('follows');
    notifs = l('notifs'); comments = l('comments'); reports = l('reports');
    meId = _p.getString('me'); lang = _p.getString('lang') ?? 'system'; theme = _p.getString('theme') ?? 'system'; hideNav = _p.getBool('hideNav') ?? false;
    if (meId != null && user(meId!) == null) meId = null;
  }

  void save() {
    for (final e in {'users': users, 'posts': posts, 'rels': rels, 'follows': follows, 'notifs': notifs, 'comments': comments, 'reports': reports}.entries) {
      _p.setString(e.key, jsonEncode(e.value));
    }
    _p.setString('lang', lang); _p.setString('theme', theme); _p.setBool('hideNav', hideNav);
    if (meId == null) { _p.remove('me'); } else { _p.setString('me', meId!); }
    notifyListeners();
  }

  M? user(String id) { for (final u in users) { if (u['id'] == id) return u; } return null; }
  M get me => user(meId!)!;
  M? post(String id) { for (final p in posts) { if (p['id'] == id) return p; } return null; }

  // ---- akun ----
  static final _unRe = RegExp(r'^[a-z0-9_.]{3,20}$');
  String? register(String name, String username, String pass, DateTime? birth) {
    final un = username.trim().toLowerCase();
    if (name.trim().isEmpty) return t('Nama wajib diisi', 'Name is required');
    if (!_unRe.hasMatch(un)) return t('Username 3-20 karakter (huruf, angka, _ .)', 'Username 3-20 chars (letters, numbers, _ .)');
    if (users.any((u) => u['username'] == un)) return t('Username sudah dipakai', 'Username already taken');
    if (pass.isEmpty) return t('Sandi wajib diisi', 'Password is required');
    if (birth == null) return t('Pilih usia dulu', 'Pick your age first');
    if (ageOf(birth) < 10) return t('Usia minimal 10 tahun', 'Minimum age is 10');
    final u = <String, dynamic>{'id': uid(), 'name': name.trim(), 'username': un, 'pass': pass, 'bio': '', 'birth': birth.toIso8601String(), 'avatar': null, 'defAud': 'all', 'anonVis': 'none', 'commentAud': 'all', 'blocked': <String>[], 'notif': {'comment': true, 'follow': true, 'rel': true}, 'created': DateTime.now().millisecondsSinceEpoch};
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
  String? setUsername(String username) {
    final un = username.trim().toLowerCase();
    if (!_unRe.hasMatch(un)) return t('Username 3-20 karakter (huruf, angka, _ .)', 'Username 3-20 chars (letters, numbers, _ .)');
    if (users.any((u) => u['username'] == un && u['id'] != meId)) return t('Username sudah dipakai', 'Username already taken');
    me['username'] = un; save(); return null;
  }
  Future<void> deleteAccount() async {
    final id = meId!;
    for (final p in posts.where((p) => p['author'] == id).toList()) { await deletePost(p, notify: false); }
    comments.removeWhere((c) => c['by'] == id);
    rels.removeWhere((r) => r['a'] == id || r['b'] == id);
    follows.removeWhere((f) => f['from'] == id || f['to'] == id);
    notifs.removeWhere((n) => n['to'] == id || n['from'] == id);
    final av = me['avatar']; if (av != null) await MediaStore.remove([av as String]);
    users.removeWhere((u) => u['id'] == id);
    meId = null; save();
  }
  Future<void> setAvatar(String? key) async {
    final old = me['avatar'];
    me['avatar'] = key;
    if (old != null) await MediaStore.remove([old as String]);
    save();
  }
  String exportJson() => const JsonEncoder.withIndent('  ').convert({
        'user': {...me, 'pass': '***'},
        'posts': posts.where((p) => p['author'] == meId).toList(),
        'comments': comments.where((c) => c['by'] == meId).toList(),
        'relations': rels.where((r) => r['a'] == meId || r['b'] == meId).toList(),
        'following': followingOf(meId!),
        'followers': followersOf(meId!),
      });

  // ---- blokir ----
  List<String> blockedOf(String id) => List<String>.from(user(id)?['blocked'] ?? []);
  bool blockedEither(String a, String b) => blockedOf(a).contains(b) || blockedOf(b).contains(a);
  void block(String id) {
    final l = blockedOf(meId!); if (!l.contains(id)) l.add(id);
    me['blocked'] = l;
    follows.removeWhere((f) => (f['from'] == meId && f['to'] == id) || (f['from'] == id && f['to'] == meId));
    rels.removeWhere((r) => (r['a'] == meId && r['b'] == id) || (r['a'] == id && r['b'] == meId));
    save();
  }
  void unblock(String id) { me['blocked'] = blockedOf(meId!)..remove(id); save(); }

  // ---- hubungan ----
  M? relBetween(String a, String b) {
    for (final r in rels) { if ((r['a'] == a && r['b'] == b) || (r['a'] == b && r['b'] == a)) return r; }
    return null;
  }
  String? relType(String a, String b) { final r = relBetween(a, b); return (r != null && r['status'] == 'ok') ? r['type'] as String : null; }
  void requestRel(String to, String type) {
    if (relBetween(meId!, to) != null || blockedEither(meId!, to)) return;
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
    if (blockedEither(meId!, id)) return;
    final i = follows.indexWhere((f) => f['from'] == meId && f['to'] == id);
    if (i >= 0) { follows.removeAt(i); } else { follows.add({'from': meId, 'to': id}); notify(id, 'follow'); }
    save();
  }
  List<String> followersOf(String id) => [for (final f in follows) if (f['to'] == id) f['from'] as String];
  List<String> followingOf(String id) => [for (final f in follows) if (f['from'] == id) f['to'] as String];
  List<String> relsOf(String id) => [for (final r in rels) if (r['status'] == 'ok' && (r['a'] == id || r['b'] == id)) (r['a'] == id ? r['b'] : r['a']) as String];

  // ---- privasi & post ----
  bool canSee(String aud, String owner, String viewer, [List? picks]) {
    if (owner == viewer || aud == 'all') return true;
    if (aud == 'none') return false;
    if (aud == 'pick') return (picks ?? []).contains(viewer);
    final r = relType(owner, viewer);
    if (aud == 'allrel') return r != null;
    return r == aud;
  }
  bool visible(M p) => !blockedEither(p['author'], meId!) && canSee(p['aud'], p['author'], meId!, p['picks']);
  List<M> feed({bool onlyFollowing = false}) {
    final fl = followingOf(meId!);
    return posts.where((p) => visible(p) && (!onlyFollowing || (p['anon'] != true && (fl.contains(p['author']) || p['author'] == meId)))).toList()..sort((a, b) => (b['time'] as int).compareTo(a['time'] as int));
  }
  List<M> realPool() => feed().where((p) => p['real'] == true).toList();
  List<M> postsOf(String id, {bool anon = false}) => feed().where((p) => p['author'] == id && (p['anon'] == true) == anon).toList();
  bool canSeeAnonTab(String id) => id == meId || canSee(user(id)?['anonVis'] ?? 'none', id, meId!);
  bool canComment(M p) {
    final a = p['author'] as String;
    if (a == meId) return true;
    if (blockedEither(a, meId!)) return false;
    final c = user(a)?['commentAud'] ?? 'all';
    if (c == 'none') return false;
    if (c == 'allrel') return relType(a, meId!) != null;
    return true;
  }
  Future<void> deletePost(M p, {bool notify = true}) async {
    await MediaStore.remove(keysOf(p));
    comments.removeWhere((c) => c['post'] == p['id']);
    notifs.removeWhere((n) => n['post'] == p['id']);
    posts.remove(p);
    if (notify) save();
  }

  // ---- komentar ----
  List<M> commentsOf(String postId, {String? parent}) => comments.where((c) => c['post'] == postId && c['parent'] == parent).toList();
  int commentCount(String postId) => comments.where((c) => c['post'] == postId).length;
  void addComment(M p, String text, {M? parent}) {
    comments.add({'id': uid(), 'post': p['id'], 'by': meId, 'text': text, 'time': DateTime.now().millisecondsSinceEpoch, 'parent': parent?['id']});
    if (parent != null) notify(parent['by'], 'reply', post: p['id']);
    if (parent == null || parent['by'] != p['author']) notify(p['author'], 'comment', post: p['id']);
    save();
  }
  void deleteComment(M c) {
    final ids = <String>{c['id']};
    var grew = true;
    while (grew) { grew = false; for (final x in comments) { if (!ids.contains(x['id']) && ids.contains(x['parent'])) { ids.add(x['id']); grew = true; } } }
    comments.removeWhere((x) => ids.contains(x['id']));
    save();
  }
  void report(String kind, String target, String reason) { reports.add({'id': uid(), 'kind': kind, 'target': target, 'by': meId, 'reason': reason, 'time': DateTime.now().millisecondsSinceEpoch}); save(); }

  // ---- notif ----
  void notify(String to, String type, {String? post}) {
    if (to == meId) return;
    final u = user(to); if (u == null) return;
    final g = type == 'reply' ? 'comment' : type.startsWith('rel') ? 'rel' : type;
    final pr = (u['notif'] as Map?) ?? {};
    if (pr[g] == false) return;
    notifs.add({'id': uid(), 'to': to, 'type': type, 'from': meId, 'post': post, 'time': DateTime.now().millisecondsSinceEpoch, 'read': false});
  }
  int get unread => notifs.where((n) => n['to'] == meId && n['read'] != true).length;

  Future<void> wipeEverything() async {
    await MediaStore.clear();
    await _p.clear();
    users = []; posts = []; rels = []; follows = []; notifs = []; comments = []; reports = []; meId = null; lang = 'system'; theme = 'system';
    notifyListeners();
  }
}
