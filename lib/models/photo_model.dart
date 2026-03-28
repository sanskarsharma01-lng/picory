class PhotoModel {
  final int id;
  final String url;
  final String? thumbnailUrl;
  final int groupId;
  final bool isMyPhoto;
  final DateTime uploadedAt;
  final String uploaderName;
  bool isSelectedForAlbum;

  PhotoModel({
    required this.id,
    required this.url,
    this.thumbnailUrl,
    required this.groupId,
    required this.isMyPhoto,
    required this.uploadedAt,
    required this.uploaderName,
    this.isSelectedForAlbum = false,
  });

  factory PhotoModel.fromMap(Map<String, dynamic> map) {
    final imageUrl = map['image'] ?? '';
    final user = map['user'] as Map<String, dynamic>? ?? {};
    
    return PhotoModel(
      id: map['id'] ?? 0,
      url: imageUrl,
      thumbnailUrl: map['thumbnail'] ?? imageUrl,
      groupId: map['group_id'] ?? 0,
      isMyPhoto: map['is_my_photo'] ?? false, 
      uploadedAt: map['created_at'] != null 
          ? DateTime.tryParse(map['created_at']) ?? DateTime.now()
          : DateTime.now(),
      uploaderName: user['name'] ?? 'User',
    );
  }

  static final List<PhotoModel> _selectedPhotos = [];

  static List<PhotoModel> getAlbumPhotos() => _selectedPhotos;

  void toggleSelection() {
    isSelectedForAlbum = !isSelectedForAlbum;
    if (isSelectedForAlbum) {
      if (!_selectedPhotos.any((p) => p.id == id)) {
        _selectedPhotos.add(this);
      }
    } else {
      _selectedPhotos.removeWhere((p) => p.id == id);
    }
  }
}
