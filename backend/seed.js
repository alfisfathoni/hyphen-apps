require('dotenv').config();
const mysql = require('mysql2/promise');
const { v4: uuidv4 } = require('uuid');

const pool = mysql.createPool({
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    waitForConnections: true,
    connectionLimit: 10,
});

const mockProducts = [
  { id: 'prod_1', title: 'Jacket Luxury Velvet', price: 250000, imageUrl: 'assets/images/PreFall.png', size: 'L', condition: 'like_new', category: 'Formal' },
  { id: 'prod_2', title: 'Streetwear Puffer Jacket', price: 320000, imageUrl: 'assets/images/jacket_product.png', size: 'XL', condition: 'like_new', category: 'Daily' },
  { id: 'prod_3', title: 'Retro Windbreaker Jacket', price: 180000, imageUrl: 'assets/images/cat_daily.png', size: 'M', condition: 'fair', category: 'Daily' },
  { id: 'prod_4', title: 'Classic Wool Trench Coat', price: 450000, imageUrl: 'assets/images/cat_formal.png', size: 'L', condition: 'like_new', category: 'Formal' },
  { id: 'prod_5', title: 'Jacket Premium Varsity', price: 250000, imageUrl: 'assets/images/slide1.png', size: 'M', condition: 'good', category: 'Pria' },
  { id: 'prod_6', title: 'Feminine Knitwear Cardigan', price: 210000, imageUrl: 'assets/images/cat_wanita.png', size: 'S', condition: 'like_new', category: 'Wanita' },
  // Product 7 is size 42, which isn't valid for XS-XXL enum, mapping to L
  { id: 'prod_7', title: 'Running Shoes Zoom Air', price: 650000, imageUrl: 'assets/images/foryou_tall.png', size: 'L', condition: 'like_new', category: 'Daily' },
  { id: 'prod_8', title: 'Casual Knit Sweater', price: 290000, imageUrl: 'assets/images/banner_sweater.png', size: 'L', condition: 'good', category: 'Daily' },
  { id: 'prod_9', title: 'California Retro Hoodie', price: 240000, imageUrl: 'assets/images/Winter.png', size: 'M', condition: 'good', category: 'Pria' },
  // Product 10 is size 41, mapping to M
  { id: 'prod_10', title: 'Suede Tiger Sneakers', price: 780000, imageUrl: 'assets/images/Spring.png', size: 'M', condition: 'like_new', category: 'Daily' },
];

async function seed() {
    try {
        console.log('Seeding products...');
        
        // Find seeded users to act as the sellers
        const [users] = await pool.query("SELECT id, email FROM users WHERE email IN ('user1@gmail.com', 'user2@gmail.com')");
        if (users.length === 0) {
            console.log('Seeded users not found. Please run the user seeder first.');
            return;
        }

        const userMap = {};
        users.forEach(u => {
            userMap[u.email] = u.id;
        });

        const user1Id = userMap['user1@gmail.com'] || users[0].id;
        const user2Id = userMap['user2@gmail.com'] || (users[1] ? users[1].id : users[0].id);

        let index = 0;
        for (const p of mockProducts) {
            // Alternate products between user1 and user2
            const sellerId = index % 2 === 0 ? user1Id : user2Id;
            index++;

            // Insert product
            await pool.query(
                'INSERT IGNORE INTO products (id, sellerId, name, description, price, category, weight, originCityId, originCityLabel, imageUrl, item_condition, defects, status) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
                [p.id, sellerId, p.title, 'Mock product description', p.price, p.category, 500, 1, 'Jakarta', p.imageUrl, p.condition, null, 'approved']
            );

            // Insert size
            await pool.query(
                'INSERT IGNORE INTO product_sizes (productId, size, stock) VALUES (?, ?, ?)',
                [p.id, p.size, 1]
            );
        }

        console.log('Successfully seeded 10 products!');
        process.exit(0);
    } catch (e) {
        console.error('Error seeding:', e);
        process.exit(1);
    }
}

seed();
