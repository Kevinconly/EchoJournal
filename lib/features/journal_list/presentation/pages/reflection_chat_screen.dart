import 'dart:async';
import 'package:material_ui/material_ui.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../journal_entry/domain/entities/journal_entry.dart';
import '../../../reflection/domain/entities/reflection_message.dart';
import '../../../reflection/domain/services/reflection_coordinator.dart';

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
  late final ReflectionCoordinator _coordinator;
  StreamSubscription? _messagesSub;
  StreamSubscription? _processingSub;
  List<ReflectionMessage> _messages = [];
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _coordinator = ReflectionCoordinator(
      currentEntry: widget.entry,
      repository: ServiceLocator.journalRepository,
    );

    _messagesSub = _coordinator.messagesStream.listen((messages) {
      if (mounted) {
        setState(() {
          _messages = messages;
        });
        _scrollToBottom();
      }
    });

    _processingSub = _coordinator.isProcessingStream.listen((processing) {
      if (mounted) {
        setState(() {
          _isProcessing = processing;
        });
        _scrollToBottom();
      }
    });

    _coordinator.initializeSession();
  }

  @override
  void dispose() {
    _messagesSub?.cancel();
    _processingSub?.cancel();
    _coordinator.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutQuad,
        );
      }
    });
  }

  void _sendMessage([String? textToSend]) {
    final text = textToSend ?? _messageController.text;
    if (text.trim().isEmpty || _isProcessing) return;

    if (textToSend == null) {
      _messageController.clear();
    }
    _coordinator.sendUserMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final moodColor = AppTheme.getMoodColor(widget.entry.mood.label);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reflection Space'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Original Entry Header Banner
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: moodColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.entry.mood.emoji} ${widget.entry.mood.label}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: moodColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.entry.text.replaceAll('\n', ' '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Message Stream List
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return _buildMessageItem(message, theme);
                },
              ),
            ),

            // Processing indicator
            if (_isProcessing)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Formulating thoughtful reflection...',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),

            // Input Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: 'Share a reflection or answer a question...',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerLow,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _isProcessing ? null : () => _sendMessage(),
                    icon: const Icon(Icons.arrow_upward, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
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

  Widget _buildMessageItem(ReflectionMessage message, ThemeData theme) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Origin badge
          Padding(
            padding: const EdgeInsets.only(bottom: 4, left: 4, right: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isUser) ...[
                  Icon(
                    message.source == ReflectionSource.memoryRetrieval
                        ? Icons.history
                        : Icons.psychology_outlined,
                    size: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  message.sourceLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // Message bubble
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.82,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isUser
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isUser ? 16 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 16),
              ),
              border: isUser
                  ? null
                  : Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Text(
              message.text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isUser
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
                height: 1.5,
              ),
            ),
          ),

          // Suggested follow-up prompt chips
          if (message.suggestedFollowUps.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: message.suggestedFollowUps.map((q) {
                return ActionChip(
                  label: Text(q),
                  onPressed: () => _sendMessage(q),
                  backgroundColor: theme.colorScheme.surfaceContainerLowest,
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
