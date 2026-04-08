import 'dart:typed_data';

import 'package:gallaerial/domain/entities/filter_model.dart';
import 'package:gallaerial/domain/entities/settings_model.dart';
import 'package:gallaerial/domain/entities/sort_model.dart';
import 'package:gallaerial/domain/entities/tag_entity.dart';
import 'package:gallaerial/domain/entities/video_entity.dart';

abstract class UserRepository {
  Future<void> initialize();
  Stream<List<VideoEntity>> get videoDataStream;
  Stream<List<TagEntity>> get tagDataStream;
  Stream<SettingsModel> get settingsStream;

  Future<SettingsModel> getSettings();
  Future<SettingsModel> editSettings(SettingsModel newSettings);

  Future<List<VideoEntity>> getVideos({FilterModel? filterModel, SortModel? sortModel});
  Future<List<VideoEntity>> addVideos(List<String> paths);
  Future<void> removeVideo(VideoEntity video);
  Future<VideoEntity> editVideo(VideoEntity video, String newName, List<String> newTagIds, String? coverPath);
  Future<VideoEntity> setVideoCover(VideoEntity video, Uint8List image);

  Future<List<TagEntity>> getTags();
  Future<TagEntity> addTag(String colorHex, String name);
  Future<void> removeTag(TagEntity tag);
  Future<TagEntity> editTag(TagEntity tag, String newColorHex, String newName);
  Future<List<TagEntity>> changeTagsOrder(int oldTagOrder, int newTagOrder);
}

