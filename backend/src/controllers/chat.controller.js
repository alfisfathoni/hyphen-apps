const { v4: uuidv4 } = require('uuid');
const db = require('@/config/db');
const { getIo } = require('@/config/socket');
const cloudinary = require('@/config/cloudinary');


const getRoomWithDetails = async (roomId, currentUserId) => {
    const [rooms] = await db.query(
        `SELECT cr.*, 
            u.username AS otherUsername,
            up.fullname AS otherFullname,
            up.photoUrl AS otherPhotoUrl,
            p.name AS productName,
            p.imageUrl AS productImageUrl,
            p.price AS productPrice,
            (SELECT cm.message FROM chat_messages cm 
             WHERE cm.roomId = cr.id 
             ORDER BY cm.createdAt DESC LIMIT 1) as lastMessage,
            (SELECT cm.createdAt FROM chat_messages cm 
             WHERE cm.roomId = cr.id 
             ORDER BY cm.createdAt DESC LIMIT 1) as lastMessageAt,
            (SELECT COUNT(*) FROM chat_messages cm 
             WHERE cm.roomId = cr.id AND cm.isRead = 0 AND cm.senderId != ?) as unreadCount
         FROM chat_rooms cr
         JOIN users u ON u.id = CASE WHEN cr.buyerId = ? THEN cr.sellerId ELSE cr.buyerId END
         LEFT JOIN user_profiles up ON up.userId = u.id
         LEFT JOIN products p ON p.id = cr.productId
         WHERE cr.id = ?`,
        [currentUserId, currentUserId, roomId]
    );
    return rooms[0];
};

// ================== BUAT / AMBIL ROOM CHAT ==================
const getOrCreateRoom = async (req, res) => {
    try {
        const buyerId = req.user.id;
        const { sellerId, productId } = req.body;

        if (!sellerId || !productId) {
            return res.status(400).json({ message: 'sellerId dan productId wajib diisi' });
        }

        // Cek room sudah ada atau belum
        const [existing] = await db.query(
            'SELECT * FROM chat_rooms WHERE buyerId = ? AND sellerId = ? AND productId = ?',
            [buyerId, sellerId, productId]
        );

        if (existing.length > 0) {
            const richRoom = await getRoomWithDetails(existing[0].id, buyerId);
            return res.status(200).json({
                message: 'Room chat ditemukan',
                data: richRoom
            });
        }

        // Cek jika mencoba chat diri sendiri
        if (buyerId === sellerId) {
            return res.status(400).json({ message: 'Tidak bisa membuat room chat dengan diri sendiri' });
        }

        // Buat room baru
        const id = uuidv4();
        await db.query(
            'INSERT INTO chat_rooms (id, buyerId, sellerId, productId) VALUES (?, ?, ?, ?)',
            [id, buyerId, sellerId, productId]
        );

        const richRoom = await getRoomWithDetails(id, buyerId);
        return res.status(201).json({
            message: 'Room chat berhasil dibuat',
            data: richRoom
        });
    } catch (error) {
        return res.status(500).json({
            message: 'Gagal membuat room chat',
            error: error.message
        });
    }
};

// ================== GET SEMUA ROOM MILIK USER ==================
const getMyRooms = async (req, res) => {
    try {
        const userId = req.user.id;

        const [rooms] = await db.query(
            `SELECT cr.*, 
                u.username AS otherUsername,
                up.fullname AS otherFullname,
                up.photoUrl AS otherPhotoUrl,
                p.name AS productName,
                p.imageUrl AS productImageUrl,
                p.price AS productPrice,
                (SELECT cm.message FROM chat_messages cm 
                 WHERE cm.roomId = cr.id 
                 ORDER BY cm.createdAt DESC LIMIT 1) as lastMessage,
                (SELECT cm.createdAt FROM chat_messages cm 
                 WHERE cm.roomId = cr.id 
                 ORDER BY cm.createdAt DESC LIMIT 1) as lastMessageAt,
                (SELECT COUNT(*) FROM chat_messages cm 
                 WHERE cm.roomId = cr.id AND cm.isRead = 0 AND cm.senderId != ?) as unreadCount
             FROM chat_rooms cr
             JOIN users u ON u.id = CASE WHEN cr.buyerId = ? THEN cr.sellerId ELSE cr.buyerId END
             LEFT JOIN user_profiles up ON up.userId = u.id
             LEFT JOIN products p ON p.id = cr.productId
             WHERE cr.buyerId = ? OR cr.sellerId = ?
             ORDER BY lastMessageAt DESC`,
            [userId, userId, userId, userId]
        );

        return res.status(200).json({
            message: 'Daftar room chat',
            total: rooms.length,
            data: rooms
        });
    } catch (error) {
        return res.status(500).json({
            message: 'Gagal mengambil room chat',
            error: error.message
        });
    }
};

