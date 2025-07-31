const port = process.env.PORT || 3000;
const FILE_PATH = process.env.FILE_PATH || '/tmp';
const UUID = process.env.UUID;
const http = require('http');
const fs = require("fs");
const path = require("path");
const { spawn } = require('child_process');

const subfilePath = path.join(FILE_PATH, "log.txt");
const server = http.createServer((req, res) => {
    if (req.url === '/') {
        res.writeHead(200);
        res.end('hello world');
    } else if (req.url === `/${UUID}`) {
        fs.readFile(subfilePath, (err, data) => {
            if (err) {
                return res.status(500).send('Error reading file');
            }
            res.type("txt").send(data);
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
