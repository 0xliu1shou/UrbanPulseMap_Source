1、请确保您已注册了域名并正确将域名解析指向服务器ip地址
2、请确保您已为域名和服务器部署了ssl证书
  certbot python3.12-certbot-nginx
3、请确保您已正确设置了您服务器操作系统的时区
  sudo timedatectl set-timezone xx/xxx
4、MongoDB 需要大量文件描述符用于管理连接和文件，如果系统设置的文件描述符上限过低，可能导致 MongoDB 连接或操作中断。请确保系统的文件描述符上限至少为 64000
5、请确保您的服务器防火墙已开启 27017（MongoDB）、5000（后端服务api）、80（http）以及 443（https）端口
6、如果您是虚拟主机、使用 NAT 网络地址转换映射 ip 地址，或者您的云服务商是通过虚拟化环境为你提供服务器，存储、网络接口以及主机等采用分离挂载的方式（目前比较常见）部署，那么可能会导致服务器的本地回环地址 (127.0.0.1) 表现出不同的网络路径，这说明您的存储层和计算层之间的某些底层 I/O 操作仍需通过内网通信，您需要修改 /etc/mongod.conf 配置文件使 MongoDB 监听您的内网 ip 地址，否则前端服务将无法通过 api 获取后端数据库中的数据。
net:
  bindIp: 127.0.0.1,< 您的内网 ip 地址 >
  port: 27017
7、如果您有安全需求，可以自行更改 MongoDB 的监听端口，或者为服务器配置防火墙仅允许您自己的 ip 地址源通过公网访问 MongoDB URI 端口。


# UrbanPulseMap 部署指南

## 克隆代码仓库

```bash
git clone https://github.com/0xliu1shou/UrbanPulseMap_Source
sudo ./deploy.sh

# 部署前的准备工作

##	1.	注册域名并解析到服务器 IP 地址
请确保您已注册域名，并正确将域名解析指向服务器的 IP 地址。
##	2.	部署 SSL 证书
请确保域名和服务器已部署 SSL 证书，您可以使用 certbot 工具：
