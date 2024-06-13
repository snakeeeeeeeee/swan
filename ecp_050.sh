#!/bin/bash

# 确保脚本在任何命令失败时退出
set -e

# 函数：打印使用方法
usage() {
  echo "Usage: $0 <IP> <ADDRESS> <PRIVATE_KEY> <COLLATERAL_AMOUNT>"
  exit 1
}

# 参数验证
if [ -z "$1" ]; then
  echo "Error: 'IP' is required."
  usage
fi

if [ -z "$2" ]; then
  echo "Error: 'ADDRESS' is required."
  usage
fi

if [ -z "$3" ]; then
  echo "Error: 'PRIVATE_KEY' is required."
  usage
fi

if [ -z "$4" ]; then
  echo "Error: 'COLLATERAL_AMOUNT' is required."
  usage
fi

# 设置环境变量
IP=$1
ADDRESS=$2
PRIVATE_KEY=$3
COLLATERAL_AMOUNT=$4

# 根目录
cd ~

# 删除旧的运行环境
echo "删除.swan文"
rm -rf .swan

# 将私钥写入文件
echo "写入私钥到 private.key"
echo $PRIVATE_KEY > private.key

# 停止并移除 Docker 容器
echo "停止并移除容器 ubi-redis 和 resource-exporter"
docker stop ubi-redis resource-exporter || true
docker rm ubi-redis resource-exporter || true

# 删除旧的 computing-provider
echo "删除旧的 computing-provider"
rm -rf computing-provider

# 下载新的 computing-provider
echo "下载新的 computing-provider"
wget https://github.com/swanchain/go-computing-provider/releases/download/v0.5.0/computing-provider

# 检查下载是否成功
if [ ! -f "computing-provider" ]; then
  echo "Error: 下载 computing-provider 失败"
  exit 1
fi

# 添加执行权限
echo "添加执行权限"
chmod +x computing-provider

# 初始化 computing-provider
echo "初始化 computing-provider"
./computing-provider init --multi-address=/ip4/$IP/tcp/9085 --node-name=ikun3

# 导入钱包私钥
echo "导入钱包私钥"
./computing-provider wallet import private.key

# 创建账户
echo "创建账户"
./computing-provider account create --ownerAddress $ADDRESS --workerAddress $ADDRESS --beneficiaryAddress $ADDRESS --task-types 1,2,4
sleep 5

# 增加抵押
echo "增加抵押"
./computing-provider collateral add --ecp --from=$ADDRESS $COLLATERAL_AMOUNT
sleep 5

# 启动 ubi daemon
echo "启动 ubi daemon"
./computing-provider ubi daemon
