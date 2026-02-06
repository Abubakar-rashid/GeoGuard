import 'package:hive/hive.dart';
import '../models/survival_guide_model.dart';
import '../models/emergency_contact_model.dart';

class LocalStorageService {
  static const String survivalGuidesBox = 'survival_guides';
  static const String emergencyContactsBox = 'emergency_contacts';
  static const String settingsBox = 'settings';
  static const String offlineDataBox = 'offline_data';

  /// Initialize Hive boxes
  Future<void> initialize() async {
    await Hive.openBox(survivalGuidesBox);
    await Hive.openBox(emergencyContactsBox);
    await Hive.openBox(settingsBox);
    await Hive.openBox(offlineDataBox);
  }

  // ============ SURVIVAL GUIDES ============

  Future<void> saveSurvivalGuide(SurvivalGuide guide) async {
    final box = Hive.box(survivalGuidesBox);
    await box.put(guide.id, guide.toJson());
  }

  Future<List<SurvivalGuide>> getSavedSurvivalGuides() async {
    final box = Hive.box(survivalGuidesBox);
    final guides = <SurvivalGuide>[];

    for (final key in box.keys) {
      final data = box.get(key) as Map<dynamic, dynamic>?;
      if (data != null) {
        guides.add(SurvivalGuide.fromJson(Map<String, dynamic>.from(data)));
      }
    }

    return guides;
  }

  Future<void> deleteSurvivalGuide(String id) async {
    final box = Hive.box(survivalGuidesBox);
    await box.delete(id);
  }

  // ============ EMERGENCY CONTACTS ============

  Future<void> saveEmergencyContact(EmergencyContact contact) async {
    final box = Hive.box(emergencyContactsBox);
    await box.put(contact.id, contact.toJson());
  }

  Future<List<EmergencyContact>> getEmergencyContacts() async {
    final box = Hive.box(emergencyContactsBox);
    final contacts = <EmergencyContact>[];

    for (final key in box.keys) {
      final data = box.get(key) as Map<dynamic, dynamic>?;
      if (data != null) {
        contacts.add(EmergencyContact.fromJson(Map<String, dynamic>.from(data)));
      }
    }

    return contacts;
  }

  Future<void> deleteEmergencyContact(String id) async {
    final box = Hive.box(emergencyContactsBox);
    await box.delete(id);
  }

  // ============ SETTINGS ============

  Future<void> saveSetting(String key, dynamic value) async {
    final box = Hive.box(settingsBox);
    await box.put(key, value);
  }

  T? getSetting<T>(String key, {T? defaultValue}) {
    final box = Hive.box(settingsBox);
    return box.get(key, defaultValue: defaultValue) as T?;
  }

  // Common settings
  Future<void> setPushNotificationsEnabled(bool enabled) async {
    await saveSetting('push_notifications', enabled);
  }

  bool getPushNotificationsEnabled() {
    return getSetting<bool>('push_notifications', defaultValue: true) ?? true;
  }

  Future<void> setLocationTrackingEnabled(bool enabled) async {
    await saveSetting('location_tracking', enabled);
  }

  bool getLocationTrackingEnabled() {
    return getSetting<bool>('location_tracking', defaultValue: true) ?? true;
  }

  Future<void> setDarkModeEnabled(bool enabled) async {
    await saveSetting('dark_mode', enabled);
  }

  bool getDarkModeEnabled() {
    return getSetting<bool>('dark_mode', defaultValue: false) ?? false;
  }

  Future<void> setAlertSensitivity(String sensitivity) async {
    await saveSetting('alert_sensitivity', sensitivity);
  }

  String getAlertSensitivity() {
    return getSetting<String>('alert_sensitivity', defaultValue: 'Medium') ?? 'Medium';
  }

  Future<void> setAutoShareLocation(bool enabled) async {
    await saveSetting('auto_share_location', enabled);
  }

  bool getAutoShareLocation() {
    return getSetting<bool>('auto_share_location', defaultValue: true) ?? true;
  }

  // ============ OFFLINE DATA ============

  Future<void> saveOfflineData(String key, dynamic data) async {
    final box = Hive.box(offlineDataBox);
    await box.put(key, data);
  }

  dynamic getOfflineData(String key) {
    final box = Hive.box(offlineDataBox);
    return box.get(key);
  }

  Future<void> clearAllData() async {
    await Hive.box(survivalGuidesBox).clear();
    await Hive.box(emergencyContactsBox).clear();
    await Hive.box(settingsBox).clear();
    await Hive.box(offlineDataBox).clear();
  }
}
