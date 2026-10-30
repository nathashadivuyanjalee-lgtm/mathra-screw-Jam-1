import 'package:flutter/material.dart';
import '../models/brand.dart';
import '../services/audio_service.dart';
import 'fx.dart';

/// Round music button with live equalizer. Opens the player sheet.
class MusicButton extends StatelessWidget {
  final double size;
  const MusicButton({super.key, this.size = 42});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: () => showMusicSheet(context),
      child: AnimatedBuilder(
        animation: AudioService.I,
        builder: (_, __) {
          final on = AudioService.I.playing;
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Brand.purple, Brand.pink],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(color: Brand.pink.withValues(alpha: on ? 0.6 : 0.3), blurRadius: on ? 14 : 6, offset: const Offset(0, 3)),
              ],
            ),
            child: Center(
              child: on
                  ? EqualizerBars(active: true, color: Colors.white, height: size * 0.45)
                  : Icon(Icons.music_note_rounded, color: Colors.white, size: size * 0.55),
            ),
          );
        },
      ),
    );
  }
}

void showMusicSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _MusicSheet(),
  );
}

String _fmt(Duration d) {
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$m:$s';
}

class _MusicSheet extends StatelessWidget {
  const _MusicSheet();

  @override
  Widget build(BuildContext context) {
    final a = AudioService.I;
    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Brand.navy2, Brand.navy],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: Brand.gold.withValues(alpha: 0.35)),
        ),
        child: AnimatedBuilder(
          animation: a,
          builder: (context, _) {
            final maxMs = a.duration.inMilliseconds <= 0 ? 1 : a.duration.inMilliseconds;
            final posMs = a.position.inMilliseconds.clamp(0, maxMs).toDouble();
            return ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 30),
              children: [
                Center(
                  child: Container(width: 44, height: 5, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(3))),
                ),
                const SizedBox(height: 14),
                Center(child: Vinyl3D(spinning: a.playing, size: 170)),
                const SizedBox(height: 22),
                Center(
                  child: Text(
                    a.current?.title ?? 'ඔබේ සිංදු එකතු කරන්න 🎵',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(height: 4),
                Center(child: EqualizerBars(active: a.playing, height: 24)),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Brand.gold,
                    inactiveTrackColor: Colors.white12,
                    thumbColor: Brand.gold,
                    trackHeight: 4,
                  ),
                  child: Slider(
                    min: 0,
                    max: maxMs.toDouble(),
                    value: posMs,
                    onChanged: (v) => a.seek(Duration(milliseconds: v.toInt())),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_fmt(a.position), style: const TextStyle(color: Colors.white60, fontSize: 12)),
                      Text(_fmt(a.duration), style: const TextStyle(color: Colors.white60, fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _toggle(Icons.shuffle_rounded, a.shuffle, a.toggleShuffle),
                    _ctl(Icons.skip_previous_rounded, 38, a.previous),
                    Pressable(
                      onTap: a.toggle,
                      child: GlowPulse(
                        circle: true,
                        color: Brand.gold,
                        maxBlur: 16,
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(colors: [Brand.orange, Brand.gold], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          ),
                          child: Icon(a.playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Brand.navy, size: 42),
                        ),
                      ),
                    ),
                    _ctl(Icons.skip_next_rounded, 38, a.next),
                    _toggle(Icons.repeat_one_rounded, a.loopOne, a.toggleLoop),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(Icons.volume_down_rounded, color: Colors.white60),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: Brand.cyan,
                          inactiveTrackColor: Colors.white12,
                          thumbColor: Brand.cyan,
                          trackHeight: 3,
                        ),
                        child: Slider(value: a.volume, onChanged: a.setVolume),
                      ),
                    ),
                    const Icon(Icons.volume_up_rounded, color: Colors.white60),
                  ],
                ),
                _switchRow(Icons.graphic_eq_rounded, 'Sound effects / ශබ්ද Effects', a.sfxEnabled, a.setSfx),
                _switchRow(Icons.view_in_ar_rounded, '3D Game mode / 3D ක්‍රීඩාව', a.threeD, a.set3D),
                const SizedBox(height: 10),
                Pressable(
                  onTap: () async {
                    final n = await a.addSongs();
                    if (n > 0 && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('සිංදු $n ක් එකතු වුණා / $n song(s) added 🎵')),
                      );
                    }
                  },
                  child: ShineSweep(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Brand.purple, Brand.pink]),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.library_add_rounded, color: Colors.white),
                          SizedBox(width: 8),
                          Text('ඔබේ සිංදු එකතු කරන්න / Add songs', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Playlist  (${a.playlist.length})',
                  style: const TextStyle(color: Brand.gold, fontSize: 16, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                if (a.playlist.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Brand.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: const Text(
                      'Playlist එක හිස්. උඩ ඇති "Add songs" බටන් එකෙන් phone එකේ සිංදු එකතු කරන්න.\nYour playlist is empty. Tap "Add songs" to add music from your phone.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, height: 1.5),
                    ),
                  ),
                for (var i = 0; i < a.playlist.length; i++)
                  StaggerIn(
                    key: ValueKey('${a.playlist[i].path}'),
                    offset: const Offset(0, -0.6),
                    duration: const Duration(milliseconds: 550),
                    child: _trackTile(a, i),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _ctl(IconData icon, double size, VoidCallback onTap) => Pressable(
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(8), child: Icon(icon, color: Colors.white, size: size)),
      );

  Widget _toggle(IconData icon, bool on, VoidCallback onTap) => Pressable(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: on ? Brand.gold : Colors.white38, size: 26),
        ),
      );

  Widget _switchRow(IconData icon, String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      activeColor: Brand.gold,
      secondary: Icon(icon, color: Brand.cyan),
      title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _trackTile(AudioService a, int i) {
    final t = a.playlist[i];
    final cur = i == a.index;
    return Pressable(
      onTap: () => a.playAt(i),
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: cur ? Brand.gold.withValues(alpha: 0.15) : Brand.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cur ? Brand.gold : Colors.white12),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: cur ? EqualizerBars(active: a.playing, height: 18, color: Brand.gold) : const Icon(Icons.music_note_rounded, color: Colors.white38, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
            if (t.path != null)
            GestureDetector(
              onTap: () => a.removeAt(i),
              child: const Icon(Icons.close_rounded, color: Colors.white38, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
