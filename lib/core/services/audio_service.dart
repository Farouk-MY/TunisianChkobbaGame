// lib/core/services/audio_service.dart

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Audio service for game sounds with real audio and haptic feedback
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  // Separate players for SFX and Music
  AudioPlayer? _sfxPlayer;
  AudioPlayer? _musicPlayer;
  
  bool _soundEnabled = true;
  bool _musicEnabled = true;
  bool _vibrationEnabled = true;
  bool _initialized = false;

  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  
  // Alias getters with 'is' prefix for consistency
  bool get isSoundEnabled => _soundEnabled;
  bool get isMusicEnabled => _musicEnabled;
  bool get isVibrationEnabled => _vibrationEnabled;

  Future<void> initialize() async {
    if (_initialized) return;
    
    debugPrint('AudioService: Initializing...');
    
    // Create new players
    _sfxPlayer = AudioPlayer();
    _musicPlayer = AudioPlayer();
    
    // Configure players
    await _sfxPlayer!.setReleaseMode(ReleaseMode.stop);
    await _musicPlayer!.setReleaseMode(ReleaseMode.loop);
    await _musicPlayer!.setVolume(0.3);
    
    _initialized = true;
    debugPrint('AudioService: Initialized successfully');
  }

  void setSoundEnabled(bool value) => _soundEnabled = value;
  
  void setMusicEnabled(bool value) {
    _musicEnabled = value;
    if (!value) {
      _musicPlayer?.stop();
    }
  }
  
  void setVibrationEnabled(bool value) => _vibrationEnabled = value;

  /// Play card deal sound
  Future<void> playCardDeal() async {
    await _playSound('card_deal');
    await _vibrate(HapticFeedback.lightImpact);
  }

  /// Play card place sound
  Future<void> playCardPlace() async {
    await _playSound('card_place');
    await _vibrate(HapticFeedback.mediumImpact);
  }

  /// Play card capture sound
  Future<void> playCardCapture() async {
    await _playSound('card_capture');
    await _vibrate(HapticFeedback.heavyImpact);
  }

  /// Play Chkobba celebration sound
  Future<void> playChkobba() async {
    await _playSound('chkobba');
    await _vibrate(HapticFeedback.heavyImpact);
    await Future.delayed(const Duration(milliseconds: 100));
    await _vibrate(HapticFeedback.heavyImpact);
    await Future.delayed(const Duration(milliseconds: 100));
    await _vibrate(HapticFeedback.mediumImpact);
  }

  /// Play round end sound
  Future<void> playRoundEnd() async {
    await _playSound('round_end');
    await _vibrate(HapticFeedback.mediumImpact);
  }

  /// Play victory sound
  Future<void> playVictory() async {
    await _playSound('victory');
    await _vibrate(HapticFeedback.heavyImpact);
    await Future.delayed(const Duration(milliseconds: 150));
    await _vibrate(HapticFeedback.mediumImpact);
  }

  /// Play defeat sound
  Future<void> playDefeat() async {
    await _playSound('defeat');
    await _vibrate(HapticFeedback.lightImpact);
  }

  /// Play button tap sound
  Future<void> playButtonTap() async {
    await _playSound('button_tap');
    await _vibrate(HapticFeedback.selectionClick);
  }

  /// Play timer warning sound
  Future<void> playTimerWarning() async {
    await _playSound('timer_warning');
    await _vibrate(HapticFeedback.lightImpact);
  }

  /// Start game background music (in game)
  Future<void> startBackgroundMusic() async {
    if (!_musicEnabled) {
      debugPrint('AudioService: Music disabled');
      return;
    }
    
    try {
      debugPrint('AudioService: Starting GAME music...');
      
      // Ensure initialized
      if (_musicPlayer == null) {
        await initialize();
      }
      
      // Stop any current music
      await _musicPlayer!.stop();
      
      // Set source and play
      await _musicPlayer!.setSource(AssetSource('audio/background_music.mp3'));
      await _musicPlayer!.setVolume(0.3);
      await _musicPlayer!.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer!.resume();
      
      debugPrint('AudioService: GAME music started!');
    } catch (e, stack) {
      debugPrint('AudioService: GAME music error - $e');
      debugPrint('Stack: $stack');
    }
  }

  /// Start lobby background music (in home/menu)
  Future<void> startLobbyMusic() async {
    if (!_musicEnabled) {
      debugPrint('AudioService: Music disabled');
      return;
    }
    
    try {
      debugPrint('AudioService: Starting LOBBY music...');
      
      // Ensure initialized
      if (_musicPlayer == null) {
        await initialize();
      }
      
      // Stop any current music
      await _musicPlayer!.stop();
      
      // Set source and play
      await _musicPlayer!.setSource(AssetSource('audio/background_music2.mp3'));
      await _musicPlayer!.setVolume(0.25);
      await _musicPlayer!.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer!.resume();
      
      debugPrint('AudioService: LOBBY music started!');
    } catch (e, stack) {
      debugPrint('AudioService: LOBBY music error - $e');
      debugPrint('Stack: $stack');
    }
  }

  /// Stop background music
  Future<void> stopBackgroundMusic() async {
    await _musicPlayer?.stop();
  }

  /// Pause background music
  Future<void> pauseBackgroundMusic() async {
    await _musicPlayer?.pause();
  }

  /// Resume background music
  Future<void> resumeBackgroundMusic() async {
    if (!_musicEnabled) return;
    await _musicPlayer?.resume();
  }

  Future<void> _playSound(String soundName) async {
    if (!_soundEnabled) return;
    if (_sfxPlayer == null) return;
    
    try {
      await _sfxPlayer!.play(AssetSource('audio/$soundName.mp3'));
    } catch (e) {
      debugPrint('AudioService: SFX error for $soundName - $e');
    }
  }

  Future<void> _vibrate(Future<void> Function() haptic) async {
    if (_vibrationEnabled) {
      try {
        await haptic();
      } catch (_) {}
    }
  }

  void dispose() {
    _sfxPlayer?.dispose();
    _musicPlayer?.dispose();
    _sfxPlayer = null;
    _musicPlayer = null;
    _initialized = false;
  }
}
