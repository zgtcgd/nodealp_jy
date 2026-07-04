const port = process.env.PORT || process.env.SERVER_PORT || 3000;
const FILE_PATH = process.env.FILE_PATH || '/tmp';
const http = require('http');
const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');
const openhttp = process.env.OPENHTTP || '1';
const DEBUG = (process.env.DEBUG || 'false') === 'true';

function log(level, msg) {
    if (!DEBUG && level === 'DEBUG') return;
    const timestamp = new Date().toISOString().replace(/T/, ' ').replace(/\..+/, '');
    console.log(`[${timestamp}] [${level}] ${msg}`);
}
const info = (msg) => log('INFO', msg);
const debug = (msg) => log('DEBUG', msg);

const startScript = spawn('bash', ['./start.sh'], {
    env: {
        ...process.env,
        OPENHTTP: openhttp
    },
    stdio: ['pipe', 'pipe', 'pipe']
});

startScript.stdout.on('data', (data) => {
    debug(`[start.sh] ${data.toString().trim()}`);
});
startScript.stderr.on('data', (data) => {
    debug(`[start.sh ERROR] ${data.toString().trim()}`);
});
startScript.on('error', (error) => {
    debug(`Failed to start script: ${error.message}`);
});

process.on('SIGINT', () => {
    debug('Received SIGINT, cleaning up...');
    startScript.kill();
    process.exit(0);
});
process.on('SIGTERM', () => {
    debug('Received SIGTERM, cleaning up...');
    startScript.kill();
    process.exit(0);
});

info("Starting Server...");

if (openhttp === '1') {
    const server = http.createServer((req, res) => {
        if (req.url === '/') {
            const indexPath = path.join(__dirname, 'index.html');
            fs.readFile(indexPath, 'utf8', (error, data) => {
                if (error) {
                    res.writeHead(200, { 'Content-Type': 'text/plain; charset=utf-8' });
                    res.end('hello world');
                } else {
                    res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
                    res.end(data);
                }
            });
        } else if (req.url === '/sub') {
            const subFilePath = path.join(FILE_PATH, 'log.txt');
            fs.readFile(subFilePath, 'utf8', (error, data) => {
                if (error) {
                    res.writeHead(500, { 'Content-Type': 'text/plain; charset=utf-8' });
                    res.end('Error reading file');
                } else {
                    res.writeHead(200, { 'Content-Type': 'text/plain; charset=utf-8' });
                    res.end(data);
                }
            });
        } else {
            res.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
            res.end('Not found');
        }
    });

    server.listen(port, () => {
        info(`server is listening on port ${port}`);
    });

} else if (openhttp === '0') {
    info(`server is listening on port ${port} (no HTTP mode)`);
    startScript.on('close', (code) => {
        debug(`Child process exited (code: ${code})`);
        process.exit(code || 0);
    });
}
