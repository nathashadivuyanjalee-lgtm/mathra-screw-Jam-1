import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/brand.dart';

enum BotLang { si, en }

class BotLink {
  final String label;
  final String url;
  final IconData icon;
  const BotLink(this.label, this.url, this.icon);
}

class BotReply {
  final String text;
  final BotLang lang;
  final List<BotLink> links;
  const BotReply(this.text, this.lang, [this.links = const []]);
}

/// Small offline, rule-based brain. No internet, no API limits.
/// Understands Sinhala, English and "Singlish" keywords.
abstract final class MathraBot {
  static final _rng = math.Random();

  static bool isSinhala(String s) => RegExp(r'[\u0D80-\u0DFF]').hasMatch(s);

  static String pick(List<String> l) => l[_rng.nextInt(l.length)];

  static const _tiktok = BotLink('TikTok', Brand.tiktokUrl, Icons.music_note_rounded);
  static const _github = BotLink('GitHub', Brand.githubUrl, Icons.code_rounded);
  static const _call = BotLink('Call', 'tel:${Brand.phone}', Icons.call_rounded);
  static const _wa = BotLink('WhatsApp', Brand.whatsappUrl, Icons.chat_rounded);

  static BotReply welcome() => const BotReply(
        'ආයුබෝවන්! 👋 මම Mathra AI Chat Bot.\n'
        'ක්‍රීඩාව, මාව හැදුවේ කවුද කියලා, හෝ ඕනෑම දෙයක් සිංහලෙන් හෝ English වලින් අහන්න.\n\n'
        "Hi! I'm Mathra AI Chat Bot. Ask me anything in Sinhala or English 🔩",
        BotLang.si,
      );

