import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/invoice_provider.dart';
import '../../core/widgets/app_drawer.dart';
import '../../services/ai_service.dart';

class AiMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<AiAction>? actions;
  final Widget? customWidget;

  AiMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.actions,
    this.customWidget,
  }) : timestamp = timestamp ?? DateTime.now();
}

class AiAction {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  AiAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });
}

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<AiMessage> _messages = [];
  bool _isProcessing = false;
  late final AiService _aiService;

  final List<String> _quickPrompts = [
    'Which products are low in stock?',
    'What were today\'s sales and GST?',
    'What are my top-selling items?',
    'Which products should I reorder?',
    'What is the forecasted demand?',
  ];

  @override
  void initState() {
    super.initState();
    _aiService = AiService();
    _messages.add(
      AiMessage(
        text: 'Hello! I am your INVENTRA AI Assistant.\n\n'
            'I analyze your real-time inventory, sales transactions, GST calculations, '
            'and demand forecasting models to provide actionable shop intelligence.\n\n'
            'How can I assist your business today?',
        isUser: false,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
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

  void _handleSend([String? presetText]) {
    final query = (presetText ?? _controller.text).trim();
    if (query.isEmpty || _isProcessing) return;

    if (presetText == null) {
      _controller.clear();
    }

    setState(() {
      _messages.add(AiMessage(text: query, isUser: true));
      _isProcessing = true;
    });
    _scrollToBottom();

    // Process answer using Gemini AI and real shop data
    _processAiResponse(query);
  }

  Future<void> _processAiResponse(String query) async {
    final responseText = await _aiService.askQuestion(
      query: query,
      productProvider: context.read<ProductProvider>(),
      analyticsProvider: context.read<AnalyticsProvider>(),
      invoiceProvider: context.read<InvoiceProvider>(),
      customerProvider: context.read<CustomerProvider>(),
    );
    
    if (!mounted) return;
    
    setState(() {
      _messages.add(AiMessage(text: responseText, isUser: false));
      _isProcessing = false;
    });
    _scrollToBottom();
  }



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.psychology, color: Colors.orange, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'INVENTRA AI',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        elevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: Icon(Icons.menu, color: theme.colorScheme.onSurface),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
      ),
      body: Column(
        children: [
          // Quick suggestion chips
          Container(
            height: 52,
            margin: const EdgeInsets.only(top: 8),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _quickPrompts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final prompt = _quickPrompts[index];
                return ActionChip(
                  label: Text(
                    prompt,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  backgroundColor: theme.colorScheme.primary.withAlpha(15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: theme.colorScheme.primary.withAlpha(50)),
                  ),
                  onPressed: () => _handleSend(prompt),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Divider(height: 1, color: theme.dividerTheme.color ?? Colors.grey.shade200),

          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(24),
              itemCount: _messages.length + (_isProcessing ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return _buildTypingIndicator(theme);
                }
                final msg = _messages[index];
                return _buildMessageBubble(msg, theme);
              },
            ),
          ),

          // Input text bar
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(5),
                  offset: const Offset(0, -4),
                  blurRadius: 16,
                )
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Ask INVENTRA AI...',
                      hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                    ),
                    onSubmitted: (_) => _handleSend(),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _isProcessing ? null : () => _handleSend(),
                    icon: const Icon(Icons.send_rounded, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(AiMessage msg, ThemeData theme) {
    final isUser = msg.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.orange, size: 20),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser
                        ? theme.colorScheme.primary
                        : theme.cardTheme.color,
                    border: isUser ? null : Border.all(color: theme.dividerTheme.color ?? Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(16).copyWith(
                      bottomRight: isUser ? const Radius.circular(4) : null,
                      bottomLeft: !isUser ? const Radius.circular(4) : null,
                      topLeft: !isUser ? const Radius.circular(4) : null,
                      topRight: isUser ? const Radius.circular(4) : null,
                    ),
                  ),
                  child: Text(
                    msg.text,
                    style: TextStyle(
                      color: isUser ? Colors.white : theme.colorScheme.onSurface,
                      fontSize: 14,
                      height: 1.5,
                      fontWeight: isUser ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ),
                if (msg.actions != null && msg.actions!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: msg.actions!.map((act) {
                      return OutlinedButton.icon(
                        onPressed: act.onTap,
                        icon: Icon(act.icon, size: 16),
                        label: Text(act.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.person, size: 20, color: theme.colorScheme.primary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.orange, size: 20),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              border: Border.all(color: theme.dividerTheme.color ?? Colors.grey.shade200),
              borderRadius: BorderRadius.circular(16).copyWith(
                topLeft: const Radius.circular(4),
                bottomLeft: const Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'INVENTRA AI is analyzing...',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
