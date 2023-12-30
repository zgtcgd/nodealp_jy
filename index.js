const port = process.env.PORT || 3000;
const FILE_PATH = process.env.FILE_PATH || '/tmp/';
const http = require('http');
const fs = require('fs');
const { spawn } = require('child_process');

const startScriptPath = 'bash /app/start.sh';
fs.chmodSync(startScriptPath, 0o755);
const listFilePath = FILE_PATH + 'list.txt';
const subFilePath = FILE_PATH + 'sub.txt';

// 如果不想终端显示信息注释这一段
const startScript = spawn(startScriptPath);
startScript.stdout.on('data', (data) => {
  console.log(`${data}`);
});
startScript.stderr.on('data', (data) => {
  console.error(`${data}`);
});
startScript.on('error', (error) => {
  console.error(`启动脚本错误: ${error}`);
  process.exit(1);
});

// 如果不想终端显示信息注释这一段
const startScript = spawn(startScriptPath);
startScript.stdout.on('data', (data) => {
  console.log(`${data}`);
});
startScript.stderr.on('data', (data) => {
  console.error(`${data}`);
});
startScript.on('error', (error) => {
  console.error(`启动脚本错误: ${error}`);
  process.exit(1);
});

const server = http.createServer((req, res) => {
  if (req.url === '/') {
    res.writeHead(200);
    res.end('hello world');

  } else if (req.url === '/healthcheck') {
    res.writeHead(200);
    res.end('ok');

  } else if (req.url === '/list') {
    fs.readFile(listFilePath, 'utf8', (error, data) => {
      if (error) {
        res.writeHead(500);
        res.end('Error reading file');
      } else {
        res.writeHead(200, { 'Content-Type': 'text/plain; charset=utf-8' });
        res.end(data);
      }
    });

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
  console.log(`Server is running on port ${port}`);
});
