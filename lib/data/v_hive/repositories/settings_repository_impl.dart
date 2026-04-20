import 'dart:async';

import 'package:gallaerial/data/v_hive/dto/settings_dto.dart';
import 'package:gallaerial/domain/entities/settings_model.dart';
import 'package:gallaerial/domain/repositories/settings_repository.dart';
import 'package:hive/hive.dart';
import 'package:rxdart/subjects.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  Box<SettingsDto> settingsBox = Hive.box('settings');
  final _settingsSubject = BehaviorSubject<SettingsModel>();

  void dispose() {
    _settingsSubject.close();
  }

  Future<void> initData() async {
    if (settingsBox.isEmpty) {
      await editSettings(SettingsModel(showNames: true, expandTags: true));
    }
    else {
      final currentSettings = await getSettings();
      _settingsSubject.add(currentSettings);
    }
  }

  @override
  Stream<SettingsModel> get settingsStream => _settingsSubject.stream;

  @override
  Future<SettingsModel> getSettings() async {
    var settingsDto = settingsBox.values.first;
    var settingsModel = settingsDto.toSettingsModel();
    return settingsModel;
  }

  @override
  Future<SettingsModel> editSettings(SettingsModel newSettings) async {
    settingsBox.clear();
    var settingsDto = SettingsDto.fromSettingsModel(newSettings);
    settingsBox.add(settingsDto);
    _settingsSubject.add(newSettings);
    return newSettings;
  }
}