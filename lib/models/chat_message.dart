import 'dart:io';

enum Sender { user, ai }

class ChatMessage {
  final String? text;
  final File? image;
  final Sender sender;
  final bool isLoading;

  ChatMessage({
    this.text,
    this.image,
    required this.sender,
    this.isLoading = false,
  });
}
