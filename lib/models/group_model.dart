class GroupModel {
  final String id;
  final String name;
  final String thumbnailUrl;
  final int memberCount;
  final String groupCode;

  GroupModel({
    required this.id,
    required this.name,
    required this.thumbnailUrl,
    required this.memberCount,
    required this.groupCode,
  });

  // Dummy data generator
  static List<GroupModel> getDummyGroups() {
    return [
      GroupModel(
        id: '1',
        name: 'Family Trip 2024',
        thumbnailUrl: 'https://via.placeholder.com/150',
        memberCount: 8,
        groupCode: 'ABCD',
      ),
      GroupModel(
        id: '2',
        name: 'Birthday Party',
        thumbnailUrl: 'https://via.placeholder.com/150',
        memberCount: 15,
        groupCode: 'EFGH',
      ),
      GroupModel(
        id: '3',
        name: 'College Reunion',
        thumbnailUrl: 'https://via.placeholder.com/150',
        memberCount: 25,
        groupCode: 'IJKL',
      ),
      GroupModel(
        id: '4',
        name: 'Wedding Ceremony',
        thumbnailUrl: 'https://via.placeholder.com/150',
        memberCount: 50,
        groupCode: 'MNOP',
      ),
      GroupModel(
        id: '5',
        name: 'Office Outing',
        thumbnailUrl: 'https://via.placeholder.com/150',
        memberCount: 12,
        groupCode: 'QRST',
      ),
    ];
  }
}