import 'package:gallaerial/domain/entities/tag_entity.dart';
import 'package:gallaerial/domain/entities/video_entity.dart';

abstract class UserRepository {
  Future<void> initialize();
  Stream<List<VideoEntity>> get videoDataStream;
  Stream<List<TagEntity>> get tagDataStream;

  Future<List<VideoEntity>> getVideos();
  Future<List<VideoEntity>> addVideos(List<String> paths);
  Future<void> removeVideo(VideoEntity video);
  Future<VideoEntity> editVideo(VideoEntity video, String newName, List<String> newTagIds);

  Future<List<TagEntity>> getTags();
  Future<TagEntity> addTag(String colorHex, String name);
  Future<void> removeTag(TagEntity tag);
  Future<TagEntity> editTag(TagEntity tag, String newColorHex, String newName);
  Future<List<TagEntity>> changeTagsOrder(int oldTagOrder, int newTagOrder);
}

