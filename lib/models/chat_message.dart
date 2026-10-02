import 'dart:io';

enum Sender { user, ai }

class ChatMessage {
  final String? text;
  final File? image;
  final Sender sender;
  final bool isLoading;
  final DateTime timestamp;

  ChatMessage({
    this.text,
    this.image,
    required this.sender,
    this.isLoading = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