  static BotReply reply(String input, {required int level}) {
    final text = input.trim();
    final si = isSinhala(text);
    final lang = si ? BotLang.si : BotLang.en;
    final low = text.toLowerCase();
    final tokens = low.split(RegExp(r'[^a-z0-9]+')).where((e) => e.isNotEmpty).toSet();

    bool has(List<String> keys) {
      for (final k in keys) {
        final ascii = RegExp(r'^[a-z0-9 ]+$').hasMatch(k);
        if (ascii && !k.contains(' ') && k.length <= 4) {
          if (tokens.contains(k)) return true;
        } else if (low.contains(k)) {
          return true;
        }
      }
      return false;
    }

    // --- Math ------------------------------------------------------------
    final m = _tryMath(low);
    if (m != null) {
      return BotReply(
        si ? 'උත්තරය: $m 🧮' : 'The answer is $m 🧮',
        lang,
      );
    }

    // --- Contact ---------------------------------------------------------
    if (has([
      'contact', 'number', 'phone', 'call', 'whatsapp', 'reach', 'mobile', 'email',
      'සම්බන්ධ', 'නම්බර්', 'නම්බරේ', 'අංකය', 'දුරකථන', 'කතා කරන්න', 'ෆෝන්', 'වට්සැප්', 'අමතන්න',
      'contact karanna', 'namber', 'කන්ටැක්ට්', 'කොන්ටැක්ට්', 'කන්ටැක්ට', 'කොන්ටැක්ට', 'කොන්ටැක්',
    ])) {
      return BotReply(
        si
            ? 'හදපු කෙනාව සම්බන්ධ කරගන්න: ${Brand.phone} 📞\nCall හෝ WhatsApp කරන්න පුළුවන්.'
            : 'To contact my creator, call or WhatsApp: ${Brand.phone} 📞',
        lang,
        const [_call, _wa],
      );
    }

    // --- Creator (most important) ---------------------------------------
    if (has([
      'හැදුවේ', 'හැදුවෙ', 'හැදුව', 'හැදූ', 'හදපු', 'හදලා දුන්', 'නිර්මාණ', 'අයිතිකාර', 'අයිතිකරු',
      'who made', 'who created', 'who built', 'who developed', 'who owns', 'made you', 'created you',
      'built you', 'your creator', 'your developer', 'your owner', 'developer', 'creator',
      'hadwe', 'haduwe', 'hadapu', 'haduwa',
    ])) {
      return BotReply(
        si
            ? 'මාව හැදුවේ Mathra Quotes TikTok අයිතිකරු ${Brand.ownerSi} (${Brand.owner}) 💛'
            : 'I was created by ${Brand.owner}, the owner of Mathra Quotes on TikTok 💛',
        lang,
        const [_tiktok, _github],
      );
    }

    // --- TikTok / GitHub -------------------------------------------------
    if (has(['tiktok', 'tik tok', 'ටික් ටොක්', 'ටික්ටොක්', 'ටික්', 'follow', 'ෆලෝ'])) {
      return BotReply(
        si
            ? 'Mathra Quotes TikTok එක Follow කරන්න 🎵 නිතරම අලුත් quotes!'
            : 'Follow Mathra Quotes on TikTok 🎵 fresh quotes all the time!',
        lang,
        const [_tiktok],
      );
    }
    if (has(['github', 'git hub', 'ගිත් හබ්', 'ගිතුබ්', 'ගිට්හබ්', 'source code', 'repo'])) {
      return BotReply(
        si
            ? 'මෙන්න ${Brand.owner} ගේ GitHub එක 💻'
            : "Here's ${Brand.owner}'s GitHub profile 💻",
        lang,
        const [_github],
      );
    }

    // --- Who are you / name ---------------------------------------------
    if (has([
      'your name', 'who are you', 'what are you', 'ඔයාගේ නම', 'ඔයාගෙ නම', 'ඔයා කවුද', 'නම මොකක්ද',
      'oyage nama', 'oya kawda',
    ])) {
      return BotReply(
        si
            ? 'මගේ නම Mathra AI Chat Bot 🤖 මම ${Brand.appName} ක්‍රීඩාවේ සහායකයා!'
            : "I'm Mathra AI Chat Bot 🤖 your helper inside ${Brand.appName}!",
        lang,
      );
    }

    // --- Level / progress -----------------------------------------------
    if (has(['my level', 'my score', 'progress', 'ලෙවල් එක', 'මගේ ලෙවල්', 'මගේ level', 'කීවෙනි'])) {
      return BotReply(
        si ? 'ඔයාගේ දැනට උපරිම level එක: $level 🔥 දිගටම යන්න!' : 'Your highest level so far is $level 🔥 Keep going!',
        lang,
      );
    }

    // --- How to play / tips ---------------------------------------------
    if (has(['how to play', 'how do i play', 'rules', 'instructions', 'කොහොමද ගහන්නේ', 'කොහොමද සෙල්ලම්',
        'කොහොමද ක්‍රීඩා', 'ක්‍රීඩා කරන්නේ', 'සෙල්ලම් කරන්නේ', 'play karanne', 'kohomada play'])) {
      return BotReply(
        si
            ? '🔩 ක්‍රීඩා කරන විදිය:\n'
                '1) Plate එකේ ඇති screw එක ඔබා ගලවන්න.\n'
                '2) ඒක ගැලපෙන පාට toolbox එකට දමන්න.\n'
                '3) Toolbox පිරුණාම ඉවත් වෙනවා.\n'
                '4) හැම screw එකක්ම ඉවත් කළාම level එක ජයයි!\n'
                'Pinch කර zoom කරන්න, double-tap කර reset කරන්න.'
            : '🔩 How to play:\n'
                '1) Tap a screw on a plate to unscrew it.\n'
                '2) Drop it into the toolbox of the same colour.\n'
                '3) A full toolbox clears away.\n'
                '4) Remove every screw to win the level!\n'
                'Pinch to zoom, double-tap to reset the view.',
        lang,
      );
    }
    if (has(['tip', 'tips', 'hint', 'hints', 'trick', 'ඉඟි', 'උපදෙස්', 'උදව්', 'help', 'hint එකක්'])) {
      return BotReply(
        si
            ? '💡 ඉඟි:\n• මුලින්ම උඩම plates වල screws ගලවන්න.\n• Waiting tray එක පිරෙන්න දෙන්න එපා.\n• Zoom කර හොඳින් බලලා move කරන්න.'
            : '💡 Tips:\n• Clear screws on the top plates first.\n• Never let the waiting tray fill up.\n• Zoom in and plan before you move.',
        lang,
      );
    }

    // --- About game ------------------------------------------------------
    if (has(['about', 'game', 'ගැන', 'ගේම්', 'ක්‍රීඩාව', 'screw jam', 'mathra screw'])) {
      return BotReply(
        si
            ? '${Brand.appName} යනු screws ගලවා පාට ගැලපෙන විනෝදජනක puzzle ක්‍රීඩාවක් 🔩 '
                'Mathra Quotes TikTok අයිතිකරු ${Brand.ownerSi} විසින් සකස් කරන ලදී.'
            : '${Brand.appName} is a fun puzzle game where you unscrew plates and match colours 🔩 '
                'Made by ${Brand.owner} of Mathra Quotes on TikTok.',
        lang,
        const [_tiktok],
      );
    }

    // --- Joke ------------------------------------------------------------
    if (has(['joke', 'funny', 'laugh', 'විහිළු', 'විහිලු', 'හිනා', 'කතාවක්'])) {
      return BotReply(
        si
            ? pick([
                'Screw එකක් තව screw එකකට කිව්වා: "ඔයා නිසා මට හරිම ටයිට් වෙලා!" 🔩😄',
                'ඇයි screw එක තරඟය දිනුවේ? මොකද එයා හැමදේම හරවන්න දන්නවා! 🔄😂',
              ])
            : pick([
                'Why did the screw win the race? It always knew how to turn things around! 🔩😂',
                'I told a screw a joke. It was a bit too tight to laugh 😄',
              ]),
        lang,
      );
    }

    // --- Time ------------------------------------------------------------
    if (has(['time', 'date', 'today', 'වෙලාව', 'වේලාව', 'දිනය', 'අද දිනය', 'අද මොන'])) {
      final n = DateTime.now();
      String two(int v) => v.toString().padLeft(2, '0');
      final stamp = '${n.year}-${two(n.month)}-${two(n.day)}  ${two(n.hour)}:${two(n.minute)}';
      return BotReply(si ? 'දැන් වෙලාව: $stamp ⏰' : 'Right now it is $stamp ⏰', lang);
    }

    // --- Thanks / bye / greetings ---------------------------------------
    if (has(['thanks', 'thank', 'thx', 'ස්තූති', 'ස්තුති', 'තැන්ක්ස්', 'ගොඩක් පිං', 'sthuthi'])) {
      return BotReply(
        si ? pick(['කමක් නෑ! 😊 තව මොනවා හරි අහන්න.', 'ඕනෑම වෙලාවක! 💛']) : pick(["You're welcome! 😊", 'Anytime! 💛']),
        lang,
      );
    }
    if (has(['bye', 'goodbye', 'see you', 'good night', 'ගිහින් එන්නම්', 'සුභ රාත්‍රියක්', 'ආයෙ හම්බෙමු'])) {
      return BotReply(
        si ? 'ආයෙත් හම්බෙමු! 👋 සුභ දවසක්!' : 'See you soon! 👋 Have a great day!',
        lang,
      );
    }
    if (has(['how are you', 'kohomada', 'kohomada?', 'කොහොමද', 'කොහෙමද', 'සනීපෙන්ද', 'සනීපද'])) {
      return BotReply(
        si ? 'මම හොඳින්! 😄 ඔයා කොහොමද? මොනවා හරි උදව්වක් ඕනද?' : "I'm doing great! 😄 How about you?",
        lang,
      );
    }
    if (has(['hi', 'hello', 'hey', 'hola', 'yo', 'හායි', 'හලෝ', 'ආයුබෝවන්', 'හෙලෝ', 'සුභ උදෑසනක්', 'හෙලෝ'])) {
      return BotReply(
        si
            ? pick([
                'ආයුබෝවන්! 👋 මම Mathra AI Chat Bot. අද ඔයාට කොහොමද උදව් කරන්නේ?',
                'හායි! 😄 ක්‍රීඩාව ගැන හෝ මාව හැදුවේ කවුද කියලා අහන්න!',
              ])
            : pick([
                "Hey there! 👋 I'm Mathra AI Chat Bot. How can I help?",
                'Hello! 😄 Ask me about the game or who made me!',
              ]),
        lang,
      );
    }

    // --- Fallback --------------------------------------------------------
    return BotReply(
      si
          ? 'ඒක මට හරියටම තේරුණේ නෑ 🤔 මෙහෙම අහලා බලන්න:\n• ඔයාව හැදුවේ කවුද?\n• කොහොමද ක්‍රීඩා කරන්නේ?\n• කොන්ටැක්ට් කරගන්න කොහොමද?'
          : "I didn't quite get that 🤔 Try asking:\n• Who made you?\n• How to play?\n• How can I contact the creator?",
      lang,
    );
  }

