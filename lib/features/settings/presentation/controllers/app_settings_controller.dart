import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum NotificationSoundOption { defaultTone, silent }

class AppSettingsController extends ChangeNotifier {
  AppSettingsController._({
    required SharedPreferences prefs,
    required ThemeMode themeMode,
    required bool notificationsEnabled,
    required NotificationSoundOption notificationSound,
    required bool autoCompleteOnDue,
    required bool weekStartsOnMonday,
    required bool hasSeenIntro,
  }) : _themeMode = themeMode,
       _notificationsEnabled = notificationsEnabled,
       _notificationSound = notificationSound,
       _autoCompleteOnDue = autoCompleteOnDue,
       _weekStartsOnMonday = weekStartsOnMonday,
       _hasSeenIntro = hasSeenIntro,
       _prefs = prefs;

  static const String _themeModeKey = 'settings.theme_mode';
  static const String _notificationsEnabledKey =
      'settings.notifications.enabled';
  static const String _notificationSoundKey = 'settings.notifications.sound';
  static const String _autoCompleteOnDueKey =
      'settings.tasks.auto_complete_on_due';
  static const String _weekStartsOnMondayKey =
      'settings.tasks.week_starts_on_monday';
  static const String _hasSeenIntroKey = 'settings.app.has_seen_intro';

  final SharedPreferences _prefs;
  ThemeMode _themeMode;
  bool _notificationsEnabled;
  NotificationSoundOption _notificationSound;
  bool _autoCompleteOnDue;
  bool _weekStartsOnMonday;
  bool _hasSeenIntro;

  ThemeMode get themeMode => _themeMode;
  bool get notificationsEnabled => _notificationsEnabled;
  NotificationSoundOption get notificationSound => _notificationSound;
  bool get autoCompleteOnDue => _autoCompleteOnDue;
  bool get weekStartsOnMonday => _weekStartsOnMonday;
  bool get hasSeenIntro => _hasSeenIntro;

  static Future<AppSettingsController> load() async {
    final prefs = await SharedPreferences.getInstance();

    final rawTheme = prefs.getString(_themeModeKey) ?? ThemeMode.system.name;
    final rawSound =
        prefs.getString(_notificationSoundKey) ??
        NotificationSoundOption.defaultTone.name;

    return AppSettingsController._(
      prefs: prefs,
      themeMode: _themeModeFrom(rawTheme),
      notificationsEnabled: prefs.getBool(_notificationsEnabledKey) ?? true,
      notificationSound: _soundFrom(rawSound),
      autoCompleteOnDue: prefs.getBool(_autoCompleteOnDueKey) ?? true,
      weekStartsOnMonday: prefs.getBool(_weekStartsOnMondayKey) ?? true,
      hasSeenIntro: prefs.getBool(_hasSeenIntroKey) ?? false,
    );
  }

  Future<void> setThemeMode(ThemeMode value) async {
    if (_themeMode == value) {
      return;
    }
    _themeMode = value;
    await _prefs.setString(_themeModeKey, value.name);
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    if (_notificationsEnabled == value) {
      return;
    }
    _notificationsEnabled = value;
    await _prefs.setBool(_notificationsEnabledKey, value);
    notifyListeners();
  }

  Future<void> setNotificationSound(NotificationSoundOption value) async {
    if (_notificationSound == value) {
      return;
    }
    _notificationSound = value;
    await _prefs.setString(_notificationSoundKey, value.name);
    notifyListeners();
  }

  Future<void> setAutoCompleteOnDue(bool value) async {
    if (_autoCompleteOnDue == value) {
      return;
    }
    _autoCompleteOnDue = value;
    await _prefs.setBool(_autoCompleteOnDueKey, value);
    notifyListeners();
  }

  Future<void> setWeekStartsOnMonday(bool value) async {
    if (_weekStartsOnMonday == value) {
      return;
    }
    _weekStartsOnMonday = value;
    await _prefs.setBool(_weekStartsOnMondayKey, value);
    notifyListeners();
  }

  Future<void> markIntroSeen() async {
    if (_hasSeenIntro) {
      return;
    }
    _hasSeenIntro = true;
    await _prefs.setBool(_hasSeenIntroKey, true);
    notifyListeners();
  }

  String get notificationSoundLabel {
    switch (_notificationSound) {
      case NotificationSoundOption.defaultTone:
        return 'Default';
      case NotificationSoundOption.silent:
        return 'Silent';
    }
  }

  static ThemeMode _themeModeFrom(String raw) {
    for (final mode in ThemeMode.values) {
      if (mode.name == raw) {
        return mode;
      }
    }
    return ThemeMode.system;
  }

  static NotificationSoundOption _soundFrom(String raw) {
    for (final sound in NotificationSoundOption.values) {
      if (sound.name == raw) {
        return sound;
      }
    }
    return NotificationSoundOption.defaultTone;
  }
}
