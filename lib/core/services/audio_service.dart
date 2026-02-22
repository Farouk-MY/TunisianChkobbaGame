// lib/core/services/audio_service.dart

import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ═══════════════════════════════════════════════════════════════════════
///  AUDIO ENGINE — clean, simple, reliable
/// ═══════════════════════════════════════════════════════════════════════
///
/// One music player, one SFX player. SFX has a minimum-interval guard
/// so rapid-fire calls (e.g. card dealing) don't overlap.
///
/// Music lifecycle:
///   Lobby → background_music2.mp3  |  Game → background_music.mp3
class AudioService {
  // ── Singleton ──────────────────────────────────────────────────────
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  // ── Players ────────────────────────────────────────────────────────
  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();

  // ── State ──────────────────────────────────────────────────────────
  bool _soundEnabled = true;
  bool _musicEnabled = true;
  bool _vibrationEnabled = true;
  double _musicVolume = 0.55;
  double _sfxVolume = 0.80;
  bool _initialized = false;

  String? _currentMusicContext;     // 'lobby' | 'game'
  String? _currentlyPlayingAsset;

  // SFX throttle — prevent overlapping rapid-fire sounds
  DateTime _lastSfxTime = DateTime(2000);
  static const int _sfxMinIntervalMs = 180;

  // Prefs keys
  static const _keySoundEnabled = 'audio_sound_enabled';
  static const _keyMusicEnabled = 'audio_music_enabled';
  static const _keyVibrationEnabled = 'audio_vibration_enabled';
  static const _keyMusicVolume = 'audio_music_volume';
  static const _keySfxVolume = 'audio_sfx_volume';

  // ── Getters ────────────────────────────────────────────────────────
  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  bool get isSoundEnabled => _soundEnabled;
  bool get isMusicEnabled => _musicEnabled;
  bool get isVibrationEnabled => _vibrationEnabled;
  double get musicVolume => _musicVolume;
  double get sfxVolume => _sfxVolume;

  // ═════════════════════════════════════════════════════════════════════
  //  INITIALIZATION
  // ═════════════════════════════════════════════════════════════════════

  Future<void> initialize() async {
    if (_initialized) return;
    debugPrint('[Audio] Initializing...');

    await _loadSettings();

    // SFX player: no audio focus, no loop
    await _sfxPlayer.setReleaseMode(ReleaseMode.stop);
    try {
      await _sfxPlayer.setAudioContext(AudioContext(
        android: AudioContextAndroid(
          isSpeakerphoneOn: false,
          audioFocus: AndroidAudioFocus.none,
          usageType: AndroidUsageType.game,
          contentType: AndroidContentType.sonification,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {AVAudioSessionOptions.mixWithOthers},
        ),
      ));
    } catch (_) {}

    // Music player: full focus, full quality
    try {
      await _musicPlayer.setAudioContext(AudioContext(
        android: AudioContextAndroid(
          isSpeakerphoneOn: false,
          audioFocus: AndroidAudioFocus.gain,
          usageType: AndroidUsageType.media,
          contentType: AndroidContentType.music,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {AVAudioSessionOptions.mixWithOthers},
        ),
      ));
    } catch (_) {}

    _initialized = true;
    debugPrint('[Audio] Ready ✓');
  }

