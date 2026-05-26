require('dotenv').config();
require('module-alias/register');
const express = require('express');
const app = express();
app.use(express.json());

const authRoutes = require('./src/routes/auth.routes');
app.use('/api/v1/auth', authRoutes);

// Global error handler to catch and log the exact stack trace
app.use((err, req, res, next) => {
    console.error('DIAGNOSTIC SERVER ERROR STACK:', err);
    res.status(500).json({ message: 'Internal Server Error', error: err.message, stack: err.stack });
});

const PORT = 3001;
app.listen(PORT, async () => {
    console.log(`Diagnostic server listening on port ${PORT}`);
    
    // Send request to itself
    const axios = require('axios');
    try {
        const response = await axios.post(`http://localhost:${PORT}/api/v1/auth/google-signin`, {
            idToken: 'mock_google_tester@gmail.com'
        });
        console.log('DIAGNOSTIC SERVER RESPONSE:', response.data);
    } catch (error) {
        if (error.response) {
            console.error('DIAGNOSTIC REQUEST FAILED:', error.response.data);
        } else {
            console.error('DIAGNOSTIC REQUEST ERROR:', error.message);
        }
    }
    process.exit(0);
});
