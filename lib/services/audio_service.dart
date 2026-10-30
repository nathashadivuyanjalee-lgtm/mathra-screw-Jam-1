import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

enum Sfx { tap, unscrew, drop, box, fall, win, lose }

class Track {
  final String title;
  final String? asset; // bundled track (path under assets/)
  final String? path; // song picked from the device
  const Track.asset(this.title, String this.asset) : path = null;
  const Track.file(this.title, String this.path) : asset = null;
  Source get source => asset != null ? AssetSource(asset!) : DeviceFileSource(path!);
}

/// Background music player + sound effects. Everything fails silently so a
/// missing codec / file can never crash the game.
class AudioService extends ChangeNotifier {
  AudioService._();
  static final AudioService I = AudioService._();

  static const _boxName = 'audio_prefs';

  final AudioPlayer _music = AudioPlayer();
  final List<AudioPlayer> _sfxPool = [];
  int _sfxIdx = 0;
  Box? _box;

  /// Only songs the player adds themselves.
  /// Default songs bundled with the app (file must exist in assets/songs/).
  static const _defaults = <(String, String)>[
    ('අහසේ ගුගුරා', 'songs/ahase_gugura.mp3'),
  ];

  final List<Track> playlist = [];
  int index = 0;
  bool playing = false;
  bool shuffle = false;
  bool loopOne = false;
  bool sfxEnabled = true;
  bool threeD = true;
  double volume = 0.7;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  final _rng = math.Random();

  Track? get current => playlist.isEmpty ? null : playlist[index.clamp(0, playlist.length - 1)];

  Future<void> init() async {
    try {
      _box = await Hive.openBox(_boxName);
      sfxEnabled = _box!.get('sfx', defaultValue: true);
      threeD = _box!.get('3d', defaultValue: true);
      volume = _box!.get('vol', defaultValue: 0.7);
      shuffle = _box!.get('shuffle', defaultValue: false);
      for (final d in _defaults) {
        try {
          await rootBundle.load('assets/${d.$2}'); // throws if the file is missing
          playlist.add(Track.asset(d.$1, d.$2));
        } catch (_) {}
      }
      final saved = (_box!.get('songs', defaultValue: <dynamic>[]) as List).cast<String>();
      final titles = (_box!.get('titles', defaultValue: <dynamic>[]) as List).cast<String>();
      for (var i = 0; i < saved.length; i++) {
        if (File(saved[i]).existsSync()) {
          playlist.add(Track.file(i < titles.length ? titles[i] : _nameOf(saved[i]), saved[i]));
        }
      }
    } catch (_) {}
    try {
      for (var i = 0; i < 4; i++) {
        final p = AudioPlayer();
        await p.setPlayerMode(PlayerMode.lowLatency);
        await p.setReleaseMode(ReleaseMode.stop);
        _sfxPool.add(p);
      }
      await _music.setVolume(volume);
      _music.onPlayerComplete.listen((_) => _onComplete());
      _music.onPositionChanged.listen((p) {
        position = p;
        notifyListeners();
      });
      _music.onDurationChanged.listen((d) {
        duration = d;
        notifyListeners();
      });
    } catch (_) {}
  }

  String _nameOf(String path) {
    final n = path.split(Platform.pathSeparator).last;
    final dot = n.lastIndexOf('.');
    return dot > 0 ? n.substring(0, dot) : n;
  }

  void _save(String k, Object v) {
    try {
      _box?.put(k, v);
    } catch (_) {}
  }

  Future<void> _onComplete() async {
    if (loopOne) {
      await _playIndex(index);
    } else {
      await next();
    }
  }

  Future<void> _playIndex(int i) async {
    if (playlist.isEmpty) return;
    index = i.clamp(0, playlist.length - 1);
    try {
      await _music.stop();
      await _music.setVolume(volume);
      await _music.play(current!.source);
      playing = true;
    } catch (_) {
      playing = false;
    }
    notifyListeners();
  }

  Future<void> toggle() async {
    if (playlist.isEmpty) {
      final n = await addSongs();
      if (n > 0) await _playIndex(0);
      return;
    }
    try {
      if (playing) {
        await _music.pause();
        playing = false;
        notifyListeners();
      } else if (position > Duration.zero && duration > Duration.zero) {
        await _music.resume();
        playing = true;
        notifyListeners();
      } else {
        await _playIndex(index);
      }
    } catch (_) {}
  }

