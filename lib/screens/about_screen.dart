import 'package:flutter/material.dart';
import '../models/brand.dart';
import '../services/links.dart';
import '../widgets/fx.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  bool _si = true;

  static const _siAbout =
      'Mathra Screw Jam යනු screws ගලවා, පාට ගැලපෙන toolbox වලට දමා, සංකීර්ණ plates ඉවත් කරන '
      'විනෝදජනක puzzle ක්‍රීඩාවකි. දැන් Mathra AI Chat Bot සමඟ සිංහල සහ English වලින් කතා කරන්නත් පුළුවන්!';
  static const _enAbout =
      'Mathra Screw Jam is a fun puzzle game where you unscrew plates, match colours with toolboxes '
      'and clear complex mechanisms. Now you can also chat with Mathra AI Chat Bot in Sinhala and English!';

  static const _siCreator =
      'මෙය නිර්මාණය කළේ Mathra Quotes TikTok අයිතිකරු ${Brand.ownerSi} (${Brand.owner}).';
  static const _enCreator =
      'Created by ${Brand.owner}, the owner of Mathra Quotes on TikTok.';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Brand.navy,
      body: StarfieldBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 12, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                    _langToggle(),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
                  children: [
                    Center(
                      child: FloatY(
                        child: GlowPulse(
                          circle: true,
                          color: Brand.gold,
                          maxBlur: 30,
                          child: RotatingRing(
                            size: 160,
                            child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    ShimmerText(
                      'ABOUT',
                      style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: 3),
                    ),
                    const SizedBox(height: 14),
                    StaggerIn(
                      delay: const Duration(milliseconds: 150),
                      child: _card(
                        icon: const ScrewSpinner(size: 26),
                        title: Brand.appName,
                        body: _si ? _siAbout : _enAbout,
                      ),
                    ),
                    const SizedBox(height: 14),
                    StaggerIn(
                      delay: const Duration(milliseconds: 300),
                      child: _card(
                        icon: Heartbeat(child: const Icon(Icons.favorite_rounded, color: Brand.pink, size: 26)),
                        title: Brand.owner,
                        body: _si ? _siCreator : _enCreator,
                      ),
                    ),
                    const SizedBox(height: 14),
                    StaggerIn(
                      delay: const Duration(milliseconds: 450),
                      child: _card(
                        icon: Wiggle(child: const Icon(Icons.call_rounded, color: Brand.green, size: 26)),
                        title: _si ? 'සම්බන්ධ කරගන්න' : 'Contact',
                        body: Brand.phone,
                      ),
                    ),
                    const SizedBox(height: 22),
                    StaggerIn(
                      delay: const Duration(milliseconds: 600),
                      child: _action('TikTok', Icons.music_note_rounded, const [Brand.pink, Brand.purple], openTikTok, 0.0),
                    ),
                    const SizedBox(height: 12),
                    StaggerIn(
                      delay: const Duration(milliseconds: 720),
                      child: _action('GitHub', Icons.code_rounded, const [Color(0xFF334155), Color(0xFF0F172A)], openGithub, 0.25),
                    ),
                    const SizedBox(height: 12),
                    StaggerIn(
                      delay: const Duration(milliseconds: 840),
                      child: Row(
                        children: [
                          Expanded(child: _action('Call', Icons.call_rounded, const [Brand.green, Color(0xFF0E9F6E)], callCreator, 0.5)),
                          const SizedBox(width: 12),
                          Expanded(child: _action('WhatsApp', Icons.chat_rounded, const [Color(0xFF25D366), Color(0xFF128C7E)], whatsappCreator, 0.75)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 26),
                    Center(
                      child: Text(
                        'Made with 💛 by ${Brand.owner}\nBased on the open-source ScrewJam (GPL-3.0)',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12, height: 1.5),
                      ),
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

  Widget _langToggle() {
    Widget item(String label, bool selected, VoidCallback onTap) => Pressable(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: selected ? Brand.gold : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Brand.navy : Colors.white70,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ),
        );
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Brand.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          item('සිංහල', _si, () => setState(() => _si = true)),
          item('English', !_si, () => setState(() => _si = false)),
        ],
      ),
    );
  }

  Widget _card({required Widget icon, required String title, required String body}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Brand.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Brand.gold.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 30, height: 30, child: Center(child: icon)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Brand.gold, fontSize: 17, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  child: Text(
                    body,
                    key: ValueKey(body),
                    style: const TextStyle(color: Colors.white, fontSize: 14.5, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _action(String label, IconData icon, List<Color> colors, Future<bool> Function() onTap, double phase) {
    return Pressable(
      onTap: () => onTap(),
      child: ShineSweep(
        phase: phase,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1)),
            ],
          ),
        ),
      ),
    );
  }
}
