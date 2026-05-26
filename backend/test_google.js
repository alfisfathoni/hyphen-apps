require('dotenv').config();
require('module-alias/register');
const pool = require('./src/config/db');
const { v4: uuidv4 } = require('uuid');

async function test() {
    try {
        const idToken = 'mock_google_tester@gmail.com';
        
        let email, name, googleId;
        if (idToken.startsWith('mock_')) {
            email = idToken.replace('mock_', '');
            name = email.split('@')[0];
            googleId = `mock_google_id_${name}`;
        }
        
        console.log('Testing with:', { email, name, googleId });
        
        let [user] = await pool.query('SELECT * FROM users WHERE email = ?', [email]);
        console.log('Existing user check returned:', user);

        if (user.length === 0) {
            console.log('Registering user...');
            const id = uuidv4();
            await pool.query(
                'INSERT INTO users (id, username, email, password, role, isVerified, googleId, authProvider) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
                [id, name, email, null, 'user', 1, googleId, 'google']
            );
            console.log('User inserted.');

            console.log('Inserting profile...');
            await pool.query(
                'INSERT INTO user_profiles (userId, fullname) VALUES (?, ?)',
                [id, name]
            );
            console.log('Profile inserted.');
        } else {
            console.log('User already exists.');
        }
        console.log('Test completed successfully!');
        process.exit(0);
    } catch (e) {
        console.error('Test failed with error:', e);
        process.exit(1);
    }
}

test();
