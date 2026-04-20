import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:gallaerial/data/v_hive/dto/assets/video_dto.dart';
import 'package:gallaerial/data/v_hive/repositories/assets/base_asset_repository_impl.dart';
import 'package:gallaerial/domain/entities/asset_entity.dart';
import 'package:gallaerial/domain/repositories/video_repository.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

class VideoAssetRepositoryImpl extends BaseAssetRepository<VideoEntity, VideoDto> implements VideoRepository{
  @override final Box<VideoDto> box = Hive.box<VideoDto>('videos');
  @override final String defaultName = "video name";

  @override
  VideoEntity mapToEntity(VideoDto dto) => dto.toEntity();

  @override
  VideoDto mapToDto(VideoEntity entity) => VideoDto.fromEntity(entity);

  @override
  VideoDto createNewDto(String id, String assetId, String name) {
    return VideoDto(id: id, assetId: assetId, name: name, tagIds: []);
  }

  @override
  Future<void> cleanUpInfrastructure(VideoEntity entity) async {
    if (entity.coverPath != null) {
      final file = File(entity.coverPath!);
      if (await file.exists()) await file.delete();
    }
  }

  @override
  Future<VideoEntity> setVideoCover(VideoEntity video, Uint8List image) async {

    if(video.coverPath != null){
      final oldFile = File(video.coverPath!);
      if (await oldFile.exists()) {
        await oldFile.delete();
      }
    }

    final directory = await getApplicationDocumentsDirectory();

    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final String fileName = 'thumb_$id.jpg';
    final File file = File('${directory.path}/$fileName');
  
    await file.writeAsBytes(image);    
    

    final updatedDto = VideoDto(
      id: video.id, 
      assetId: video.assetId,
      name: video.name,
      tagIds: video.tagIds,
      coverPath: file.path
    );
    
    await box.put(video.id, updatedDto);

    broadcastUpdate();
    
    return updatedDto.toEntity();
  }

  /*Future<void> syncMetadataInBackground() async {
    bool hasChanges = false;

    await Future.wait(box.values.map((dto) async {
      final nativeAsset = await AssetEntity.fromId(dto.assetId);
      
      if (nativeAsset != null) {
        final currentDuration = nativeAsset.duration;
        
        if (dto.durationSeconds != currentDuration) {
          dto.durationSeconds = currentDuration;
          await box.put(dto.id, dto);
          hasChanges = true;
        }
      } else {
        await box.delete(dto.id);
        hasChanges = true;
      }
    }));

    if (hasChanges) {
      await broadcastUpdate();
    }
  }*/
}