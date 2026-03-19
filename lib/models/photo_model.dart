class PhotoModel {
  final int id;
  final String url;
  final int groupId;
  final bool isMyPhoto;
  final DateTime uploadedAt;
  final String uploaderName;
  bool isSelectedForAlbum;

  PhotoModel({
    required this.id,
    required this.url,
    required this.groupId,
    required this.isMyPhoto,
    required this.uploadedAt,
    required this.uploaderName,
    this.isSelectedForAlbum = false,
  });

  factory PhotoModel.fromMap(Map<String, dynamic> map) {
    return PhotoModel(
      id: map['id'] ?? 0,
      url: map['image'] ?? '',
      groupId: map['group_id'] ?? 0,
      isMyPhoto: false, // Updated from face scan logic typically
      uploadedAt: map['created_at'] != null 
          ? DateTime.tryParse(map['created_at']) ?? DateTime.now()
          : DateTime.now(),
      uploaderName: 'User', // Usually joined from uploader data if available
    );
  }

  // Static store for selected photos since user wants persistent selection in session
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