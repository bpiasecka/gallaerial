import 'package:hive_flutter/adapters.dart';

//part 'asset_dto.g.dart';

//@HiveType(typeId: 3)
abstract class AssetDto {

  @HiveField(0) String id;
  @HiveField(1) String assetId;
  @HiveField(2) String name;
  @HiveField(3) List<String>? tagIds;

  AssetDto({required this.id, required this.assetId, required this.name, required this.tagIds});  
}