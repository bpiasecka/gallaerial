import 'package:gallaerial/domain/entities/video_entity.dart';
import 'package:hive_flutter/adapters.dart';

part 'video_dto.g.dart';

@HiveType(typeId: 1)
class VideoDto{

  @HiveField(0) String id;
  @HiveField(1) String assetId;
  @HiveField(2) String name;
  @HiveField(3) List<String>? tagIds;
  @HiveField(4) String? coverPath;

  VideoDto({required this.id, required this.assetId, required this.name, required this.tagIds, this.coverPath});

  static VideoDto fromVideoEntity(VideoEntity entity){
    return VideoDto(id: entity.id, assetId: entity.assetId, name: entity.name, tagIds: entity.tagIds, coverPath: entity.coverPath);
  }

  VideoEntity toVideoEntity(){
    return VideoEntity(id: id, assetId: assetId, name: name, tagIds: tagIds ?? [], coverPath: coverPath);
  }
}