  // ---------------------------------------------------------------------
  // Tiny calculator so the bot can do "Mathra Math" 🧮
  // ---------------------------------------------------------------------
  static String? _tryMath(String s) {
    final t = s
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAllMapped(RegExp(r'(?<=\d)\s*x\s*(?=\d)'), (_) => '*')
        .replaceAll('=', '')
        .replaceAll('?', '')
        .trim();
    if (!RegExp(r'^[0-9+\-*/().%\s]+$').hasMatch(t)) return null;
    if (!RegExp(r'\d').hasMatch(t) || !RegExp(r'[+\-*/%]').hasMatch(t)) return null;
    try {
      final p = _Parser(t);
      final v = p.parse();
      if (v.isNaN || v.isInfinite) return null;
      return v == v.roundToDouble() && v.abs() < 1e15
          ? v.toInt().toString()
          : v.toStringAsFixed(4).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
    } catch (_) {
      return null;
    }
  }
}

class _Parser {
  final String s;
  int i = 0;
  _Parser(this.s);

  double parse() {
    final v = _expr();
    _ws();
    if (i != s.length) throw const FormatException('bad');
    return v;
  }

  void _ws() {
    while (i < s.length && s[i] == ' ') {
      i++;
    }
  }

  double _expr() {
    var v = _term();
    while (true) {
      _ws();
      if (i < s.length && (s[i] == '+' || s[i] == '-')) {
        final op = s[i++];
        final r = _term();
        v = op == '+' ? v + r : v - r;
      } else {
        return v;
      }
    }
  }

  double _term() {
    var v = _factor();
    while (true) {
      _ws();
      if (i < s.length && (s[i] == '*' || s[i] == '/' || s[i] == '%')) {
        final op = s[i++];
        final r = _factor();
        v = op == '*' ? v * r : (op == '/' ? v / r : v % r);
      } else {
        return v;
      }
    }
  }

  double _factor() {
    _ws();
    if (i < s.length && s[i] == '-') {
      i++;
      return -_factor();
    }
    if (i < s.length && s[i] == '(') {
      i++;
      final v = _expr();
      _ws();
      if (i >= s.length || s[i] != ')') throw const FormatException('paren');
      i++;
      return v;
    }
    final start = i;
    while (i < s.length && RegExp(r'[0-9.]').hasMatch(s[i])) {
      i++;
    }
    if (start == i) throw const FormatException('num');
    return double.parse(s.substring(start, i));
  }
}
