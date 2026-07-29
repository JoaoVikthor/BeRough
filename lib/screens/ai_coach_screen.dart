import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../design/tokens.dart';
import '../design/ui.dart';
import '../models/chat_message.dart';
import 'skill_selection_screen.dart';
import 'auth_screen.dart';

class AICoachScreen extends StatefulWidget {
  const AICoachScreen({super.key});

  @override
  State<AICoachScreen> createState() => _AICoachScreenState();
}

class _AICoachScreenState extends State<AICoachScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  int _chatStep = 0;
  ChatSession? _chat;
  bool _isSetupComplete = false;
  bool _useSimulationMode = false;

  @override
  void initState() {
    super.initState();
    _messages.add(ChatMessage(
      text:
          "Fala, atleta! Sou o Coach de IA do BeRough. Antes de liberar seu mapa de treinos, preciso calcular sua alavancagem para adaptar as progressões de calistenia pra você. Me passa sua altura, peso e idade, por favor.",
      isUser: false,
    ));
    _initGemini();
  }

  void _initGemini() {
    const apiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
    if (apiKey.isEmpty) {
      setState(() {
        _useSimulationMode = true;
        _isSetupComplete = true;
      });
      return;
    }

    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      systemInstruction: Content.system('''
        Você é um treinador de calistenia durão, direto e focado em resultados do aplicativo BeRough. 
        As informações que você PRECISA coletar do usuário, UMA PERGUNTA POR VEZ, são:
        1. Peso, Altura e Idade. (Já perguntado, valide os dados).
        2. Qual o principal objetivo na calistenia? (Hipertrofia, Força, Skills, Perder Peso).
        3. Teste (força): Quantas flexões e barras fixas consegue fazer seguidas hoje?
        4. Teste (resistência): Tempo máximo em prancha e tempo em corrida leve?
        
        Regras: APENAS UMA pergunta de cada vez. Respostas curtas.
        Quando coletar TODOS os 4 pontos, termine sua mensagem EXATAMENTE com a tag: [FIM_DO_QUESTIONARIO]
      '''),
    );

    _chat = model.startChat(history: [
      Content.model([
        TextPart(
            'Fala, atleta! Sou o Coach de IA do BeRough. Antes de liberar seu mapa de treinos, preciso calcular sua alavancagem para adaptar as progressões de calistenia pra você. Me passa sua altura, peso e idade, por favor.')
      ])
    ]);

    setState(() => _isSetupComplete = true);
  }

  void _handleSubmitted(String text) async {
    if (text.trim().isEmpty || !_isSetupComplete) return;

    _textController.clear();
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isTyping = true;
    });
    _scrollToBottom();

    if (_useSimulationMode) {
      await Future.delayed(const Duration(seconds: 2));
      _simulateNextQuestion();
    } else {
      try {
        final response = await _chat!.sendMessage(Content.text(text));
        final responseText = response.text ?? 'Ops, deu um branco aqui. Pode repetir?';

        setState(() {
          _isTyping = false;
          if (responseText.contains('[FIM_DO_QUESTIONARIO]')) {
            _chatStep = 4;
            _messages.add(ChatMessage(
                text: responseText.replaceAll('[FIM_DO_QUESTIONARIO]', '').trim(),
                isUser: false));
          } else {
            _messages.add(ChatMessage(text: responseText, isUser: false));
          }
        });
      } catch (_) {
        setState(() {
          _isTyping = false;
          _messages.add(ChatMessage(
              text: "Erro de Conexão. Verifique sua internet ou a API Key.",
              isUser: false));
        });
      }
    }
    _scrollToBottom();
  }

  void _simulateNextQuestion() {
    setState(() {
      _isTyping = false;
      _chatStep++;
      String resposta = "";
      if (_chatStep == 1) {
        resposta =
            "Boa. E qual o seu foco principal? (Hipertrofia, Ganhar Força, Dominar Skills, Perder Peso)";
      } else if (_chatStep == 2) {
        resposta =
            "Anotado! Agora o teste de força: Quantas flexões de braço e barras fixas você consegue fazer hoje sem parar?";
      } else if (_chatStep == 3) {
        resposta =
            "Pra fechar: Qual seu tempo máximo na prancha isométrica e tempo médio de corrida leve?";
      } else {
        resposta =
            "Fechou! Perfil analisado e salvo com sucesso. Seu Plano de Evolução BeRough está pronto.";
        _chatStep = 4;
      }
      _messages.add(ChatMessage(text: resposta, isUser: false));
    });
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BeColors.canvas,
      appBar: AppBar(
        backgroundColor: BeColors.canvasElevated,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: BeColors.ink, size: 18),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AuthScreen()),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.smart_toy, color: BeColors.primary, size: 20),
            const SizedBox(width: 8),
            Text("TREINADOR VIRTUAL"),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: BeHairline(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(BeSpacing.xs),
              itemCount: _messages.length,
              itemBuilder: (context, index) => _buildMessageBubble(_messages[index]),
            ),
          ),
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: BeSpacing.xs, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "O Coach está avaliando...",
                  style: BeFonts.caption.copyWith(color: BeColors.muted),
                ),
              ),
            ),
          if (_chatStep > 3)
            Padding(
              padding: const EdgeInsets.all(BeSpacing.xs),
              child: SizedBox(
                width: double.infinity,
                child: BePrimaryButton(
                  label: "Avançar para Seleção de Metas",
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SkillSelectionScreen()),
                  ),
                ),
              ),
            )
          else
            _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: BeSpacing.xs),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: BeColors.canvasElevated,
                border: Border.all(color: BeColors.hairline, width: 1),
              ),
              child: const Icon(Icons.smart_toy, color: BeColors.primary, size: 18),
            ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser ? BeColors.primary : BeColors.canvasElevated,
                border: message.isUser
                    ? null
                    : Border.all(color: BeColors.hairline, width: 1),
              ),
              child: Text(
                message.text,
                style: BeFonts.bodyMd.copyWith(
                    color: message.isUser ? BeColors.onPrimary : BeColors.ink),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: BeSpacing.xs, vertical: BeSpacing.xs),
      decoration: const BoxDecoration(
        color: BeColors.canvasElevated,
        border: Border(top: BorderSide(color: BeColors.hairline, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              style: beBodyMdInk,
              onSubmitted: _handleSubmitted,
              decoration: beInputDecoration(hint: "Ex: 1.75m, 70kg, 25 anos..."),
            ),
          ),
          const SizedBox(width: BeSpacing.xxs),
          Container(
            decoration: const BoxDecoration(
              color: BeColors.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: BeColors.onPrimary),
              onPressed: () => _handleSubmitted(_textController.text),
            ),
          ),
        ],
      ),
    );
  }
}