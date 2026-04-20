sealed class UserAssetEntity{
  final String id;
  final String assetId;
  final String name;
  final List<String> tagIds;

  UserAssetEntity({required this.id, required this.assetId, required this.name, required this.tagIds});
}

class ImageEntity extends UserAssetEntity {

  ImageEntity({required super.id, required super.assetId, required super.name, required super.tagIds});
}

class VideoEntity extends UserAssetEntity {
  final String? coverPath;

  VideoEntity({this.coverPath, required super.id, required super.assetId, required super.name, required super.tagIds, });
}
