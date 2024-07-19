import 'package:flutter/material.dart';

class MessageBubble extends StatelessWidget {
  final String authorId;
  final String content;
  final bool isCurrentUser;
  final bool readed;

  const MessageBubble({
    super.key,
    required this.authorId,
    required this.content,
    required this.isCurrentUser,
    required this.readed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Align(
          alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            margin: EdgeInsets.only(
              top: 4,
              bottom: 4,
              left: isCurrentUser ? 50 : 15,
              right: isCurrentUser ? 15 : 50,
            ),
            decoration: BoxDecoration(
              color: isCurrentUser ? Colors.deepOrangeAccent : Colors.grey[300],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              content,
              style: TextStyle(
                  fontSize: 16,
                  color: isCurrentUser ? Colors.white : Colors.black,
                  fontFamily: 'Readex Pro'
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(
            left: isCurrentUser ? 50 : 15,
            right: isCurrentUser ? 15 : 50,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (readed)
                const Icon(
                  Icons.check,
                  size: 12,
                  color: Colors.grey,
                ),
            ],
          ),
        ),
      ],
    );
  }
}