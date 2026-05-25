import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hyphen/managers/chat_manager.dart';
import 'package:hyphen/managers/auth_manager.dart';
import 'package:hyphen/screens/login_page.dart';

class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = AuthManager();
      if (auth.isLoggedIn) {
        ChatManager().initSocket();
        ChatManager().fetchRooms();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(timeStr).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inDays == 0) {
        final hour = dt.hour.toString().padLeft(2, '0');
        final minute = dt.minute.toString().padLeft(2, '0');
        return '$hour:$minute';
      } else if (diff.inDays == 1) {
        return 'Kemarin';
      } else if (diff.inDays < 7) {
        final weekdays = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
        return weekdays[dt.weekday - 1];
      } else {
        final months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 
          'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
        ];
        return '${dt.day} ${months[dt.month - 1]}';
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Segmented Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F6F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.black54,
                  labelStyle: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  tabs: const [
                    Tab(text: 'Chats'),
                    Tab(text: 'Notifications'),
                  ],
                ),
              ),
            ),

            // Tab View Body
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildChatsTab(context),
                  _buildNotificationsTab(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatsTab(BuildContext context) {
    const Color brandBrown = Color(0xFF8C7355);
    final auth = AuthManager();

    if (!auth.isLoggedIn) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 80,
                width: 80,
                decoration: const BoxDecoration(
                  color: Color(0xFFF6F6F6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline, size: 36, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Text(
                'Belum Masuk Akun',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Silakan login terlebih dahulu untuk mengakses kotak masuk dan fitur pesan.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.black54,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  ).then((_) {
                    setState(() {});
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Masuk Sekarang',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListenableBuilder(
      listenable: ChatManager(),
      builder: (context, child) {
        final rooms = ChatManager().rooms;

        if (ChatManager().isLoadingRooms) {
          return const Center(
            child: CircularProgressIndicator(color: brandBrown),
          );
        }

        if (rooms.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 80,
                    width: 80,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF6F6F6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.chat_bubble_outline, size: 36, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Belum Ada Chat',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Anda belum memiliki obrolan aktif. Cari produk yang Anda minati lalu hubungi penjual!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.black54,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          itemCount: rooms.length,
          separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F1F1)),
          itemBuilder: (context, index) {
            final room = rooms[index];
            final String name = room['otherUsername'] ?? 'User';
            final String lastMsg = room['lastMessage'] ?? 'Mulai percakapan baru';
            final String timeStr = _formatTime(room['lastMessageAt'] ?? room['createdAt']);
            final int unreadCount = room['unreadCount'] ?? 0;
            final bool hasUnread = unreadCount > 0;
            final String? photoUrl = room['otherPhotoUrl'];

            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatDetailPage(
                      roomId: room['id'],
                      name: name,
                      avatarUrl: photoUrl,
                      productName: room['productName'],
                      productPrice: room['productPrice'] != null
                          ? double.tryParse(room['productPrice'].toString())
                          : null,
                      productImageUrl: room['productImageUrl'],
                    ),
                  ),
                ).then((_) {
                  // Refresh rooms to reset unread count when returning
                  ChatManager().fetchRooms();
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14.0),
                child: Row(
                  children: [
                    // Avatar
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: const Color(0xFFF6F6F6),
                      backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                          ? NetworkImage(photoUrl)
                          : null,
                      child: (photoUrl == null || photoUrl.isEmpty)
                          ? Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'U',
                              style: GoogleFonts.plusJakartaSans(
                                color: brandBrown,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),

                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                              fontSize: 15,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            lastMsg,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              color: hasUnread ? Colors.black87 : Colors.black45,
                              fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Time and Unread Dot
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          timeStr,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.black38,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (hasUnread)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: brandBrown,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )
                        else
                          const SizedBox(height: 16),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNotificationsTab(BuildContext context) {
    final List<Map<String, dynamic>> mockNotifications = [
      {
        'icon': Icons.local_shipping_outlined,
        'title': 'Pesanan Telah Dikirim!',
        'body': 'Paket dengan nomor resi HP-982183 sudah diserahkan ke kurir.',
        'time': '2 jam yang lalu',
        'isPromo': false,
      },
      {
        'icon': Icons.sell_outlined,
        'title': 'Price Drop Alert!',
        'body': 'Barang vintage dari keranjang belanja Anda turun harga sebesar 10%!',
        'time': '5 jam yang lalu',
        'isPromo': false,
      },
      {
        'icon': Icons.card_giftcard_outlined,
        'title': 'Voucher Premium Gratis',
        'body': 'Dapatkan diskon ongkir hingga Rp 20.000 dengan kode voucher HYPENSHIP.',
        'time': '1 hari yang lalu',
        'isPromo': true,
      },
      {
        'icon': Icons.check_circle_outline,
        'title': 'Verifikasi Berhasil',
        'body': 'Produk Vintage Knitwear Sweater Anda telah disetujui untuk dijual.',
        'time': '3 hari yang lalu',
        'isPromo': false,
      },
    ];

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      itemCount: mockNotifications.length,
      separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F1F1)),
      itemBuilder: (context, index) {
        final notif = mockNotifications[index];
        const Color brandBrown = Color(0xFF8C7355);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 14.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: notif['isPromo'] ? brandBrown.withOpacity(0.08) : const Color(0xFFF6F6F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  notif['icon'],
                  color: notif['isPromo'] ? brandBrown : Colors.black87,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notif['title'],
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notif['body'],
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.black54,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notif['time'],
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.black38,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ChatDetailPage extends StatefulWidget {
  final String roomId;
  final String name;
  final String? avatarUrl;
  final String? productName;
  final double? productPrice;
  final String? productImageUrl;

  const ChatDetailPage({
    super.key,
    required this.roomId,
    required this.name,
    this.avatarUrl,
    this.productName,
    this.productPrice,
    this.productImageUrl,
  });

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatManager = ChatManager();
      chatManager.initSocket();
      chatManager.joinRoom(widget.roomId);
      chatManager.fetchMessages(widget.roomId);
      chatManager.markMessagesRead(widget.roomId, AuthManager().userId);
    });
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    ChatManager().leaveRoom();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _sendMessage() {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    final currentUserId = AuthManager().userId;
    ChatManager().sendMessage(widget.roomId, currentUserId, text);

    _msgController.clear();
    _scrollToBottom();
  }

  String _formatRupiah(double price) {
    final buffer = StringBuffer('Rp ');
    final priceStr = price.toInt().toString();
    final len = priceStr.length;
    for (int i = 0; i < len; i++) {
      buffer.write(priceStr[i]);
      if ((len - i - 1) % 3 == 0 && i != len - 1) {
        buffer.write('.');
      }
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    const Color brandBrown = Color(0xFF8C7355);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFF6F6F6),
              backgroundImage: (widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty)
                  ? NetworkImage(widget.avatarUrl!)
                  : null,
              child: (widget.avatarUrl == null || widget.avatarUrl!.isEmpty)
                  ? Text(
                      widget.name.isNotEmpty ? widget.name[0].toUpperCase() : 'U',
                      style: GoogleFonts.plusJakartaSans(
                        color: brandBrown,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.name,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Online',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.green,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Premium Product Info Bar
          if (widget.productName != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9F9),
                border: Border(
                  bottom: BorderSide(color: Colors.grey.withOpacity(0.15)),
                ),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: widget.productImageUrl != null && widget.productImageUrl!.isNotEmpty
                        ? (widget.productImageUrl!.startsWith('http')
                            ? Image.network(widget.productImageUrl!, width: 44, height: 44, fit: BoxFit.cover)
                            : Image.asset(widget.productImageUrl!, width: 44, height: 44, fit: BoxFit.cover))
                        : Container(width: 44, height: 44, color: Colors.grey[200]),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.productName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.productPrice != null ? _formatRupiah(widget.productPrice!) : '',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: brandBrown,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Message List
          Expanded(
            child: ListenableBuilder(
              listenable: ChatManager(),
              builder: (context, child) {
                final messages = ChatManager().messages;

                // Scroll to bottom on new messages
                if (messages.isNotEmpty) {
                  _scrollToBottom();
                }

                if (ChatManager().isLoadingMessages) {
                  return const Center(child: CircularProgressIndicator(color: brandBrown));
                }

                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'Belum ada pesan. Mulai obrolan sekarang!',
                      style: GoogleFonts.plusJakartaSans(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg['senderId'] == AuthManager().userId;

                    String time = '';
                    if (msg['createdAt'] != null) {
                      try {
                        final dt = DateTime.parse(msg['createdAt']).toLocal();
                        final hour = dt.hour.toString().padLeft(2, '0');
                        final minute = dt.minute.toString().padLeft(2, '0');
                        time = '$hour:$minute';
                      } catch (_) {}
                    }

                    return _buildMessageBubble(msg['message'] ?? '', isMe, time);
                  },
                );
              },
            ),
          ),

          // Bottom Send Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey.withOpacity(0.2)),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Attachment Icon
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: Colors.black54),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Attachments is pending backend.')),
                      );
                    },
                  ),

                  // Message Input Field
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F6F6),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _msgController,
                        style: GoogleFonts.plusJakartaSans(color: Colors.black, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Type your message...',
                          hintStyle: GoogleFonts.plusJakartaSans(color: Colors.black38, fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Send Action Button
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: brandBrown,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isMe, String time) {
    const Color brandBrown = Color(0xFF8C7355);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints: const BoxConstraints(maxWidth: 260),
            decoration: BoxDecoration(
              color: isMe ? brandBrown : const Color(0xFFF1F1F1),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 0),
                bottomRight: Radius.circular(isMe ? 0 : 16),
              ),
            ),
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
            child: Text(
              time,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.black38,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
