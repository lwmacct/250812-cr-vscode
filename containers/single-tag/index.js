const fs = require("node:fs");
const path = require("node:path");
const Handlebars = require("handlebars");

const config = {
  baseImage: "ubuntu:resolute-20260421",
  etcdImage: "gcr.io/etcd-development/etcd:v3.6.11",
  maintainer: "https://github.com/lwmacct",
  source: "https://github.com/lwmacct/250812-cr-vscode",
  description: "专为 VSCode 容器开发环境构建",
  license: "MIT",
  timezone: "Asia/Shanghai",
  goProxy: "https://goproxy.cn,direct",
  aptArchiveMirror: "http://azure.archive.ubuntu.com/ubuntu",
  aptPortsMirror: "http://azure.ports.ubuntu.com/ubuntu-ports",
  aptSecurityMirror: "http://azure.archive.ubuntu.com/ubuntu",
};

const templatePath = path.join(__dirname, "Dockerfile.hbs");
const outputPath = path.join(__dirname, "Dockerfile");

const template = fs.readFileSync(templatePath, "utf8");
const dockerfile = Handlebars.compile(template, { noEscape: true })(config);

fs.writeFileSync(outputPath, dockerfile);
console.log(`Generated ${path.relative(process.cwd(), outputPath)}`);
