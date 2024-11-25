# UrbanPulseMap 部署指南
## 部署前的准备工作

1.	注册域名并解析到服务器 IP 地址
请确保您已注册域名，并正确将域名解析指向服务器的 IP 地址。

2.	部署 SSL 证书
请确保域名和服务器已部署 SSL 证书，您可以使用 certbot 工具：
```bash
sudo apt install python3.12-certbot-nginx
certbot --nginx
```
3.	设置服务器的时区
请确保您已正确设置服务器操作系统的时区：
```bash
sudo timedatectl set-timezone <时区名称>
```
例如：sudo timedatectl set-timezone Asia/Shanghai

4.	调整系统文件描述符限制
MongoDB 需要大量文件描述符用于管理连接和文件。如果文件描述符上限过低，可能会导致 MongoDB 连接中断。请确保系统文件描述符的限制至少为 64000。

5.	开启服务器防火墙的必要端口
请确保服务器防火墙允许以下端口：
	•	27017（MongoDB）
	•	5000（后端服务 API）
	•	80（HTTP）
	•	443（HTTPS）

6.	设置 MongoDB 监听内网 IP 地址
如果您使用虚拟主机、NAT 网络地址转换，或云服务商的虚拟化环境（例如分离存储和计算层），可能会导致本地回环地址 127.0.0.1 无法正常通信。请修改 /etc/mongod.conf 文件，确保 MongoDB 监听内网 IP 地址：
```yaml
net:
  bindIp: 127.0.0.1,<您的内网 IP 地址>
  port: 27017
```

7.	提升 MongoDB 访问安全性
	•	如果有安全需求，可以更改 MongoDB 的默认监听端口。
	•	配置防火墙，仅允许特定 IP 地址访问 MongoDB 的公网端口。

### 注意事项

	•	请以 root 权限 或通过 sudo 执行脚本。
	•	部署完成后，访问 https://<您的域名> 检查服务是否正常运行。



# 部署步骤

## 克隆代码仓库

```bash
git clone https://github.com/0xliu1shou/UrbanPulseMap_Source
```

## 设置时区
```bash
cd UrbanPulseMap_Source/deploy
chmod +x set_timezone.sh
sudo ./set_timezone.sh
```
重启服务器

## 部署upmap
```bash
cd UrbanPulseMap_Source/deploy
chmod +x deploy.sh
sudo ./deploy.sh
```

### 部署ssl证书
```bash
chmod +x set_ssl.sh
sudo ./set_ssl.sh
```

## 设置文件符上限
```bash
chmod +x set_fd_limit.sh
sudo ./set_fd_limit.sh
```
重启服务器

## 验证部署情况
```bash
cd UrbanPulseMap_Source/deploy
chmod +x validate_deployment.sh
sudo ./validate_deployment.sh
```
