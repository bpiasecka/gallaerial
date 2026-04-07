class VideoEntity{
  final String id;
  final String assetId;
  final String name;
  final List<String> tagIds;
  final String? coverPath;

  VideoEntity({required this.id, required this.assetId, required this.name, required this.tagIds, this.coverPath});
}