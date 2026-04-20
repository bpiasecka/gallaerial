import 'dart:async';

import 'package:gallaerial/data/v_hive/dto/assets/image_dto.dart';
import 'package:gallaerial/data/v_hive/repositories/assets/base_asset_repository_impl.dart';
import 'package:gallaerial/domain/entities/asset_entity.dart';
import 'package:gallaerial/domain/repositories/image_repository.dart';
import 'package:hive/hive.dart';

class ImageAssetRepositoryImpl extends BaseAssetRepository<ImageEntity, ImageDto> implements ImageRepository{

  @override final Box<ImageDto> box = Hive.box<ImageDto>('images');
  @override final String defaultName = "image name";

  @override
  ImageEntity mapToEntity(ImageDto dto) => dto.toEntity();

  @override
  ImageDto mapToDto(ImageEntity entity) => ImageDto.fromEntity(entity);

  @override
  ImageDto createNewDto(String id, String assetId, String name) {
    return ImageDto(id: id, assetId: assetId, name: name, tagIds: []);
  }

  @override
  Future<void> cleanUpInfrastructure(ImageEntity entity) async {
  }
}