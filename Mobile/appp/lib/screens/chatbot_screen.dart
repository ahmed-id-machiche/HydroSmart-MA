import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../services/api_services.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<ChatMessage> messages = [
    ChatMessage(
      text:
          "Hello 👋 I am the HydroSmart Assistant. Ask me a question about irrigation, weather, ET0, ETc, or your plots.",
      isUser: false,
    ),
  ];

  bool sending = false;
  String userInitial = "F"; // Default initial for Farmer

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await ApiService.getFarmerProfile();
      final fullName = profile["fullName"]?.toString() ?? "";
      if (fullName.isNotEmpty) {
        setState(() {
          userInitial = fullName[0].toUpperCase();
        });
      }
    } catch (_) {
      // Silently keep default initial "F"
    }
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      messages.add(ChatMessage(text: text, isUser: true));
      messageController.clear();
      sending = true;
    });
    _scrollToBottom();

    try {
      final botReply = await ApiService.getChatResponse(text);
      if (!mounted) return;

      setState(() {
        messages.add(ChatMessage(text: botReply, isUser: false));
        sending = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        messages.add(ChatMessage(
          text:
              "Sorry, I cannot contact the server. Please check your internet connection and try again.",
          isUser: false,
          isError: true,
        ));
        sending = false;
      });
    }
    _scrollToBottom();
  }

  Future<void> retrySendMessage(String text) async {
    setState(() {
      sending = true;
    });
    _scrollToBottom();

    try {
      final botReply = await ApiService.getChatResponse(text);
      if (!mounted) return;

      setState(() {
        messages.add(ChatMessage(text: botReply, isUser: false));
        sending = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        messages.add(ChatMessage(
          text:
              "Sorry, I cannot contact the server. Please check your internet connection and try again.",
          isUser: false,
          isError: true,
        ));
        sending = false;
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 22),
              decoration: const BoxDecoration(
                color: primaryGreen,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(28),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const CircleAvatar(
                      backgroundImage: AssetImage("assets/images/bot_farmer.png"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "HydroSmart Assistant",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Online • Irrigation Help",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: messages.length + (sending ? 1 : 0),
                itemBuilder: (context, index) {
                  if (sending && index == messages.length) {
                    return BotTypingBubble(userInitial: userInitial);
                  }

                  final message = messages[index];

                  return ChatBubble(
                    message: message,
                    userInitial: userInitial,
                    onRetry: message.isError
                        ? () {
                            setState(() {
                              messages.removeAt(index);
                            });
                            // Find last user message to retry
                            for (int i = messages.length - 1; i >= 0; i--) {
                              if (messages[i].isUser) {
                                retrySendMessage(messages[i].text);
                                break;
                              }
                            }
                          }
                        : null,
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: "Ask your question about irrigation...",
                        filled: true,
                        fillColor: lightBackground,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: sending ? null : sendMessage,
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: sending ? Colors.grey[300] : primaryGreen,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: sending
                            ? null
                            : [
                                BoxShadow(
                                  color: primaryGreen.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                      ),
                      child: Icon(
                        Icons.send,
                        color: sending ? Colors.grey[600] : Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final bool isError;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.isError = false,
  });
}

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final String userInitial;
  final VoidCallback? onRetry;

  const ChatBubble({
    super.key,
    required this.message,
    required this.userInitial,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: message.isError
                  ? Colors.red.withOpacity(0.1)
                  : Colors.transparent,
              backgroundImage: message.isError
                  ? null
                  : const AssetImage("assets/images/bot_farmer.png"),
              child: message.isError
                  ? const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 16,
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              decoration: BoxDecoration(
                color: message.isUser
                    ? primaryGreen
                    : (message.isError ? const Color(0xFFFFF2F2) : Colors.white),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(message.isUser ? 16 : 4),
                  bottomRight: Radius.circular(message.isUser ? 4 : 16),
                ),
                border: message.isError
                    ? Border.all(color: Colors.red.withOpacity(0.3))
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildMessageContent(message.text, message.isUser),
                  if (message.isError && onRetry != null) ...[
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: onRetry,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.refresh, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              "Retry",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: primaryGreen,
              child: Text(
                userInitial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget buildMessageContent(String text, bool isUser) {
    final textColor = isUser ? Colors.white : darkText;
    final lines = text.split('\n');
    final List<Widget> children = [];

    for (var i = 0; i < lines.length; i++) {
      var line = lines[i].trim();
      if (line.isEmpty) {
        if (i < lines.length - 1) {
          children.add(const SizedBox(height: 6));
        }
        continue;
      }

      // Headers: ### Header Name
      if (line.startsWith('### ')) {
        final headerText = line.substring(4);
        children.add(
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(
              headerText,
              style: TextStyle(
                color: isUser ? Colors.white : primaryGreen,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
        continue;
      }

      // List item: - Item text or * Item text
      bool isListItem = false;
      if (line.startsWith('- ') || line.startsWith('* ')) {
        isListItem = true;
        line = line.substring(2);
      }

      // Parse inline bold and inline code
      final spans = parseInlineStyles(line, isUser);

      if (isListItem) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "• ",
                  style: TextStyle(
                    color: isUser ? Colors.white70 : primaryGreen,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      children: spans,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 13.5,
                        height: 1.35,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        children.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: RichText(
              text: TextSpan(
                children: spans,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13.5,
                  height: 1.35,
                ),
              ),
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  List<TextSpan> parseInlineStyles(String line, bool isUser) {
    final List<TextSpan> spans = [];
    final regExp = RegExp(r'(\*\*([^*]+)\*\*|`([^`]+)`|\$\$([^$]+)\$\$)');
    int lastMatchEnd = 0;

    for (final match in regExp.allMatches(line)) {
      // Add text before the match
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(text: line.substring(lastMatchEnd, match.start)));
      }

      if (match.group(2) != null) {
        // Bold text: **bold**
        spans.add(
          TextSpan(
            text: match.group(2),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        );
      } else if (match.group(3) != null) {
        // Code text: `code`
        spans.add(
          TextSpan(
            text: match.group(3),
            style: TextStyle(
              fontFamily: 'monospace',
              backgroundColor: isUser ? Colors.white12 : Colors.grey[200],
              color: isUser ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      } else if (match.group(4) != null) {
        // Math/Formula text: $$formula$$
        spans.add(
          TextSpan(
            text: match.group(4),
            style: const TextStyle(
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < line.length) {
      spans.add(TextSpan(text: line.substring(lastMatchEnd)));
    }

    return spans;
  }
}

class BotTypingBubble extends StatelessWidget {
  final String userInitial;

  const BotTypingBubble({
    super.key,
    required this.userInitial,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              radius: 16,
              backgroundImage: AssetImage("assets/images/bot_farmer.png"),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                  bottomLeft: Radius.circular(4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Assistant is typing...",
                    style: TextStyle(
                      color: darkText.withOpacity(0.6),
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}