class ServerModel {
  final String id;
  final String ownerId;
  String name;
  String description;
  String image;
  List<dynamic> members = [];
  final int creationTime; // New field for creation time

  ServerModel({
    required this.name,
    required this.description,
    required this.image,
    required this.id,
    required this.ownerId,
    List<dynamic>? members,
    int? creationTime, // Include creation time in the constructor
  })  : members = members ?? [],
        creationTime = creationTime ?? DateTime.now().millisecondsSinceEpoch; // Assign current time if not provided

  // To JSON
  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'image': image,
    'id': id,
    'ownerId': ownerId,
    'members': members,
    'creationTime': creationTime, // Include creation time in JSON output
  };

  // From JSON
  factory ServerModel.fromJson(Map<String, dynamic> json) {
    return ServerModel(
      name: json['name'],
      description: json['description'],
      image: json['image'],
      id: json['id'],
      ownerId: json['ownerId'],
      members: json['members'] ?? [],
      creationTime: json['creationTime'] ?? DateTime.now().millisecondsSinceEpoch, // Use current time if creation time is missing
    );
  }
}
