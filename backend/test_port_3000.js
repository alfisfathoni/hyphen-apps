const axios = require('axios');

async function check() {
    try {
        console.log('Sending post to http://localhost:3000/api/v1/auth/google-signin');
        const res = await axios.post('http://localhost:3000/api/v1/auth/google-signin', {
            idToken: 'mock_google_tester@gmail.com'
        });
        console.log('Response:', res.data);
    } catch (e) {
        if (e.response) {
            console.error('Response failed with status:', e.response.status);
            console.error('Response data:', e.response.data);
        } else {
            console.error('Error message:', e.message);
        }
    }
}

check();
