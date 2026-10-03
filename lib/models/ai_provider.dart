enum AiProviderId { claude, chatgpt, gemini }

class AiProvider {
  final AiProviderId id;
  final String displayName;
  final String hint; // ex: "sk-ant-..."

  const AiProvider({required this.id, required this.displayName, required this.hint});

  static const List<AiProvider> all = [
    AiProvider(id: AiProviderId.claude, displayName: 'Claude (Anthropic)', hint: 'sk-ant-...'),
    AiProvider(id: AiProviderId.chatgpt, displayName: 'ChatGPT (OpenAI)', hint: 'sk-...'),
    AiProvider(id: AiProviderId.gemini, displayName: 'Gemini (Google)', hint: 'AIza...'),
  ];

  static AiProvider byId(AiProviderId id) => all.firstWhere((p) => p.id == id);
}
