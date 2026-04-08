import 'package:gallaerial/domain/entities/settings_model.dart';
import 'package:hive/hive.dart';

part 'settings_dto.g.dart';

@HiveType(typeId: 2)
class SettingsDto{
  
  @HiveField(0) final bool showNames;
  @HiveField(1) final bool expandTags;

  SettingsDto({required this.showNames, required this.expandTags});


  static SettingsDto fromSettingsModel(SettingsModel settings){
    return SettingsDto(showNames: settings.showNames, expandTags: settings.expandTags);
  }

  SettingsModel toSettingsModel(){
    return SettingsModel(showNames: showNames, expandTags: expandTags);
  }
}