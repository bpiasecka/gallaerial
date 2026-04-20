import 'package:gallaerial/data/v_hive/dto/assets/image_dto.dart';
import 'package:gallaerial/data/v_hive/dto/settings_dto.dart';
import 'package:gallaerial/data/v_hive/dto/tag_dto.dart';
import 'package:gallaerial/data/v_hive/dto/assets/video_dto.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HiveDatabaseService {
  static Future<void> initialize() async {

    await Hive.initFlutter();
    Hive.registerAdapter(TagDtoAdapter());
    Hive.registerAdapter(VideoDtoAdapter());
    Hive.registerAdapter(SettingsDtoAdapter());
    Hive.registerAdapter(ImageDtoAdapter());

    await Hive.openBox<VideoDto>('videos');
    await Hive.openBox<ImageDto>('images');
    await Hive.openBox<TagDto>('tags');
    await Hive.openBox<SettingsDto>('settings'); 
  }
}