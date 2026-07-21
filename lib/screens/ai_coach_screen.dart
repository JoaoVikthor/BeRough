import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/chat_message.dart';
import 'skill_selection_screen.dart'; // Importação essencial para guiar até a seleção de skills
import 'auth_screen.dart';

class AICoachScreen extends StatefulWidget {
  const AICoachScreen({Key? key}) : super(key: key);

  @override
  State<AICoachScreen> createState() => _AICoachScreenState();
}

class _AICoachScreenState extends State<AICoachScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  
  int _chatStep = 0; // Controla quando liberar o botão "VER MEU PLANO"
  ChatSession? _chat; // Sessão do Gemini
  bool _isSetupComplete = false;
  bool _useSimulationMode = false; // Modo de fallback se não houver API Key

  @override
  void initState() {
    super.initState();
    _messages.add(ChatMessage(
      text: "Fala, atleta! Sou o Coach de IA do BeRough. Antes de liberar seu mapa de treinos, preciso calcular sua alavancagem para adaptar as progressões de calistenia pra você. Me passa sua altura, peso e idade, por favor.",
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
      Content.model([TextPart('Fala, atleta! Sou o Coach de IA do BeRough. Antes de liberar seu mapa de treinos, preciso calcular sua alavancagem para adaptar as progressões de calistenia pra você. Me passa sua altura, peso e idade, por favor.')])
    ]);

    setState(() {
      _isSetupComplete = true;
    });
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
              isUser: false
            ));
          } else {
            _messages.add(ChatMessage(text: responseText, isUser: false));
          }
        });
      } catch (e) {
        setState(() {
          _isTyping = false;
          _messages.add(ChatMessage(
            text: "Erro de Conexão. Verifique sua internet ou a API Key.", 
            isUser: false
          ));
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
        resposta = "Boa. E qual o seu foco principal? (Hipertrofia, Ganhar Força, Dominar Skills, Perder Peso)";
      } else if (_chatStep == 2) {
        resposta = "Anotado! Agora o teste de força: Quantas flexões de braço e barras fixas você consegue fazer hoje sem parar?";
      } else if (_chatStep == 3) {
        resposta = "Pra fechar: Qual seu tempo máximo na prancha isométrica e tempo médio de corrida leve?";
      } else {
        resposta = "Fechou! Perfil analisado e salvo com sucesso. Seu Plano de Evolução BeRough está pronto.";
        _chatStep = 4; // Libera o botão
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
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A24),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const AuthScreen()),
            );
          },
        ),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.smart_toy, color: Color(0xFF9C27B0)),
            SizedBox(width: 8),
            Text("Treinador Virtual", style: TextStyle(fontFamily: 'Oswald', fontWeight: FontWeight.bold)),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: const Color(0xFF333333), height: 1.0),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          if (_isTyping)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "O Coach está avaliando...",
                  style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 12),
                ),
              ),
            ),
          
          if (_chatStep > 3)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // MUDADO PARA O FLUXO DE SELEÇÃO DE SKILLS ANTES DA HOME
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const SkillSelectionScreen()),
                    );
                  },
                  child: const Text("AVANÇAR PARA SELEÇÃO DE METAS"),
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
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser)
            const CircleAvatar(
              backgroundColor: Color(0xFF1A1A24),
              child: Icon(Icons.smart_toy, color: Color(0xFF9C27B0), size: 20),
            ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: message.isUser ? const Color(0xFF9C27B0) : const Color(0xFF1A1A24),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(message.isUser ? 20 : 4),
                  bottomRight: Radius.circular(message.isUser ? 4 : 20),
                ),
                border: message.isUser ? null : Border.all(color: const Color(0xFF333333)),
              ),
              child: Text(
                message.text,
                style: const TextStyle(color: Colors.white, height: 1.4),
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
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A24),
        border: Border(top: BorderSide(color: Color(0xFF333333))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              style: const TextStyle(color: Colors.white),
              onSubmitted: _handleSubmitted,
              decoration: InputDecoration(
                hintText: "Ex: 1.75m, 70kg, 25 anos...",
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: const Color(0xFF0D0D12),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Color(0xFF333333)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Color(0xFF9C27B0)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF9C27B0),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: () => _handleSubmitted(_textController.text),
            ),
          ),
        ],
      ),
    );
  }
}