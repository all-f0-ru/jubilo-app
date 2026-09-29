import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_text_styles.dart';

/// Maneja las preferencias de accesibilidad de Jubilo: tamaño de letra,
/// alto contraste y lectura en voz alta. Persisten entre sesiones usando
/// shared_preferences, tal como se definió en el plan de trabajo.
class SettingsProvider extends ChangeNotifier {
  static const _kFontScaleKey = 'font_scale_level';
  static const _kHighContrastKey = 'high_contrast';
  static const _kVoiceKey = 'voice_enabled';

  FontScaleLevel _fontScale = FontScaleLevel.normal;
  bool _highContrast = false;
  bool _voiceEnabled = true;

  FontScaleLevel get fontScale => _fontScale;
  bool get highContrast => _highContrast;
  bool get voiceEnabled => _voiceEnabled;

  SettingsProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final savedScale = prefs.getInt(_kFontScaleKey);
    if (savedScale != null && savedScale < FontScaleLevel.values.length) {
      _fontScale = FontScaleLevel.values[savedScale];
    }
    _highContrast = prefs.getBool(_kHighContrastKey) ?? false;
    _voiceEnabled = prefs.getBool(_kVoiceKey) ?? true;
    notifyListeners();
  }

  Future<void> setFontScale(FontScaleLevel level) async {
    _fontScale = level;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kFontScaleKey, level.index);
  }

  Future<void> toggleHighContrast(bool value) async {
    _highContrast = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHighContrastKey, value);
  }

  Future<void> toggleVoice(bool value) async {
    _voiceEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kVoiceKey, value);
  }
}
