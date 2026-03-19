class GroupModel {
  final int id;
  final String name;
  final String barcode;
  final String eventTitle;
  final String eventDescription;
  final String location;
  final DateTime? eventDate;
  final String? thumbnailUrl;

  GroupModel({
    required this.id,
    required this.name,
    required this.barcode,
    required this.eventTitle,
    required this.eventDescription,
    required this.location,
    this.eventDate,
    this.thumbnailUrl,
  });

  factory GroupModel.fromMap(Map<String, dynamic> map) {
    final event = map['event'] as Map<String, dynamic>? ?? {};
    return GroupModel(
      id: map['id'] ?? 0,
      name: map['name'] ?? '',
      barcode: map['barcode'] ?? '',
      eventTitle: event['title'] ?? '',
      eventDescription: event['description'] ?? '',
      location: event['location'] ?? '',
      eventDate: event['event_date'] != null 
          ? DateTime.tryParse(event['event_date']) 
          : null,
      thumbnailUrl: null,
    );
  }
}