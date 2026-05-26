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
      backgroundColor: const Color(0xFFFAFBFD),
      body: SafeArea(
        child: Column(
          children: [
            // Custom Segmented Header (iOS / macOS Style Pill)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Container(
                height: 48,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEEEEE),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TabBar(
                  controller: _tabController,
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorPadding: EdgeInsets.zero,
                  indicator: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
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
    return ListenableBuilder(
      listenable: AuthManager(),
      builder: (context, child) {
        final auth = AuthManager();

        if (!auth.isLoggedIn) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 90,
                    width: 90,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.lock_outline, size: 40, color: brandBrown),
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
                  const SizedBox(height: 28),
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
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
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
                        height: 90,
                        width: 90,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.chat_bubble_outline, size: 40, color: brandBrown),
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

            return ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              itemCount: rooms.length,
              itemBuilder: (context, index) {
                final room = rooms[index];
                final String name = room['otherUsername'] ?? 'User';
                final String lastMsg = room['lastMessage'] ?? 'Mulai percakapan baru';
                final String timeStr = _formatTime(room['lastMessageAt'] ?? room['createdAt']);
                final int unreadCount = room['unreadCount'] ?? 0;
                final bool hasUnread = unreadCount > 0;
                final String? photoUrl = room['otherPhotoUrl'];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.015),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                    border: Border.all(color: const Color(0xFFF1F3F7)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
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
                            ChatManager().fetchRooms();
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                          child: Row(
                            children: [
                              // Avatar with Online dot status indicator
                              Stack(
                                children: [
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
                                  Positioned(
                                    right: 1,
                                    bottom: 1,
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF4CAF50),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                    ),
                                  ),
                                ],
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
                                        fontWeight: hasUnread ? FontWeight.bold : FontWeight.w700,
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
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: brandBrown,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 18,
                                        minHeight: 18,
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
                                    const SizedBox(height: 18),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
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

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemCount: mockNotifications.length,
      itemBuilder: (context, index) {
        final notif = mockNotifications[index];
        const Color brandBrown = Color(0xFF8C7355);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.015),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(color: const Color(0xFFF1F3F7)),
          ),
          padding: const EdgeInsets.all(16.0),
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
                    const SizedBox(height: 6),
                    Text(
                      notif['body'],
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.black54,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
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
      backgroundColor: const Color(0xFFF5F6F9),
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
          // Premium Product Info Bar (Floating card design)
          if (widget.productName != null)
            Container(
              margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(color: const Color(0xFFEAEAEA)),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: widget.productImageUrl != null && widget.productImageUrl!.isNotEmpty
                        ? (widget.productImageUrl!.startsWith('http')
                            ? Image.network(widget.productImageUrl!, width: 40, height: 40, fit: BoxFit.cover)
                            : Image.asset(widget.productImageUrl!, width: 40, height: 40, fit: BoxFit.cover))
                        : Container(width: 40, height: 40, color: Colors.grey[200]),
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
                        const SizedBox(height: 3),
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

          // Negotiation Bar
          ListenableBuilder(
            listenable: ChatManager(),
            builder: (context, child) {
              return _buildNegotiationBar(context, ChatManager().activeRoom, brandBrown);
            },
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
                top: BorderSide(color: Colors.grey.withOpacity(0.15)),
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
                        color: const Color(0xFFF4F5F7),
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
    if (text.contains('mengajukan penawaran harga baru:') ||
        text.contains('menyetujui penawaran harga:') ||
        text.contains('menolak penawaran harga:')) {
      return Align(
        alignment: Alignment.center,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF0EAE1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5DAC9)),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF7A654D),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

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
              color: isMe ? brandBrown : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 16),
              ),
              boxShadow: isMe
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
              border: isMe ? null : Border.all(color: const Color(0xFFECECEC)),
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
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
            child: Text(
              time,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.black38,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildNegotiationBar(BuildContext context, Map<String, dynamic>? chatRoom, Color brandBrown) {
    if (chatRoom == null) return const SizedBox.shrink();

    final currentUserId = AuthManager().userId;
    final isBuyer = currentUserId == chatRoom['buyerId']?.toString() || currentUserId == chatRoom['buyerId'];
    final isSeller = currentUserId == chatRoom['sellerId']?.toString() || currentUserId == chatRoom['sellerId'];
    final status = chatRoom['negotiationStatus'];
    final proposedBy = chatRoom['proposedBy'];
    
    double? price;
    if (chatRoom['proposedPrice'] != null) {
      price = double.tryParse(chatRoom['proposedPrice'].toString());
    }

    if (status == null) {
      if (isBuyer) {
        return _buildNegotiationCard(
          context: context,
          text: 'Nego harga untuk produk ini?',
          actionWidgets: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: brandBrown,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => _showProposePriceDialog(context),
              child: const Text('Tawar Harga', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      }
      return const SizedBox.shrink();
    }

    if (status == 'accepted') {
      return _buildNegotiationCard(
        context: context,
        text: ' Penawaran disetujui: ${_formatRupiah(price!)}',
        subText: isBuyer ? 'Harga ini akan otomatis diterapkan saat Anda checkout!' : 'Pembeli akan checkout dengan harga ini.',
        actionWidgets: const [],
        color: Colors.green.shade50,
        textColor: Colors.green.shade800,
      );
    }

    if (status == 'rejected') {
      if (isSeller) {
        final title = proposedBy == 'buyer'
            ? ' Anda menolak penawaran pembeli'
            : ' Penawaran Anda ditolak oleh pembeli';
        return _buildNegotiationCard(
          context: context,
          text: title,
          subText: 'Silakan ubah harga penawaran untuk melanjutkan.',
          color: Colors.red.shade50,
          textColor: Colors.red.shade800,
          actionWidgets: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: brandBrown,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => _showProposePriceDialog(context),
              child: const Text('Ubah Harga', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      }
      final title = proposedBy == 'buyer'
          ? ' Penawaran Anda ditolak oleh penjual'
          : ' Anda menolak penawaran penjual';
      return _buildNegotiationCard(
        context: context,
        text: title,
        subText: 'Menunggu penjual mengubah harga...',
        color: Colors.red.shade50,
        textColor: Colors.red.shade800,
        actionWidgets: const [],
      );
    }

    if (status == 'pending') {
      if (proposedBy == 'buyer') {
        if (isBuyer) {
          return _buildNegotiationCard(
            context: context,
            text: ' Menunggu respon penjual',
            subText: 'Tawaran Anda: ${_formatRupiah(price!)}',
            color: Colors.amber.shade50,
            textColor: Colors.amber.shade800,
            actionWidgets: const [],
          );
        }
        return _buildNegotiationCard(
          context: context,
          text: ' Tawaran baru dari pembeli: ${_formatRupiah(price!)}',
          color: Colors.amber.shade50,
          textColor: Colors.amber.shade800,
          actionWidgets: [
            TextButton(
              onPressed: () => ChatManager().respondNegotiation(widget.roomId, 'reject'),
              child: const Text('Tolak', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent.shade100,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => _showProposePriceDialog(context),
              child: const Text('Ubah / Counter', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => ChatManager().respondNegotiation(widget.roomId, 'accept'),
              child: const Text('Setuju', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      } else if (proposedBy == 'seller') {
        if (isSeller) {
          return _buildNegotiationCard(
            context: context,
            text: ' Menunggu respon pembeli',
            subText: 'Tawaran Anda: ${_formatRupiah(price!)}',
            color: Colors.amber.shade50,
            textColor: Colors.amber.shade800,
            actionWidgets: const [],
          );
        }
        return _buildNegotiationCard(
          context: context,
          text: ' Penawaran baru dari penjual: ${_formatRupiah(price!)}',
          color: Colors.amber.shade50,
          textColor: Colors.amber.shade800,
          actionWidgets: [
            TextButton(
              onPressed: () => ChatManager().respondNegotiation(widget.roomId, 'reject'),
              child: const Text('Tolak', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => ChatManager().respondNegotiation(widget.roomId, 'accept'),
              child: const Text('Setuju', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      }
    }

    return const SizedBox.shrink();
  }

  Widget _buildNegotiationCard({
    required BuildContext context,
    required String text,
    String? subText,
    required List<Widget> actionWidgets,
    Color? color,
    Color? textColor,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
        border: Border.all(color: color != null ? color.withOpacity(0.5) : const Color(0xFFEAEAEA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: textColor ?? Colors.black87,
                      ),
                    ),
                    if (subText != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subText,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                          color: textColor?.withOpacity(0.7) ?? Colors.black54,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (actionWidgets.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: actionWidgets,
            ),
          ],
        ],
      ),
    );
  }

  void _showProposePriceDialog(BuildContext context) {
    final chatRoom = ChatManager().activeRoom;
    double? existingPrice;
    if (chatRoom != null && chatRoom['proposedPrice'] != null) {
      existingPrice = double.tryParse(chatRoom['proposedPrice'].toString());
    }
    final initialValue = existingPrice ?? widget.productPrice;
    final controller = TextEditingController(
      text: initialValue != null ? initialValue.toInt().toString() : '',
    );
    if (controller.text.isNotEmpty) {
      controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: controller.text.length,
      );
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          'Tawar Harga (Rp)',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: GoogleFonts.plusJakartaSans(color: Colors.black),
          decoration: const InputDecoration(
            hintText: 'cth. 200000',
            hintStyle: TextStyle(color: Colors.black38),
            prefixText: 'Rp ',
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.black26),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.black),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: GoogleFonts.plusJakartaSans(color: Colors.black54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
            onPressed: () {
              final parsed = double.tryParse(controller.text);
              if (parsed != null && parsed > 0) {
                ChatManager().proposePrice(widget.roomId, parsed);
              }
              Navigator.pop(context);
            },
            child: Text(
              'Kirim',
              style: GoogleFonts.plusJakartaSans(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
