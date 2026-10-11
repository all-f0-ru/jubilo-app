import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_segment.dart';
import '../theme/app_text_styles.dart';

/// Maneja las preferencias de accesibilidad de Jubilo (tamaño de letra,
/// alto contraste, lectura en voz alta) y, desde la reestructuración a
/// navegación por pestañas, también la personalización del usuario
/// (sexo/edad) — así el segmento se calcula una sola vez y persiste al
/// cambiar entre pestañas (Inicio/Aprender/Modalidades/Simular), en vez
/// de perderse cada vez que se vuelve a entrar a "Aprender".
class SettingsProvider extends ChangeNotifier {
  static const _kFontScaleKey = 'font_scale_level';
  static const _kHighContrastKey = 'high_contrast';
  static const _kVoiceKey = 'voice_enabled';
  static const _kSexoKey = 'personalizacion_sexo';
  static const _kEdadKey = 'personalizacion_edad';

  FontScaleLevel _fontScale = FontScaleLevel.normal;
  bool _highContrast = false;
  bool _voiceEnabled = true;
  String? _sexo;
  int? _edad;

  FontScaleLevel get fontScale => _fontScale;
  bool get highContrast => _highContrast;
  bool get voiceEnabled => _voiceEnabled;
  String? get sexo => _sexo;
  int? get edad => _edad;

  /// true una vez que la persona respondió sexo y edad.
  bool get tienePersonalizacion => _sexo != null && _edad != null;

  /// Segmento calculado a partir de la personalización, o null si todavía
  /// no se ha respondido sexo/edad.
  UserSegmentInfo? get segmentInfo {
    if (_sexo == null || _edad == null) return null;
    return computeSegment(sexo: _sexo!, edad: _edad!);
  }

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
    _sexo = prefs.getString(_kSexoKey);
    _edad = prefs.getInt(_kEdadKey);
    notifyListeners();
  }

  Future<void> setPersonalizacion({required String sexo, required int edad}) async {
    _sexo = sexo;
    _edad = edad;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSexoKey, sexo);
    await prefs.setInt(_kEdadKey, edad);
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
