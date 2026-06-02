import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final messageController = TextEditingController();

  final List<ChatMessage> messages = [
    ChatMessage(
      text:
          "Bonjour 👋 Je suis l’assistant HydroSmart. Pose-moi une question sur l’irrigation, la météo, ET0, ETc ou tes parcelles.",
      isUser: false,
    ),
  ];

  bool sending = false;

  Future<void> sendMessage() async {
    final text = messageController.text.trim();

    if (text.isEmpty) return;

    setState(() {
      messages.add(ChatMessage(text: text, isUser: true));
      messageController.clear();
      sending = true;
    });

    await Future.delayed(const Duration(milliseconds: 700));

    final botReply = getLocalBotReply(text);

    if (!mounted) return;

    setState(() {
      messages.add(ChatMessage(text: botReply, isUser: false));
      sending = false;
    });
  }

  String getLocalBotReply(String question) {
    final q = question.toLowerCase();

    if (q.contains("et0")) {
      return "ET0 signifie évapotranspiration de référence. Elle indique la quantité d’eau perdue par le sol et la plante à cause de la chaleur, du vent, de l’humidité et du rayonnement solaire.";
    }

    if (q.contains("etc")) {
      return "ETc est le besoin réel de la culture en eau. On le calcule avec: ETc = ET0 × Kc. Le coefficient Kc dépend du type de culture et de son stade de croissance.";
    }

    if (q.contains("irrig") || q.contains("eau")) {
      return "Pour décider l’irrigation, HydroSmart utilise la météo, ET0, le coefficient Kc, la pluie, la surface de la parcelle et l’efficacité d’irrigation.";
    }

    if (q.contains("pluie") || q.contains("rain")) {
      return "S’il y a de la pluie, le besoin d’irrigation peut être réduit. HydroSmart prend la précipitation en compte dans le calcul du besoin net.";
    }

    if (q.contains("météo") || q.contains("meteo") || q.contains("weather")) {
      return "La météo est récupérée depuis OpenWeather en utilisant la latitude et longitude de la parcelle ou de la localisation choisie.";
    }

    if (q.contains("parcelle") || q.contains("field")) {
      return "Une parcelle contient le nom, la culture, la surface, le type de sol et la localisation GPS. Ces informations sont utilisées pour calculer les recommandations.";
    }

    return "Je peux t’aider à comprendre l’irrigation, la météo, ET0, ETc, les cultures et les recommandations. Plus tard, je pourrai aussi répondre avec les données réelles de tes parcelles.";
  }

  @override
  void dispose() {
    messageController.dispose();
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
                  const CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.smart_toy_outlined,
                      color: primaryGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Assistant HydroSmart",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "Aide irrigation & météo",
                          style: TextStyle(
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
                padding: const EdgeInsets.all(16),
                itemCount: messages.length + (sending ? 1 : 0),
                itemBuilder: (context, index) {
                  if (sending && index == messages.length) {
                    return const BotTypingBubble();
                  }

                  final message = messages[index];

                  return ChatBubble(message: message);
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
                      decoration: InputDecoration(
                        hintText: "Écris ta question...",
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
                        color: sending ? Colors.grey : primaryGreen,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(
                        Icons.send,
                        color: Colors.white,
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

  ChatMessage({
    required this.text,
    required this.isUser,
  });
}

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final alignment =
        message.isUser ? Alignment.centerRight : Alignment.centerLeft;

    final bubbleColor = message.isUser ? primaryGreen : Colors.white;
    final textColor = message.isUser ? Colors.white : darkText;

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 12,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.76,
        ),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(message.isUser ? 18 : 4),
            bottomRight: Radius.circular(message.isUser ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}

class BotTypingBubble extends StatelessWidget {
  const BotTypingBubble({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Text(
          "Assistant écrit...",
          style: TextStyle(
            color: Colors.black54,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}