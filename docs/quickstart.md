# 快速开始指南

## 系统要求

- macOS 12.x (Monterey) 或更高版本
- Lima (安装: `brew install lima`)
- kubectl (安装: `brew install kubectl`)
- Docker CLI (安装: `brew install docker`)

## 一键安装

### 1. 验证先决条件
```bash
# 检查 Lima 是否安装
limactl --version

# 检查 kubectl 是否安装
kubectl version --client

# 检查 Docker CLI 是否安装
docker --version
```

### 2. 运行一键安装脚本
```bash
# 给脚本执行权限
chmod +x setup.sh

# 运行安装脚本
./setup.sh
```

注意：安装过程中，系统可能会请求各种权限（如完全磁盘访问、辅助功能等），请按照提示进行授权以确保功能完整。

### 3. 等待安装完成
- 脚本将自动执行以下操作：
  - 使用 orbstack-like.yaml 配置创建 Lima 虚拟机
  - 启动虚拟机
  - 配置 MetalLB
  - 设置 DNS 解析以支持 servicename.local 访问

## 验证安装

### 1. 检查虚拟机状态
```bash
limactl list
```

### 2. 检查 Kubernetes 集群
```bash
kubectl get nodes
```

### 3. 部署测试服务
```bash
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --port=80 --type=LoadBalancer
```

### 4. 检查服务分配的外部 IP
```bash
kubectl get svc nginx
```

### 5. 测试 servicename.namespace.svc.cluster.local 访问
```bash
# 如果 nginx 服务在 default namespace 中
limactl shell orbstack-like curl http://nginx.default.svc.cluster.local
```

## 使用服务

### 通过 LoadBalancer 服务访问
一旦服务创建并分配了外部 IP，您可以通过虚拟机 IP 和分配的端口访问服务。

### 通过 servicename.namespace.svc.cluster.local 访问
在虚拟机内部，您可以使用标准的 Kubernetes 服务 DNS 名称访问服务。

### 配置 Docker 上下文
为了从主机访问容器，您可以使用 configure-context.sh 脚本：
```bash
./configure-context.sh
```

或者使用预配置的 docker 包装脚本：
```bash
./bin/docker ps
```

## 故障排除

如果遇到连接问题，请检查：

1. 虚拟机是否正在运行：
   ```bash
   limactl list
   ```

2. Kubernetes 服务状态：
   ```bash
   kubectl get pods -A
   ```

3. MetalLB 是否正常运行：
   ```bash
   kubectl get pods -n metallb-system
   ```

4. 系统权限是否已正确授予：
   - 检查"系统设置" > "隐私与安全性" > 各类权限设置
   - 确保终端应用已获得所需权限