// ================== GET MESSAGES DI ROOM ==================
const getMessages = async (req, res) => {
    try {
        const { roomId } = req.params;
        const userId = req.user.id;

        // Validasi user adalah member room
        const [room] = await db.query(
            'SELECT * FROM chat_rooms WHERE id = ? AND (buyerId = ? OR sellerId = ?)',
            [roomId, userId, userId]
        );

        if (room.length === 0) {
            return res.status(403).json({ message: 'Akses tidak diizinkan' });
        }

        // Ambil semua pesan
        const [messages] = await db.query(
            `SELECT cm.*, u.username AS senderName 
             FROM chat_messages cm
             JOIN users u ON cm.senderId = u.id
             WHERE cm.roomId = ? 
             ORDER BY cm.createdAt ASC`,
            [roomId]
        );

        // Tandai pesan sebagai sudah dibaca
        await db.query(
            'UPDATE chat_messages SET isRead = 1 WHERE roomId = ? AND senderId != ? AND isRead = 0',
            [roomId, userId]
        );

        return res.status(200).json({
            message: 'Pesan berhasil diambil',
            total: messages.length,
            data: messages
        });
    } catch (error) {
        return res.status(500).json({
            message: 'Gagal mengambil pesan',
            error: error.message
        });
    }
};

// ================== KIRIM PESAN (REST fallback) ==================
const sendMessage = async (req, res) => {
    try {
        const { roomId } = req.params;
        const { message, imageUrl } = req.body;
        const senderId = req.user.id;

        if (!message && !imageUrl) {
            return res.status(400).json({ message: 'Pesan atau gambar wajib diisi' });
        }

        // Validasi user adalah member room
        const [room] = await db.query(
            'SELECT * FROM chat_rooms WHERE id = ? AND (buyerId = ? OR sellerId = ?)',
            [roomId, senderId, senderId]
        );

        if (room.length === 0) {
            return res.status(403).json({ message: 'Akses tidak diizinkan' });
        }

        const id = uuidv4();
        const type = imageUrl ? 'image' : 'text';

        await db.query(
            'INSERT INTO chat_messages (id, roomId, senderId, message, imageUrl, type) VALUES (?, ?, ?, ?, ?, ?)',
            [id, roomId, senderId, message ?? null, imageUrl ?? null, type]
        );

        const newMessage = {
            id, roomId, senderId, message, imageUrl, type,
            isRead: false,
            createdAt: new Date().toISOString()
        };

        const io = getIo();
        io.to(roomId).emit('new_message', newMessage);

        return res.status(201).json({
            message: 'Pesan berhasil dikirim',
            data: newMessage
        });
    } catch (error) {
        return res.status(500).json({
            message: 'Gagal mengirim pesan',
            error: error.message
        });
    }
};


// ================== KIRIM FOTO IMAGE ==================
const uploadChatImage = async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ message: 'File gambar wajib diupload' });
        }

        const result = await new Promise((resolve, reject) => {
            cloudinary.uploader.upload_stream(
                { folder: 'chat_images', resource_type: 'image' },
                (error, result) => {
                    if (error) reject(error);
                    else resolve(result);
                }
            ).end(req.file.buffer);
        });

        return res.status(200).json({
            message: 'Gambar berhasil diupload',
            imageUrl: result.secure_url
        });
    } catch (error) {
        return res.status(500).json({
            message: 'Gagal upload gambar',
            error: error.message
        });
    }
};

