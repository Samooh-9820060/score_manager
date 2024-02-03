class Participant {
  final String? id; // Made nullable
  final String name;
  final String? mail; // Already nullable
  final String? profileImageURL; // Already nullable
  final bool isRegisteredUser;

  Participant({
    this.id, // Made nullable
    required this.name,
    this.mail,
    this.profileImageURL,
    this.isRegisteredUser = false,
  });

  factory Participant.fromMap(Map<String, dynamic> map) {
    return Participant(
      id: map['id'],
      name: map['name'] ?? '',
      mail: map['mail'],
      profileImageURL: map['profileImageURL'],
      isRegisteredUser: map['isRegisteredUser'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'mail': mail,
      'profileImageURL': profileImageURL,
      'isRegisteredUser': isRegisteredUser,
    };
  }
}
