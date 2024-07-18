class Message {
  final String id;
  final String author;
  final String authorId;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool readed;

  Message({
    required this.id,
    required this.author,
    required this.authorId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    required this.readed
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['ID'],
      author: json['Author'],
      authorId: json['AuthorID'],
      content: json['Content'],
      createdAt: DateTime.parse(json['CreatedAt']),
      updatedAt: DateTime.parse(json['UpdatedAt']),
      readed: json['Readed']
    );
  }
}