const port = process.env.PORT || 3000;
const FLIE_PATH = process.env.FLIE_PATH || '/tmp/';
const express = require("express");
const app = express();
const http = require('http');
const fs = require('fs');
const { spawn } = require('child_process');
const { createProxyMiddleware } = require("http-proxy-middleware");
const { execFile } = require('child_process');
var exec = require("child_process").exec;

const startScriptPath = './start.sh';
fs.chmodSync(startScriptPath, 0o777);

app.get("/", function (req, res) {
  res.status(200).send("hello world");
});

app.get("/healthcheck", function (req, res) {
  res.status(200).send("ok");
});

//获取节点数据
app.get("/list", function (req, res) {
    let cmdStr = "cat " + FLIE_PATH + "list.txt";
    exec(cmdStr, function (err, stdout, stderr) {
      if (err) {
        res.type("html").send("<pre>命令行执行错误：\n" + err + "</pre>");
      }
      else {
        res.type("html").send("<pre>节点数据：\n\n" + stdout + "</pre>");
      }
    });
  });

//获取订阅数据
app.get("/sub", (req, res) => {
    let cmdStr = "cat " + FLIE_PATH + "sub.txt";
    exec(cmdStr, function (err, stdout, stderr) {
    if (err) {
      res.status(500).send('Error reading file');
    } else {
      res.type("txt").send(escape(stdout));
    }
  });
});

//获取系统进程表
app.get("/status", function (req, res) {
  let cmdStr = "ps -ef";
  exec(cmdStr, function (err, stdout, stderr) {
    if (err) {
      res.type("html").send("<pre>命令行执行错误：\n" + err + "</pre>");
    }
    else {
      res.type("html").send("<pre>获取系统进程表：\n" + stdout + "</pre>");
    }
  });
});

//web保活
function keep_web_alive() {
  exec("pidof web", function (err, stdout, stderr) {
    // 1.查后台系统进程，保持唤醒
    if (stdout != "" ) {
      console.log("web正在运行");
    }
    else {
      // 哪吒未运行，命令行调起
      exec(
        "bash " + FLIE_PATH + "web.sh 2>&1 &", function (err, stdout, stderr) {
          if (err) {
            console.log("保活-调起web-命令行执行错误:" + err);
          }
          else {
            console.log("保活-调起web-命令行执行成功!");
          }
        }
      );
    }
  });
}
setInterval(keep_web_alive, 30 * 1000);
// keepalive end

//nezha保活
function keep_nezha_alive() {
  exec("pidof nezha-agent", function (err, stdout, stderr) {
    // 1.查后台系统进程，保持唤醒
    if (stdout != "" ) {
      console.log("nz正在运行");
    }
    else {
      // 哪吒未运行，命令行调起
      exec(
        "bash " + FLIE_PATH + "nezha.sh 2>&1 &", function (err, stdout, stderr) {
          if (err) {
            console.log("保活-调起nz-命令行执行错误:" + err);
          }
          else {
            console.log("保活-调起nz-命令行执行成功!");
          }
        }
      );
    }
  });
}
setInterval(keep_nezha_alive, 30 * 1000);
// keepalive end

//argo保活,不用argo这段删除
function keep_argo_alive() {
  exec("pidof argo", function (err, stdout, stderr) {
    // 1.查后台系统进程，保持唤醒
    if (stdout != "" ) {
      console.log("cff正在运行");
    }
    else {
      // 哪吒未运行，命令行调起
      exec(
        "bash " + FLIE_PATH + "argo.sh 2>&1 &", function (err, stdout, stderr) {
          if (err) {
            console.log("保活-调起cff-命令行执行错误:" + err);
          }
          else {
            console.log("保活-调起cff-命令行执行成功!");
          }
        }
      );
    }
  });
}
setInterval(keep_argo_alive, 30 * 1000);
// keepalive end

app.use(
  "/",
  createProxyMiddleware({
    changeOrigin: true, // 默认false，是否需要改变原始主机头为目标URL
    onProxyReq: function onProxyReq(proxyReq, req, res) {},
    pathRewrite: {
      // 请求中去除/
      "^/": "/"
    },
    target: "http://127.0.0.1:8080/", // 需要跨域处理的请求地址
    ws: true // 是否代理websockets
  })
);

exec("bash start.sh", function (err, stdout, stderr) {
  if (err) {
    console.error(err);
    return;
  }
  console.log(stdout);
});

app.listen(port, () => console.log(`Example app listening on port ${port}!`));
