const https = require('https');

function sendFileToAPI(filePath, action) {
    const data = JSON.stringify({
        file_path: filePath,
        action: action
    });

    const options = {
        hostname: 'api.bknode.tech',
        port: 2253,
        path: '/1.0/cms/post/update',
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Content-Length': data.length,
            'Authorization': process.env.BKNODE_API_AUTH_KEY
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