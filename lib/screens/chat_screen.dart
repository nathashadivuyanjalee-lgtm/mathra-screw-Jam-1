import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/brand.dart';
import '../providers/game_provider.dart';
import '../services/haptics.dart';
import '../services/links.dart';
import '../services/mathra_bot.dart';
import '../widgets/fx.dart';

class _Msg {
  final bool fromBot;
  final String text;
  final BotLang lang;
  final List<BotLink> links;
  final bool typed;
  const _Msg({
    required this.fromBot,
    required this.text,
    required this.lang,
    this.links = const [],
    this.typed = false,
  });
}

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _tts = FlutterTts();
  final List<_Msg> _msgs = [];
  bool _thinking = false;
  bool _voiceOn = true;
  bool _speaking = false;
  bool _warnedNoSinhala = false;

  static const _chips = <String>[
    'ඔයාව හැදුවේ කවුද?',
    'Who made you?',
    'කොන්ටැක්ට් කරගන්න කොහොමද?',
    'Contact creator',
    'TikTok',
    'GitHub',
    'කොහොමද ක්‍රීඩා කරන්නේ?',
    'Tell me a joke',
  ];

  @override
  void initState() {
    super.initState();
    final w = MathraBot.welcome();
    _msgs.add(_Msg(fromBot: true, text: w.text, lang: w.lang, typed: true));
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.05);
      await _tts.setVolume(1.0);
      _tts.setStartHandler(() {
        if (mounted) setState(() => _speaking = true);
      });
      _tts.setCompletionHandler(() {
        if (mounted) setState(() => _speaking = false);
      });
      _tts.setCancelHandler(() {
        if (mounted) setState(() => _speaking = false);
      });
      _tts.setErrorHandler((_) {
        if (mounted) setState(() => _speaking = false);
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _tts.stop();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String _speechText(String t) {
    // remove emoji / symbols so the voice does not read them out
    return t
        .replaceAll(RegExp(r'[\u{1F000}-\u{1FFFF}\u{2600}-\u{27BF}\u{FE0F}]', unicode: true), '')
        .replaceAll(RegExp(r'[•\n]+'), '. ');
  }

  Future<void> _speak(String text, BotLang lang, {bool force = false}) async {
    if (!_voiceOn && !force) return;
    try {
      final code = lang == BotLang.si ? 'si-LK' : 'en-US';
      final ok = await _tts.isLanguageAvailable(code);
      if (ok == true) {
        await _tts.setLanguage(code);
        await _tts.stop();
        await _tts.speak(_speechText(text));
      } else if (lang == BotLang.si && !_warnedNoSinhala && mounted) {
        _warnedNoSinhala = true;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            duration: Duration(seconds: 6),
            content: Text(
              'ඔබේ දුරකථනයේ සිංහල Text-to-Speech නැත. Settings > Text-to-speech > Google වලින් Sinhala voice එක බාගන්න.\n'
              'No Sinhala voice found. Install it in Settings > Text-to-speech.',
            ),
          ),
        );
      }
    } catch (_) {}
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  void _follow() {
    if (_scroll.hasClients) {
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    }
  }

  Future<void> _send(String raw) async {
    final text = raw.trim();
    if (text.isEmpty || _thinking) return;
    Haptics.light();
    _input.clear();
    setState(() {
      _msgs.add(_Msg(fromBot: false, text: text, lang: MathraBot.isSinhala(text) ? BotLang.si : BotLang.en));
      _thinking = true;
    });
    _scrollDown();
    await Future.delayed(Duration(milliseconds: 650 + (text.length * 8).clamp(0, 600).toInt()));
    if (!mounted) return;
    final r = MathraBot.reply(text, level: ref.read(highestLevelProvider));
    setState(() {
      _thinking = false;
      _msgs.add(_Msg(fromBot: true, text: r.text, lang: r.lang, links: r.links, typed: true));
    });
    _scrollDown();
    _speak(r.text, r.lang);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Brand.navy,
      body: StarfieldBackground(
        child: SafeArea(
          child: Column(
            children: [
              _header(),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                  child: Column(
                    children: [
                      for (var i = 0; i < _msgs.length; i++)
                        _bubble(_msgs[i], isLast: i == _msgs.length - 1),
                      if (_thinking) _typingBubble(),
                    ],
                  ),
                ),
              ),
              _chipsRow(),
              _inputBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 6, 12, 8),
      decoration: BoxDecoration(
        color: Brand.navy.withValues(alpha: 0.7),
        border: Border(bottom: BorderSide(color: Brand.gold.withValues(alpha: 0.25))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          RotatingRing(
            size: 46,
            thickness: 3,
            child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  Brand.botName,
                  style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900),
                ),
                Row(
                  children: [
                    Heartbeat(
                      amount: 0.35,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(color: Brand.green, shape: BoxShape.circle),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _thinking ? 'typing…' : 'Online  •  සිංහල / English',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Pressable(
            onTap: () {
              setState(() => _voiceOn = !_voiceOn);
              if (!_voiceOn) _tts.stop();
            },
            child: Ripples(
              active: _speaking,
              size: 44,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _voiceOn ? Brand.gold.withValues(alpha: 0.2) : Colors.white10,
                  border: Border.all(color: _voiceOn ? Brand.gold : Colors.white24, width: 1.5),
                ),
                child: Icon(
                  _voiceOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                  color: _voiceOn ? Brand.gold : Colors.white54,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatar() {
    return SizedBox(
      width: 32,
      height: 32,
      child: ClipOval(child: Image.asset('assets/images/logo.png', fit: BoxFit.cover)),
    );
  }

  Widget _typingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _avatar(),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: _botDecoration(),
              child: const TypingDots(),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _botDecoration() => BoxDecoration(
        color: Brand.card,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(18),
        ),
        border: Border.all(color: Brand.gold.withValues(alpha: 0.35)),
      );

  Widget _bubble(_Msg m, {required bool isLast}) {
    const style = TextStyle(color: Colors.white, fontSize: 15.5, height: 1.4);
    if (!m.fromBot) {
      return StaggerIn(
        offset: const Offset(0.15, 0.1),
        duration: const Duration(milliseconds: 450),
        child: Align(
          alignment: Alignment.centerRight,
          child: Container(
            margin: const EdgeInsets.only(top: 8, left: 48),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Brand.blue, Color(0xFF3B6BFF)]),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(4),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
            ),
            child: Text(m.text, style: style),
          ),
        ),
      );
    }
    return StaggerIn(
      offset: const Offset(-0.15, 0.1),
      duration: const Duration(milliseconds: 450),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(top: 8, right: 32),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _avatar(),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: _botDecoration(),
                      child: (m.typed && isLast)
                          ? Typewriter(text: m.text, style: style, onTick: _follow)
                          : Text(m.text, style: style),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        for (final l in m.links) _linkButton(l),
                        _smallBtn(Icons.volume_up_rounded, 'Speak', () => _speak(m.text, m.lang, force: true)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _smallBtn(IconData icon, String label, VoidCallback onTap) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: Colors.white70),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _linkButton(BotLink l) {
    return Pressable(
      onTap: () => openUrl(l.url),
      child: ShineSweep(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Brand.orange, Brand.gold]),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(l.icon, size: 17, color: Brand.navy),
              const SizedBox(width: 6),
              Text(l.label, style: const TextStyle(color: Brand.navy, fontWeight: FontWeight.w900, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chipsRow() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        itemCount: _chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => Pressable(
          onTap: () => _send(_chips[i]),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Brand.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Brand.cyan.withValues(alpha: 0.5)),
            ),
            child: Text(
              _chips[i],
              style: const TextStyle(color: Brand.cyan, fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Brand.card,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: Colors.white12),
              ),
              child: TextField(
                controller: _input,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                cursorColor: Brand.gold,
                textInputAction: TextInputAction.send,
                onSubmitted: _send,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'ටයිප් කරන්න / Type a message…',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Pressable(
            onTap: () => _send(_input.text),
            child: GlowPulse(
              circle: true,
              color: Brand.gold,
              maxBlur: 14,
              child: Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Brand.orange, Brand.gold],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(Icons.send_rounded, color: Brand.navy, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