  // ── Persistence ────────────────────────────────────────────────────

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _soundEnabled = prefs.getBool(_keySoundEnabled) ?? true;
      _musicEnabled = prefs.getBool(_keyMusicEnabled) ?? true;
      _vibrationEnabled = prefs.getBool(_keyVibrationEnabled) ?? true;
      _musicVolume = prefs.getDouble(_keyMusicVolume) ?? 0.55;
      _sfxVolume = prefs.getDouble(_keySfxVolume) ?? 0.80;
    } catch (_) {}
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keySoundEnabled, _soundEnabled);
      await prefs.setBool(_keyMusicEnabled, _musicEnabled);
      await prefs.setBool(_keyVibrationEnabled, _vibrationEnabled);
      await prefs.setDouble(_keyMusicVolume, _musicVolume);
      await prefs.setDouble(_keySfxVolume, _sfxVolume);
    } catch (_) {}
  }

  // ── Settings ───────────────────────────────────────────────────────

  void setSoundEnabled(bool value) {
    _soundEnabled = value;
    _saveSettings();
  }

  void setMusicEnabled(bool value) {
    _musicEnabled = value;
    _saveSettings();
    if (!value) {
      stopMusic();
    } else {
      if (_currentMusicContext == 'lobby') startLobbyMusic();
      if (_currentMusicContext == 'game') startGameMusic();
    }
  }

  void setVibrationEnabled(bool value) {
    _vibrationEnabled = value;
    _saveSettings();
  }

  void setMusicVolume(double value) {
    _musicVolume = value.clamp(0.0, 1.0);
    _musicPlayer.setVolume(_musicVolume);
    _saveSettings();
  }

  void setSfxVolume(double value) {
    _sfxVolume = value.clamp(0.0, 1.0);
    _saveSettings();
  }

  // ═════════════════════════════════════════════════════════════════════
  //  MUSIC
  // ═════════════════════════════════════════════════════════════════════

  Future<void> startLobbyMusic() async {
    _currentMusicContext = 'lobby';
    await _playMusic('audio/background_music2.mp3');
  }

  Future<void> startGameMusic() async {
    _currentMusicContext = 'game';
    await _playMusic('audio/background_music.mp3');
  }

  Future<void> startBackgroundMusic() => startGameMusic();

  Future<void> stopMusic() async {
    try {
      await _musicPlayer.stop();
      _currentlyPlayingAsset = null;
    } catch (_) {}
  }

  Future<void> stopBackgroundMusic() => stopMusic();
  Future<void> pauseBackgroundMusic() => _musicPlayer.pause();
  Future<void> resumeBackgroundMusic() async {
    if (!_musicEnabled) return;
    await _musicPlayer.resume();
  }

  Future<void> _playMusic(String assetPath) async {
    if (!_musicEnabled) return;
    if (_currentlyPlayingAsset == assetPath) return;

    try {
      await _musicPlayer.stop();
      _currentlyPlayingAsset = null;
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.setVolume(_musicVolume);
      await _musicPlayer.play(AssetSource(assetPath));
      _currentlyPlayingAsset = assetPath;
      debugPrint('[Audio] Music → $assetPath ✓');
    } catch (e) {
      debugPrint('[Audio] Music error: $e');
    }
  }

  // ═════════════════════════════════════════════════════════════════════
  //  SOUND EFFECTS
  // ═════════════════════════════════════════════════════════════════════

  Future<void> playCardDeal() async {
    await _playSfx('card_deal');
    await _vibrate(HapticFeedback.lightImpact);
  }

  Future<void> playCardPlace() async {
    await _playSfx('card_place');
    await _vibrate(HapticFeedback.mediumImpact);
  }

  Future<void> playCardCapture() async {
    await _playSfx('card_capture');
    await _vibrate(HapticFeedback.heavyImpact);
  }

  /// Play the "CHKOBBA!" celebration sound.
  /// Bypasses throttle — this is a special celebration, must always play.
  /// TODO (online mode): use male/female voice variant based on player gender.
  Future<void> playChkobba() async {
    if (!_soundEnabled) return;
    // Reset throttle so this always plays
    _lastSfxTime = DateTime(2000);
    await _playSfx('chkkoba');
    await _vibrate(HapticFeedback.heavyImpact);
    await Future.delayed(const Duration(milliseconds: 100));
    await _vibrate(HapticFeedback.heavyImpact);
  }

  Future<void> playRoundEnd() async {
    await _playSfx('card_capture');
    await _vibrate(HapticFeedback.mediumImpact);
  }

  Future<void> playVictory() async {
    await _playSfx('victory');
    await _vibrate(HapticFeedback.heavyImpact);
  }

  Future<void> playDefeat() async {
    await _playSfx('defeat');
    await _vibrate(HapticFeedback.lightImpact);
  }

  Future<void> playButtonTap() async {
    await _playSfx('button_tap');
    await _vibrate(HapticFeedback.selectionClick);
  }

  Future<void> playTimerWarning() async {
    await _playSfx('button_tap');
    await _vibrate(HapticFeedback.lightImpact);
  }

  /// Play SFX with throttle guard — if called too rapidly,
  /// subsequent calls within [_sfxMinIntervalMs] are skipped.
  /// This prevents overlapping / duplicate sounds during animations.
  Future<void> _playSfx(String name) async {
    if (!_soundEnabled) return;

    // Throttle: skip if too soon after last SFX
    final now = DateTime.now();
    if (now.difference(_lastSfxTime).inMilliseconds < _sfxMinIntervalMs) {
      return;
    }
    _lastSfxTime = now;

    try {
      await _sfxPlayer.setVolume(_sfxVolume);
      await _sfxPlayer.play(AssetSource('audio/$name.mp3'));
    } catch (e) {
      debugPrint('[Audio] SFX error ($name): $e');
    }

    // Fallback: resume music if Android stole focus
    if (_currentlyPlayingAsset != null && _musicEnabled) {
      Future.delayed(const Duration(milliseconds: 100), () async {
        try { await _musicPlayer.resume(); } catch (_) {}
      });
    }
  }

  Future<void> _vibrate(Future<void> Function() haptic) async {
    if (!_vibrationEnabled) return;
    try { await haptic(); } catch (_) {}
  }

  // ── Cleanup ────────────────────────────────────────────────────────
  void dispose() {
    _musicPlayer.dispose();
    _sfxPlayer.dispose();
  }
}
