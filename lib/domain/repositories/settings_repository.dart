import 'package:gallaerial/domain/entities/settings_model.dart';

abstract class SettingsRepository {
  Stream<SettingsModel> get settingsStream;

  Future<SettingsModel> getSettings();
  Future<SettingsModel> editSettings(SettingsModel newSettings);
}