# setSoftware.sh

# 更新系统并安装必要软件
echo "更新系统并安装必要的软件..."
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install -y python3.12
sudo apt-get install -y python3-pip
sudo apt-get install -y python3-venv
sudo apt-get install -y npm
sudo apt-get install -y nodejs
sudo apt-get install -y mongodb-org-shell
sudo apt-get install -y screen
sudo apt-get update