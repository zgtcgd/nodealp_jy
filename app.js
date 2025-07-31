const port = process.env.PORT || 3000;
const FILE_PATH = process.env.FILE_PATH || '/tmp';
const http = require('http');
const UUID = process.env.UUID;
const fs = require('fs');
const { spawn } = require('child_process');

const subFilePath = FILE_PATH + '/log.txt';
const server = http.createServer((req, res) => {
    if (req.url === '/') {
        res.writeHead(200);
        res.end('hello world');
    } else if (req.url === '/healthcheck') {
        res.writeHead(200);
        res.end('ok');
    } else if (req.url === `/${UUID}`) {
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

const startScriptPath = `./start.sh`;
const childProcess = spawn(startScriptPath, [], {
    detached: false,
    stdio: 'inherit',
});

server.listen(port, () => {
    console.log(`server is listening on port ${port}`);
});
