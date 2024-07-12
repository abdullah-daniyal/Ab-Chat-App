// chat_user.dart
class ChatUser {
  final String id;
  final String name;
  final String email;
  late final String image;
  final String about;
  final bool hasMessaged;

  var pushToken;
  
  ChatUser({
    required this.id,
    required this.name,
    required this.email,
    required this.image,
    required this.about,
    this.hasMessaged = false,
  });

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      image: json['image'] as String,
      about: json['about'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'image': image,
      'about': about,
    };
  }
}
