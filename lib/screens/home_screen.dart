import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/brand.dart';
import '../models/game_models.dart';
import '../providers/game_provider.dart';
import '../providers/theme_provider.dart';
import '../services/links.dart';
import '../widgets/fx.dart';
import '../widgets/music_sheet.dart';
import 'about_screen.dart';
import 'chat_screen.dart';
import 'game_screen.dart';
import 'levels_screen.dart';
import 'settings_screen.dart';

/// Mathra dashboard – the home of the app.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
                .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final highestLevel = ref.watch(highestLevelProvider);
    final appTheme = ref.watch(themeProvider);
    final nextMilestone = ((highestLevel ~/ 10) + 1) * 10;
    final progress = (highestLevel % 10) * 10;

    return Scaffold(
      backgroundColor: Brand.navy,
      body: StarfieldBackground(
        colors: appTheme.background.computeLuminance() < 0.3
            ? [
                Color.lerp(appTheme.background, Colors.white, 0.1)!,
                appTheme.background,
                Color.lerp(appTheme.background, Colors.black, 0.6)!,
              ]
            : null,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 6, 22, 26),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: MusicButton(size: 40),
                  ),
                  const Spacer(),
                  Pressable(
                    onTap: openGithub,
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Wiggle(child: Icon(Icons.star_rounded, color: Brand.gold, size: 30)),
                    ),
                  ),
                  Pressable(
                    onTap: openTikTok,
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Heartbeat(child: Icon(Icons.favorite_rounded, color: Brand.pink, size: 28)),
                    ),
                  ),
                ],
              ),
              Center(
                child: StaggerIn(
                  curve: Curves.elasticOut,
                  duration: const Duration(milliseconds: 1100),
                  child: FloatY(
                    child: Spin3D(
                     child: GlowPulse(
                      circle: true,
                      color: Brand.gold,
                      maxBlur: 34,
                      child: RotatingRing(
                        size: 188,
                        thickness: 5,
                        child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
                      ),
                    ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              ShimmerText(
                'MATHRA SCREW JAM',
                style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: 1.5),
              ),
              const SizedBox(height: 6),
              Center(
                child: Typewriter(
                  text: 'ඇණ ගලවන්න  •  ගැලපෙන්න  •  ජය ගන්න',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(child: _stat('LEVEL', highestLevel, Brand.gold, 0)),
                  const SizedBox(width: 10),
                  Expanded(child: _stat('NEXT GOAL', nextMilestone, Brand.cyan, 120)),
                  const SizedBox(width: 10),
                  Expanded(child: _stat('PROGRESS %', progress, Brand.green, 240)),
                ],
              ),
              const SizedBox(height: 20),
              StaggerIn(
                delay: const Duration(milliseconds: 350),
                child: Pressable(
                  onTap: () {
                    ref.read(gameProvider.notifier).startLevel(highestLevel);
                    _push(context, const GameScreen());
                  },
                  child: GlowPulse(
                    color: Brand.green,
                    borderRadius: BorderRadius.circular(22),
                    child: ShineSweep(
                      borderRadius: BorderRadius.circular(22),
                      child: Container(
                        height: 74,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF2ED573), Color(0xFF00A86B)]),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 38),
                            const SizedBox(width: 8),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('PLAY NOW', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 2)),
                                Text('Level $highestLevel', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.2,
                children: [
                  _tile('RANDOM', 'අහඹු puzzle', const Icon(Icons.shuffle_rounded, color: Colors.white, size: 34), const [Color(0xFFFF8A00), Color(0xFFFF5E3A)], 480, 0.0,
                      () => _showRandomDifficultyDialog(context, ref, appTheme)),
                  _tile('LEVELS', 'ලෙවල් ලැයිස්තුව', const Icon(Icons.grid_view_rounded, color: Colors.white, size: 34), const [Color(0xFF1EA7FF), Color(0xFF3B6BFF)], 560, 0.2,
                      () => _push(context, const LevelsScreen())),
                  _tile('AI CHAT', 'Mathra Bot 🤖', const Heartbeat(child: Icon(Icons.smart_toy_rounded, color: Colors.white, size: 36)), const [Brand.purple, Brand.pink], 640, 0.4,
                      () => _push(context, const ChatScreen())),
                  _tile('MUSIC', 'සිංදු 🎵', const Icon(Icons.library_music_rounded, color: Colors.white, size: 34), const [Color(0xFFEC4899), Color(0xFF8B5CF6)], 680, 0.5,
                      () => showMusicSheet(context)),
                  _tile('ABOUT', 'අප ගැන', const Wiggle(child: Icon(Icons.info_rounded, color: Colors.white, size: 34)), const [Color(0xFF14B8A6), Color(0xFF0E7490)], 720, 0.6,
                      () => _push(context, const AboutScreen())),
                  _tile('SETTINGS', 'සැකසුම්', const ScrewSpinner(size: 32), const [Color(0xFF64748B), Color(0xFF334155)], 800, 0.8,
                      () => _push(context, const SettingsScreen())),
                  _tile('TIKTOK', 'Follow us', const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 34), const [Color(0xFFFF2D6F), Color(0xFF111111)], 880, 0.1,
                      () => openTikTok()),
                  _tile('GITHUB', 'Source code', const Icon(Icons.code_rounded, color: Colors.white, size: 34), const [Color(0xFF475569), Color(0xFF0F172A)], 960, 0.3,
                      () => openGithub()),
                ],
              ),
              const SizedBox(height: 22),
              Center(
                child: Text(
                  'Made by ${Brand.owner}  •  Mathra Quotes',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(String label, int value, Color color, int delayMs) {
    return StaggerIn(
      delay: Duration(milliseconds: 200 + delayMs),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Brand.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
        ),
        child: Column(
          children: [
            CountUp(value: value, style: TextStyle(color: color, fontSize: 26, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }

  Widget _tile(String title, String sub, Widget icon, List<Color> colors, int delayMs, double phase, VoidCallback onTap) {
    return StaggerIn(
      delay: Duration(milliseconds: delayMs),
      child: Tilt3D(
       child: Pressable(
        onTap: onTap,
        child: Container(
         decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(color: Color.lerp(colors.last, Colors.black, 0.5)!, offset: const Offset(0, 7), blurRadius: 0),
            BoxShadow(color: Colors.black.withValues(alpha: 0.4), offset: const Offset(0, 14), blurRadius: 14),
          ],
         ),
         child: ShineSweep(
          phase: phase,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 40, child: Center(child: icon)),
                const SizedBox(height: 8),
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                const SizedBox(height: 2),
                Text(sub, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11.5, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
         ),
        ),
       ),
      ),
    );
  }

  void _showRandomDifficultyDialog(BuildContext context, WidgetRef ref, dynamic appTheme) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: appTheme.dialogBg,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'RANDOM PUZZLE',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: appTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Select puzzle difficulty',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: appTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 20),
                ...PuzzleDifficulty.values.map((diff) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: GestureDetector(
                      onTap: () {
                        ref.read(gameProvider.notifier).startRandomPuzzle(diff);
                        Navigator.of(ctx).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const GameScreen(),
                          ),
                        );
                      },
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: diff.color,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: diff.darkColor, width: 2.0),
                          boxShadow: [
                            BoxShadow(
                              color: diff.darkColor,
                              offset: const Offset(0, 4),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            diff.label.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(
                    'CANCEL',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: appTheme.textMuted,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