  Future<void> playAt(int i) => _playIndex(i);

  Future<void> next() async {
    if (playlist.isEmpty) return;
    final i = shuffle && playlist.length > 1
        ? (index + 1 + _rng.nextInt(playlist.length - 1)) % playlist.length
        : (index + 1) % playlist.length;
    await _playIndex(i);
  }

  Future<void> previous() async {
    if (playlist.isEmpty) return;
    await _playIndex((index - 1 + playlist.length) % playlist.length);
  }

  Future<void> seek(Duration d) async {
    try {
      await _music.seek(d);
    } catch (_) {}
  }

  Future<void> setVolume(double v) async {
    volume = v;
    _save('vol', v);
    try {
      await _music.setVolume(v);
    } catch (_) {}
    notifyListeners();
  }

  void toggleShuffle() {
    shuffle = !shuffle;
    _save('shuffle', shuffle);
    notifyListeners();
  }

  void toggleLoop() {
    loopOne = !loopOne;
    notifyListeners();
  }

  void setSfx(bool v) {
    sfxEnabled = v;
    _save('sfx', v);
    notifyListeners();
  }

  void set3D(bool v) {
    threeD = v;
    _save('3d', v);
    notifyListeners();
  }

  /// Let the player add songs from the phone.
  Future<int> addSongs() async {
    try {
      final res = await FilePicker.platform.pickFiles(type: FileType.audio, allowMultiple: true);
      if (res == null) return 0;
      var added = 0;
      final dir = Directory('${(await getApplicationDocumentsDirectory()).path}${Platform.pathSeparator}songs');
      if (!dir.existsSync()) dir.createSync(recursive: true);
      for (final f in res.files) {
        final p = f.path;
        if (p == null) continue;
        final title = _nameOf(p);
        if (playlist.any((t) => t.title == title)) continue; // already in playlist
        // copy into the app folder so the song stays in the playlist permanently
        final ext = p.contains('.') ? p.substring(p.lastIndexOf('.')) : '';
        final dest = '${dir.path}${Platform.pathSeparator}${DateTime.now().microsecondsSinceEpoch}$ext';
        try {
          await File(p).copy(dest);
          playlist.add(Track.file(title, dest));
          added++;
        } catch (_) {}
      }
      _save('songs', [for (final t in playlist) if (t.path != null) t.path!]);
      _save('titles', [for (final t in playlist) if (t.path != null) t.title]);
      notifyListeners();
      return added;
    } catch (_) {
      return 0;
    }
  }

  Future<void> removeAt(int i) async {
    if (i < 0 || i >= playlist.length) return;
    if (playlist[i].asset != null) return; // default songs stay
    final wasCurrent = i == index;
    final removed = playlist.removeAt(i);
    try {
      if (removed.path != null) await File(removed.path!).delete();
    } catch (_) {}
    if (i < index) index--;
    if (playlist.isEmpty) {
      index = 0;
      playing = false;
      position = Duration.zero;
      duration = Duration.zero;
      try {
        await _music.stop();
      } catch (_) {}
    } else if (wasCurrent) {
      index = index.clamp(0, playlist.length - 1);
      if (playing) await _playIndex(index);
    }
    _save('songs', [for (final t in playlist) if (t.path != null) t.path!]);
    _save('titles', [for (final t in playlist) if (t.path != null) t.title]);
    notifyListeners();
  }

  static const _sfxFiles = {
    Sfx.tap: 'audio/sfx_tap.mp3',
    Sfx.unscrew: 'audio/sfx_unscrew.mp3',
    Sfx.drop: 'audio/sfx_drop.mp3',
    Sfx.box: 'audio/sfx_box.mp3',
    Sfx.fall: 'audio/sfx_fall.mp3',
    Sfx.win: 'audio/sfx_win.mp3',
    Sfx.lose: 'audio/sfx_lose.mp3',
  };

  void sfx(Sfx s) {
    if (!sfxEnabled || _sfxPool.isEmpty) return;
    try {
      final p = _sfxPool[_sfxIdx++ % _sfxPool.length];
      p.play(AssetSource(_sfxFiles[s]!), volume: 0.9);
    } catch (_) {}
  }
}
