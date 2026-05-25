require('dotenv').config();
const mysql = require('mysql2/promise');
const bcrypt = require('bcrypt');
const { v4: uuidv4 } = require('uuid');

const pool = mysql.createPool({
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    waitForConnections: true,
    connectionLimit: 10,
});

async function seedUsers() {
    try {
        console.log('Seeding users and profiles...');

        // Hash default password once to optimize performance
        const defaultPassword = 'Password123';
        const hashedPassword = await bcrypt.hash(defaultPassword, 10);

        const usersToSeed = [
            {
                email: 'user1@gmail.com',
                username: 'user1',
                role: 'user',
                fullname: 'John Doe',
                phone: '081234567890',
                location: 'Jakarta',
            },
            {
                email: 'user2@gmail.com',
                username: 'user2',
                role: 'user',
                fullname: 'Jane Smith',
                phone: '081298765432',
                location: 'Bandung',
            }
        ];

        for (const userData of usersToSeed) {
            // Check if user already exists
            const [existing] = await pool.query('SELECT id FROM users WHERE email = ?', [userData.email]);

            if (existing.length === 0) {
                const userId = uuidv4();
                
                // Insert User
                await pool.query(
                    'INSERT INTO users (id, username, email, password, role, isVerified, authProvider) VALUES (?, ?, ?, ?, ?, ?, ?)',
                    [userId, userData.username, userData.email, hashedPassword, userData.role, 1, 'local']
                );

                // Insert Profile
                await pool.query(
                    'INSERT INTO user_profiles (userId, fullname, phone, location) VALUES (?, ?, ?, ?)',
                    [userId, userData.fullname, userData.phone, userData.location]
                );

                console.log(`Created user: ${userData.email} and its profile.`);
            } else {
                console.log(`User ${userData.email} already exists. Skipping.`);
            }
        }

        console.log(' Successfully seeded users and profiles!');
        process.exit(0);
    } catch (error) {
        console.error('Error seeding users:', error);
        process.exit(1);
    }
}

seedUsers();
