const https = require('https');

function sendFileToAPI(filePath, action) {
    const data = JSON.stringify({
        file_name: filePath,
        action: action
    });

    const options = {
        hostname: 'https://api.bknode.tech',
        port: 2253,
        path: '/1.0/project/list',
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Content-Length': data.length
        }
    };

    const req = https.request(options, (res) => {
        let responseData = '';

        res.on('data', (chunk) => {
            responseData += chunk;
        });

        res.on('end', () => {
            console.log('Response:', responseData);
        });
    });

    req.on('error', (error) => {
        console.error('Error:', error);
    });

    req.write(data);
    req.end();
}

const filePath = process.argv[2];
const action = process.argv[3];

sendFileToAPI(filePath, action);