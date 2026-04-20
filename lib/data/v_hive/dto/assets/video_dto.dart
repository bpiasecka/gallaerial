import 'package:gallaerial/data/v_hive/dto/assets/asset_dto.dart';
import 'package:gallaerial/domain/entities/asset_entity.dart';
import 'package:hive_flutter/adapters.dart';

part 'video_dto.g.dart';

@HiveType(typeId: 1)
class VideoDto extends AssetDto{
  @HiveField(4) String? coverPath;

  VideoDto({required super.id, required super.assetId, required super.name, required super.tagIds, this.coverPath});

  static VideoDto fromEntity(VideoEntity entity){
    return VideoDto(id: entity.id, assetId: entity.assetId, name: entity.name, tagIds: entity.tagIds, coverPath: entity.coverPath);
  }

  VideoEntity toEntity(){
    return VideoEntity(id: id, assetId: assetId, name: name, tagIds: tagIds ?? [], coverPath: coverPath);
  }
}