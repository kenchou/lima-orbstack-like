# 配置指南

## 主要配置文件

### orbstack-like.yaml
这是 Lima 虚拟机的主要配置文件，包含以下关键配置：
- 虚拟机规格 (CPU、内存、磁盘)
- 网络设置
- Kubernetes (k3s) 安装
- Docker 兼容的 containerd 设置
- MetalLB 自动安装和配置
- CoreDNS DNS 代理设置
- 与主机共享 registry 的配置

### setup.sh
一键安装脚本，执行以下配置：
- 检查系统先决条件
- 启动 Lima 虚拟机
- 配置主机 DNS 解析
- 部署和配置 MetalLB
- 验证服务连接性

### configure-context.sh
配置 Kubernetes 和 Docker 上下文的脚本，用于从主机访问虚拟机中的服务。

## 网络配置

### DNS 设置
- 脚本自动在 `/etc/resolver/` 中创建配置
- 为 `.cluster.local` 和 `.svc.cluster.local` 域名转发到虚拟机的 CoreDNS
- CoreDNS 运行在端口 5353 以避免与系统 DNS 冲突

### MetalLB 配置
- IP 地址池范围：`192.168.105.200-192.168.105.250`
- 使用 L2 广告模式
- 自动检测 LoadBalancer 服务并分配 IP

## Docker 和 Kubernetes 访问

### 方法 1: Docker 上下文 (推荐)
使用 `configure-context.sh` 脚本设置：
```bash
./configure-context.sh
docker context use orbstack-like
```

### 方法 2: Docker 包装脚本
使用 `./bin/docker` 直接访问虚拟机中的 containerd：
```bash
./bin/docker ps
```

### Kubernetes 访问
使用标准的 kubectl 命令，但需要适当配置 KUBECONFIG：
```bash
export KUBECONFIG="$HOME/.lima/orbstack-like/copied-from-guest/kubeconfig.yaml"
kubectl get nodes
```

## 自定义配置

### 修改虚拟机规格
编辑 `orbstack-like.yaml` 文件中的 CPU、内存和磁盘设置。

### 修改 MetalLB IP 池范围
编辑 `orbstack-like.yaml` 文件中的 IP 地址池配置。

### 添加更多服务到 DNS 解析
DNS 配置会自动更新以包含新的 LoadBalancer 服务，每分钟检查一次。

## 权限配置

### macOS 系统权限
- 完全磁盘访问：用于修改 `/etc/resolver` 目录
- 辅助功能：如果需要自动化操作
- 开发者工具：Lima 运行所需