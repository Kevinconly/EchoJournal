import 'package:flutter/material.dart';
import '../../../journal_entry/domain/entities/journal_entry.dart';
import '../../../journal_entry/domain/services/reflection_engine.dart';
import '../../../journal_entry/domain/services/similarity_search_service.dart';
import '../../../journal_entry/domain/repositories/journal_repository.dart';
import '../../../journal_entry/data/repositories/journal_repository_impl.dart';
import '../../../journal_entry/data/datasources/local/database_service.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../../shared/utils/error_handler.dart';
import '../../../../core/constants/app_constants.dart';

class ReflectionChatScreen extends StatefulWidget {
  final JournalEntryEntity entry;

  const ReflectionChatScreen({
    super.key,
    required this.entry,
  });

  @override
  State<ReflectionChatScreen> createState() => _ReflectionChatScreenState();
}

class _ReflectionChatScreenState extends State<ReflectionChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  late SimilaritySearchService _similarityService;

  @override
  void initState() {
    super.initState();
    _similarityService = SimilaritySearchService(
      JournalRepositoryImpl(DatabaseService()),
    );
    _addInitialAssistantMessage();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addInitialAssistantMessage() {
    // Generate contextual opening using Reflection Engine
    final initialMessage = ReflectionEngine.generateInitialReflection(widget.entry);
    
    setState(() {
      _messages.add(ChatMessage(
        text: initialMessage,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });

    // Generate and add reflection prompts after a short delay
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _addReflectionPrompts();
      }
    });
  }

  void _addReflectionPrompts() {
    final prompts = ReflectionEngine.generateReflectionPrompts(widget.entry);
    
    for (final prompt in prompts) {
      Future.delayed(Duration(milliseconds: prompts.indexOf(prompt) * 600), () {
        if (mounted) {
          setState(() {
            _messages.add(ChatMessage(
              text: prompt,
              isUser: false,
              timestamp: DateTime.now(),
            ));
          });
          _scrollToBottom();
        }
      });
    }

    // Add similar entries after all prompts
    Future.delayed(Duration(milliseconds: prompts.length * 600 + 1000), () {
      if (mounted) {
        _addSimilarEntries();
      }
    });
  }

  void _addSimilarEntries() async {
    try {
      final similarEntries = await _similarityService.findSimilarEntries(widget.entry);
      
      if (similarEntries.isNotEmpty) {
        final similarEntriesMessage = _similarityService.generateSimilarEntriesMessage(similarEntries);
        
        setState(() {
          _messages.add(ChatMessage(
            text: similarEntriesMessage,
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
        _scrollToBottom();
      }
    } catch (e) {
      // Silently fail if similarity search fails
      print('Error finding similar entries: $e');
    }
  }

  String _generateContextualResponse() {
    final mood = widget.entry.mood.label.toLowerCase();
    final content = widget.entry.text;
    
    switch (mood) {
      case 'happy':
        return "I can see you're feeling happy! 🌟 What specific moments brought you joy today?";
      case 'sad':
        return "I hear you're feeling sad. 💙 It's brave to acknowledge these emotions. What's on your mind?";
      case 'stressed':
        return "I sense you're stressed. 🌿 Take a deep breath. What's weighing on you?";
      case 'calm':
        return "You're feeling calm - that's wonderful! 🌊 What helped you find this peace?";
      case 'excited':
        return "Your excitement is contagious! 🎆 What are you looking forward to?";
      default:
        return "Thank you for sharing this moment with me. 🌱 How are you feeling about this entry?";
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isTyping = true;
    });

    _messageController.clear();
    _scrollToBottom();

    // Simulate AI response
    Future.delayed(const Duration(seconds: 1, milliseconds: 500), () {
      if (mounted) {
        _generateAssistantResponse(text);
      }
    });
  }

  void _generateAssistantResponse(String userMessage) {
    setState(() {
      _isTyping = true;
    });

    // Simulate AI response with delay
    Future.delayed(const Duration(seconds: 1, milliseconds: 500), () {
      if (mounted) {
        final response = ReflectionEngine.generateContextualResponse(userMessage, widget.entry);
        
        setState(() {
          _messages.add(ChatMessage(
            text: response,
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isTyping = false;
        });

        _scrollToBottom();
      }
    });
  }

  String _generateContextualReply(String userMessage) {
    final lowerMessage = userMessage.toLowerCase();
    
    if (lowerMessage.contains('help') || lowerMessage.contains('advice')) {
      return "I'm here to support you. Remember that you have the strength within to navigate this. What specific aspect would you like to explore?";
    } else if (lowerMessage.contains('feel') || lowerMessage.contains('feeling')) {
      return "Your feelings are valid. Acknowledging them is the first step. How does it feel to express this?";
    } else if (lowerMessage.contains('why') || lowerMessage.contains('reason')) {
      return "Understanding 'why' is a journey. Sometimes the answer comes through patience. What insights are you discovering?";
    } else if (lowerMessage.contains('thank') || lowerMessage.contains('thanks')) {
      return "You're welcome! 🌟 I'm here to help you reflect. What else would you like to explore about this entry?";
    } else {
      return "Thank you for sharing that with me. Your willingness to reflect shows great self-awareness. What other thoughts are coming up?";
    }
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
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Reflection Chat'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Original Journal Entry Section
          _buildJournalEntrySection(),
          
          // Chat Messages Section
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // Chat Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: Icon(
                            Icons.psychology,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Reflection Assistant',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Here to help you reflect',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                  
                  // Message Input Area
                  _buildMessageInput(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJournalEntrySection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with mood and date
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.entry.mood.emoji,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.entry.mood.label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                widget.entry.formattedDate,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Entry content
          Text(
            widget.entry.text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: _isTyping ? 'AI is thinking...' : 'Share your thoughts...',
                  border: InputBorder.none,
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceVariant,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  hintStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                enabled: !_isTyping,
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: Container(
                decoration: BoxDecoration(
                  color: _isTyping 
                      ? Theme.of(context).colorScheme.surfaceVariant
                      : Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: _isTyping ? null : _sendMessage,
                  icon: _isTyping
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        )
                      : const Icon(Icons.send),
                  color: _isTyping
                      ? Theme.of(context).colorScheme.onSurfaceVariant
                      : Theme.of(context).colorScheme.onPrimary,
                ),
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
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isUser;

  const _MessageBubble({
    super.key,
    required this.message,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Icon(
                Icons.psychology,
                size: 18,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: Container(
              decoration: BoxDecoration(
                color: isUser
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomLeft: isUser ? 20 : 4,
                  bottomRight: isUser ? 4 : 20,
                  topLeft: isUser ? 20 : 4,
                  topRight: isUser ? 4 : 20,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isUser
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ),
          
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.person,
                size: 18,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Icon(
              Icons.psychology,
              size: 18,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(20).copyWith(
                bottomRight: 4,
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Dot(delay: 0),
                const SizedBox(width: 4),
                _Dot(delay: 200),
                const SizedBox(width: 4),
                _Dot(delay: 400),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final int delay;

  const _Dot({required this.delay});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(_animation.value),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