const proposePrice = async (req, res) => {
    try {
        const { roomId, price } = req.body;
        const userId = req.user.id;

        if (!roomId || !price || isNaN(price) || Number(price) <= 0) {
            return res.status(400).json({ message: 'roomId dan price yang valid wajib diisi' });
        }

        // Validasi user adalah member room
        const [room] = await db.query(
            'SELECT * FROM chat_rooms WHERE id = ? AND (buyerId = ? OR sellerId = ?)',
            [roomId, userId, userId]
        );

        if (room.length === 0) {
            return res.status(403).json({ message: 'Akses tidak diizinkan' });
        }

        const activeRoom = room[0];
        const proposedBy = userId === activeRoom.buyerId ? 'buyer' : 'seller';

        // Update room negotiation
        await db.query(
            "UPDATE chat_rooms SET proposedPrice = ?, negotiationStatus = 'pending', proposedBy = ? WHERE id = ?",
            [Number(price), proposedBy, roomId]
        );

        // Insert system message into chat
        const messageId = uuidv4();
        const senderName = proposedBy === 'buyer' ? 'Pembeli' : 'Penjual';
        const formattedText = `${senderName} mengajukan penawaran harga baru: Rp ${Number(price).toLocaleString('id-ID')}`;

        await db.query(
            'INSERT INTO chat_messages (id, roomId, senderId, message, type) VALUES (?, ?, ?, ?, ?)',
            [messageId, roomId, userId, formattedText, 'text']
        );

        const newMessage = {
            id: messageId,
            roomId,
            senderId: userId,
            senderName: req.user.username,
            message: formattedText,
            type: 'text',
            isRead: false,
            createdAt: new Date().toISOString()
        };

        // Broadcast via Socket.IO
        const io = getIo();
        io.to(roomId).emit('new_message', newMessage);
        io.to(roomId).emit('negotiation_update', {
            roomId,
            proposedPrice: Number(price),
            negotiationStatus: 'pending',
            proposedBy
        });

        return res.status(200).json({
            message: 'Penawaran harga berhasil diajukan',
            data: {
                roomId,
                proposedPrice: Number(price),
                negotiationStatus: 'pending',
                proposedBy
            }
        });
    } catch (error) {
        console.error('proposePrice error:', error);
        return res.status(500).json({ message: 'Gagal mengajukan penawaran harga', error: error.message });
    }
};

const respondNegotiation = async (req, res) => {
    try {
        const { roomId, action } = req.body; // action: 'accept' or 'reject'
        const userId = req.user.id;

        if (!roomId || !action || !['accept', 'reject'].includes(action)) {
            return res.status(400).json({ message: 'roomId dan action (accept/reject) wajib diisi' });
        }

        // Validasi user adalah member room
        const [room] = await db.query(
            'SELECT * FROM chat_rooms WHERE id = ? AND (buyerId = ? OR sellerId = ?)',
            [roomId, userId, userId]
        );

        if (room.length === 0) {
            return res.status(403).json({ message: 'Akses tidak diizinkan' });
        }

        const activeRoom = room[0];
        if (activeRoom.negotiationStatus !== 'pending') {
            return res.status(400).json({ message: 'Tidak ada penawaran aktif untuk direspon' });
        }

        // Ensure responder is NOT the one who proposed it (so they are responding to the other side's proposal)
        const isProposer = (userId === activeRoom.buyerId && activeRoom.proposedBy === 'buyer') ||
                           (userId === activeRoom.sellerId && activeRoom.proposedBy === 'seller');
        
        // Exception: Seller is allowed to counter/reject if buyer disagrees, or either side can reject.
        // Let's allow either side to reject, but only the other side can accept.
        if (action === 'accept' && isProposer) {
            return res.status(400).json({ message: 'Anda tidak dapat menyetujui penawaran Anda sendiri' });
        }

        const status = action === 'accept' ? 'accepted' : 'rejected';

        // Update room negotiation
        await db.query(
            "UPDATE chat_rooms SET negotiationStatus = ? WHERE id = ?",
            [status, roomId]
        );

        // Insert system message
        const messageId = uuidv4();
        const responderName = userId === activeRoom.buyerId ? 'Pembeli' : 'Penjual';
        const actionText = action === 'accept' ? 'menyetujui' : 'menolak';
        const formattedText = `${responderName} ${actionText} penawaran harga: Rp ${Number(activeRoom.proposedPrice).toLocaleString('id-ID')}`;

        await db.query(
            'INSERT INTO chat_messages (id, roomId, senderId, message, type) VALUES (?, ?, ?, ?, ?)',
            [messageId, roomId, userId, formattedText, 'text']
        );

        const newMessage = {
            id: messageId,
            roomId,
            senderId: userId,
            senderName: req.user.username,
            message: formattedText,
            type: 'text',
            isRead: false,
            createdAt: new Date().toISOString()
        };

        // Broadcast via Socket.IO
        const io = getIo();
        io.to(roomId).emit('new_message', newMessage);
        io.to(roomId).emit('negotiation_update', {
            roomId,
            proposedPrice: activeRoom.proposedPrice,
            negotiationStatus: status,
            proposedBy: activeRoom.proposedBy
        });

        return res.status(200).json({
            message: `Penawaran harga berhasil di-${actionText}`,
            data: {
                roomId,
                proposedPrice: activeRoom.proposedPrice,
                negotiationStatus: status,
                proposedBy: activeRoom.proposedBy
            }
        });
    } catch (error) {
        console.error('respondNegotiation error:', error);
        return res.status(500).json({ message: 'Gagal merespon penawaran harga', error: error.message });
    }
};

module.exports = { 
    getOrCreateRoom, 
    getMyRooms, 
    getMessages, 
    sendMessage, 
    uploadChatImage,
    proposePrice,
    respondNegotiation
};