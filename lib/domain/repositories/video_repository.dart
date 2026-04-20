import 'dart:typed_data';

import 'package:gallaerial/domain/entities/asset_entity.dart';
import 'package:gallaerial/domain/repositories/asset_repository.dart';

abstract class VideoRepository extends AssetRepository<VideoEntity> {
  Future<VideoEntity> setVideoCover(VideoEntity video, Uint8List image);
}