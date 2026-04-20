import 'package:gallaerial/data/v_hive/dto/assets/asset_dto.dart';
import 'package:gallaerial/domain/entities/asset_entity.dart';
import 'package:hive_flutter/adapters.dart';

part 'image_dto.g.dart';

@HiveType(typeId: 4)
class ImageDto extends AssetDto{

  ImageDto({required super.id, required super.assetId, required super.name, required super.tagIds});

  static ImageDto fromEntity(ImageEntity entity){
    return ImageDto(id: entity.id, assetId: entity.assetId, name: entity.name, tagIds: entity.tagIds);
  }

  ImageEntity toEntity(){
    return ImageEntity(id: id, assetId: assetId, name: name, tagIds: tagIds ?? []);
  }
}