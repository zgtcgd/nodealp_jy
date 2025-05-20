const port = process.env.PORT || 3000;
const FILE_PATH = process.env.FILE_PATH || '/tmp';
const http = require('http');
const fs = require('fs');
const { spawn } = require('child_process');
const openserver = process.env.openserver || '1';

// run
const startScriptPath = `/app/start.sh`;
const childProcess = spawn(startScriptPath, [], {
    detached: false,
    stdio: 'inherit',
});

if (openserver === '1') {
    const subFilePath = FILE_PATH + '/log.txt';
    const server = http.createServer((req, res) => {
        if (req.url === '/') {
            res.writeHead(200);
            res.end('hello world');
        } else if (req.url === '/sub') {
            fs.readFile(subFilePath, 'utf8', (error, data) => {
                if (error) {
                    res.writeHead(500);
                    res.end('Error reading file');
                } else {
                    res.writeHead(200, { 'Content-Type': 'text/plain; charset=utf-8' });
                    res.end(data);
                }
            });
        } else {
            res.writeHead(404);
            res.end('Not found');
        }
    });
    server.listen(port, () => {
        console.log(`server is listening on port ${port}`);
    });
} else if (openserver === '0') {
    console.log(`server is listening on port ${port}`);
}
