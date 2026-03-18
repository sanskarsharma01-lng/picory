class PhotoModel {
  final String id;
  final String url;
  final String groupId;
  final bool isMyPhoto;
  final DateTime uploadedAt;
  final String uploaderName;

  PhotoModel({
    required this.id,
    required this.url,
    required this.groupId,
    required this.isMyPhoto,
    required this.uploadedAt,
    required this.uploaderName,
  });

  // Dummy data generator
  static List<PhotoModel> getDummyPhotos(String groupId) {
    final now = DateTime.now();
    return List.generate(20, (index) {
      return PhotoModel(
        id: 'photo_${groupId}_$index',
        url: 'https://via.placeholder.com/300x400?text=Photo+${index + 1}',
        groupId: groupId,
        isMyPhoto: index % 3 == 0,
        uploadedAt: now.subtract(Duration(days: index)),
        uploaderName: index % 3 == 0 ? 'Me' : 'User ${index + 1}',
      );
    });
  }

  static List<PhotoModel> getMyPhotos(String groupId) {
    return getDummyPhotos(groupId).where((photo) => photo.isMyPhoto).toList();
  }

  static List<PhotoModel> getAllPhotos(String groupId) {
    return getDummyPhotos(groupId);
  }
}