# UrbanPulseMap 部署指南
## 部署前的准备工作

1.	注册域名并解析到服务器 IP 地址
请确保您已注册域名，并正确将域名解析指向服务器的 IP 地址。

2.	开启服务器防火墙的必要端口
请确保服务器防火墙允许以下端口：
•	27017（MongoDB）
•	5000（后端服务 API）
•	80（HTTP）
•	443（HTTPS）

# 具体步骤和命令：
## 1. 克隆代码仓库

```bash
git clone https://github.com/0xliu1shou/UrbanPulseMap_Source
```

## 2. 设置时区
```bash
cd UrbanPulseMap_Source/deploy
chmod +x setTimezone.sh
sudo ./setTimezone.sh
```
### 重启服务器

##  3. 安装必要软件
```bash
cd UrbanPulseMap_Source/deploy
chmod +x setSoftware.sh
sudo ./setSoftware.sh
```
## 4. 设置 MongoDB 服务
### 如果您使用虚拟主机、NAT 网络地址转换，或云服务商的虚拟化环境，可能会导致存储层和计算层之间无法使用本地回环地址 127.0.0.1 正常通信。请按照部署脚本的提示输入您的内网 IP 地址，修改 /etc/mongod.conf 文件，确保 MongoDB 监听内网 IP 地址。
```bash
chmod +x setMongodb.sh
sudo ./setMongodb.sh
```
## 5. 部署后端与前端服务环境
```bash
chmod +x setEnvironment.sh
sudo ./setEnvironment.sh
```

## 6. 部署 ssl 证书
```bash
chmod +x setSsl.sh
sudo ./setSsl.sh
```

## 7. 修改配置文件
### 修改 vite.config.js、Nginx 以及前端 API 地址的 Config.js 配置文件
```bash
chmod +x setConfig.sh
sudo ./setConfig.sh
```

## 8. 设置文件符上限
### MongoDB 需要大量文件描述符用于管理连接和文件。如果文件描述符上限过低，可能会导致 MongoDB 连接中断。请确保系统文件描述符的限制至少为 64000。
```bash
chmod +x setFdLimit.sh
sudo ./setFdLimit.sh
```
### 重启服务器

## 9. 创建前端静态文件
```bash
chmod +x setWebsite.sh
sudo ./setWebsite.sh
```

## 10. 验证部署情况
```bash
cd UrbanPulseMap_Source/deploy
sudo bash ./check.sh
```

# 注意事项：
## 提升 MongoDB 访问安全性
•	如果有安全需求，可以自行更改 MongoDB 的默认监听端口。
•	配置防火墙，仅允许特定 IP 地址访问 MongoDB 的公网端口。

