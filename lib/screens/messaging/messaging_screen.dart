import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/delivery.dart';
import '../../models/message.dart';
import '../../providers/messaging_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/delivery_detail_provider.dart';
import '../../theme/app_theme.dart';

class MessagingScreen extends StatefulWidget {
  final Delivery delivery;

  const MessagingScreen({
    super.key,
    required this.delivery,
  });

  @override
  State<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _showQuickReplies = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeMessaging();
    });
  }

  void _initializeMessaging() {
    final auth = context.read<AuthProvider>();
    final driverId = auth.currentUser?.id ?? '';
    context.read<MessagingProvider>().initializeForDelivery(
      widget.delivery.id,
      driverId,
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.delivery.customerName,
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'Order #${widget.delivery.orderId.substring(0, 8)}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () => _callCustomer(),
            tooltip: 'Call customer',
          ),
        ],
      ),
      body: Column(
        children: [
          // Customer info banner
          _buildCustomerBanner(),

          // Messages list
          Expanded(
            child: Consumer<MessagingProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.messages.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryGreen),
                  );
                }

                if (provider.messages.isEmpty) {
                  return _buildEmptyState();
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingM,
                    vertical: AppTheme.spacingS,
                  ),
                  itemCount: provider.messages.length,
                  itemBuilder: (context, index) {
                    final message = provider.messages[index];
                    final showDate = index == 0 ||
                        !_isSameDay(
                          provider.messages[index - 1].createdAt,
                          message.createdAt,
                        );
                    return Column(
                      children: [
                        if (showDate) _buildDateDivider(message.createdAt),
                        _buildMessageBubble(message),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Quick replies
          if (_showQuickReplies) _buildQuickReplies(),

          // Message input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildCustomerBanner() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.iconBackground,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                widget.delivery.customerName[0].toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.delivery.customerName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                Text(
                  widget.delivery.deliveryAddress,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              'No messages yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              'Send a message or use quick replies\nto communicate with the customer',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),
            OutlinedButton.icon(
              onPressed: () {
                setState(() => _showQuickReplies = true);
              },
              icon: const Icon(Icons.flash_on),
              label: const Text('View Quick Replies'),
              style: AppTheme.outlinedButtonStyle,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateDivider(DateTime date) {
    String label;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      label = 'Today';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      label = 'Yesterday';
    } else {
      label = DateFormat.MMMd().format(date);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey[300])),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey[300])),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message) {
    final isFromDriver = message.isFromDriver;
    final time = DateFormat.jm().format(message.createdAt);

    return Align(
      alignment: isFromDriver ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingM,
          vertical: AppTheme.spacingS,
        ),
        decoration: BoxDecoration(
          color: isFromDriver ? AppTheme.primaryGreen : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isFromDriver ? 16 : 4),
            bottomRight: Radius.circular(isFromDriver ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Message type indicator
            if (message.type != MessageType.text) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getMessageTypeIcon(message.type),
                    size: 12,
                    color: isFromDriver
                        ? Colors.white.withValues(alpha: 0.7)
                        : Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _getMessageTypeLabel(message.type),
                    style: TextStyle(
                      fontSize: 10,
                      color: isFromDriver
                          ? Colors.white.withValues(alpha: 0.7)
                          : Colors.grey[500],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
            Text(
              message.content,
              style: TextStyle(
                color: isFromDriver ? Colors.white : Colors.black87,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                fontSize: 11,
                color: isFromDriver
                    ? Colors.white.withValues(alpha: 0.7)
                    : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getMessageTypeIcon(MessageType type) {
    switch (type) {
      case MessageType.quickReply:
        return Icons.flash_on;
      case MessageType.locationUpdate:
        return Icons.location_on;
      case MessageType.etaUpdate:
        return Icons.timer;
      case MessageType.statusUpdate:
        return Icons.update;
      default:
        return Icons.message;
    }
  }

  String _getMessageTypeLabel(MessageType type) {
    switch (type) {
      case MessageType.quickReply:
        return 'Quick Reply';
      case MessageType.locationUpdate:
        return 'Location Update';
      case MessageType.etaUpdate:
        return 'ETA Update';
      case MessageType.statusUpdate:
        return 'Status Update';
      default:
        return '';
    }
  }

  Widget _buildQuickReplies() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quick Replies',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                  fontSize: 13,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => setState(() => _showQuickReplies = false),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingS),
          Wrap(
            spacing: AppTheme.spacingS,
            runSpacing: AppTheme.spacingS,
            children: QuickReply.driverQuickReplies.map((quickReply) {
              return _buildQuickReplyChip(quickReply);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickReplyChip(QuickReply quickReply) {
    return Consumer<MessagingProvider>(
      builder: (context, provider, child) {
        return ActionChip(
          avatar: Icon(
            _getQuickReplyIcon(quickReply.icon),
            size: 16,
            color: AppTheme.primaryGreen,
          ),
          label: Text(
            quickReply.message.length > 30
                ? '${quickReply.message.substring(0, 30)}...'
                : quickReply.message,
            style: const TextStyle(fontSize: 12),
          ),
          backgroundColor: Colors.white,
          side: BorderSide(color: Colors.grey[300]!),
          onPressed: provider.isSending
              ? null
              : () async {
                  final success = await provider.sendQuickReply(quickReply);
                  if (success && mounted) {
                    setState(() => _showQuickReplies = false);
                    _scrollToBottom();
                  }
                },
        );
      },
    );
  }

  IconData _getQuickReplyIcon(IconType iconType) {
    switch (iconType) {
      case IconType.directions:
        return Icons.directions;
      case IconType.timer:
        return Icons.timer;
      case IconType.location:
        return Icons.location_on;
      case IconType.help:
        return Icons.help_outline;
      case IconType.warning:
        return Icons.warning_amber;
      case IconType.phone:
        return Icons.phone;
    }
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.only(
        left: AppTheme.spacingM,
        right: AppTheme.spacingM,
        top: AppTheme.spacingS,
        bottom: MediaQuery.of(context).padding.bottom + AppTheme.spacingS,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          // Quick reply toggle
          IconButton(
            icon: Icon(
              _showQuickReplies ? Icons.flash_off : Icons.flash_on,
              color: _showQuickReplies ? AppTheme.primaryGreen : Colors.grey[600],
            ),
            onPressed: () {
              setState(() => _showQuickReplies = !_showQuickReplies);
            },
            tooltip: 'Quick replies',
          ),

          // Text field
          Expanded(
            child: TextField(
              controller: _messageController,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingM,
                  vertical: AppTheme.spacingS,
                ),
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 4,
              minLines: 1,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),

          const SizedBox(width: AppTheme.spacingS),

          // Send button
          Consumer<MessagingProvider>(
            builder: (context, provider, child) {
              return IconButton(
                icon: provider.isSending
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primaryGreen,
                        ),
                      )
                    : const Icon(Icons.send, color: AppTheme.primaryGreen),
                onPressed: provider.isSending ? null : _sendMessage,
              );
            },
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final provider = context.read<MessagingProvider>();
    final success = await provider.sendMessage(text);

    if (success && mounted) {
      _messageController.clear();
      _scrollToBottom();
    }
  }

  void _callCustomer() {
    context.read<DeliveryDetailProvider>().callCustomer(
      widget.delivery.customerPhone,
    );
  }
}
