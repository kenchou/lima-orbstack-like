# 故障排除指南

## 常见问题和解决方案

### 1. Lima 虚拟机无法启动
**问题**: `limactl start orbstack-like.yaml` 失败
**解决方案**:
- 检查是否安装了最新版本的 Lima
- 确认有足够的磁盘空间
- 检查系统资源是否足够（至少4GB内存）
- 查看日志: `limactl shell orbstack-like -- journalctl -u k3s`

### 2. DNS 解析失败
**问题**: 无法通过 servicename.local 访问服务
**解决方案**:
- 验证 `/etc/resolver/` 目录中有正确的配置文件
- 确认 CoreDNS 正在虚拟机中运行: `limactl shell orbstack-like sudo systemctl status coredns-k8s`
- 检查端口 5353 是否正确配置
- 刷新 DNS 缓存: `sudo dscacheutil -flushcache` (macOS)

### 3. MetalLB 未分配外部 IP
**问题**: LoadBalancer 服务的 EXTERNAL-IP 保持为 `<pending>`
**解决方案**:
- 检查 MetalLB 是否正在运行: `kubectl get pods -n metallb-system`
- 验证 IP 地址池配置: `kubectl get ipaddresspool -n metallb-system`
- 检查 MetalLB 日志: `kubectl logs -n metallb-system -l app=metallb,component=controller`
- 确认没有 IP 地址冲突

### 4. Docker 访问失败
**问题**: 无法从主机访问 Docker 容器
**解决方案**:
- 尝试使用 Docker 上下文: `./configure-context.sh`
- 或使用包装脚本: `./bin/docker ps`
- 确认虚拟机正在运行: `limactl list`

### 5. 权限问题
**问题**: 无法修改系统文件或目录
**解决方案**:
- 在"系统设置" > "隐私与安全性" > "完全磁盘访问权限"中授权终端应用
- 确保已正确授予系统权限
- 重新运行安装脚本

## 诊断命令

### 检查虚拟机状态
```bash
limactl list
limactl shell orbstack-like -- systemctl status k3s
limactl shell orbstack-like -- systemctl status coredns-k8s
```

### 检查 Kubernetes 状态
```bash
kubectl cluster-info
kubectl get nodes
kubectl get pods -A
```

### 检查 MetalLB 状态
```bash
kubectl get pods -n metallb-system
kubectl get ipaddresspool -n metallb-system
kubectl get l2advertisement -n metallb-system
kubectl logs -n metallb-system -l app=metallb,component=controller
```

### 检查 DNS 配置
```bash
# 检查系统 resolver 配置
ls -la /etc/resolver/

# 检查虚拟机内 CoreDNS 配置
limactl shell orbstack-like cat /etc/coredns-k8s/Corefile

# 检查 DNS 更新脚本
limactl shell orbstack-like cat /usr/local/bin/update-dns.sh
```

### 检查网络连接
```bash
# 检查虚拟机 IP
limactl shell orbstack-like ip addr show eth0

# 从主机测试连接虚拟机
limactl shell orbstack-like ping -c 3 $(limactl shell orbstack-like hostname -I | awk '{print $1}')
```

## 日志文件位置

### 虚拟机日志
- k3s 日志: 在虚拟机内 `/var/log/k3s.log`
- 系统日志: 在虚拟机内 `journalctl`
- CoreDNS 日志: 在虚拟机内 `journalctl -u coredns-k8s`

### 安装脚本日志
- 直接运行脚本时的控制台输出即为日志
- 重新运行 `./setup.sh` 可以查看详细输出

## 性能问题

### 虚拟机响应缓慢
- 增加分配的 CPU 和内存资源
- 检查宿主机是否有足够的可用资源
- 检查是否有过多的容器或服务在运行

### 网络速度慢
- 确认使用的是共享网络模式
- 检查宿主机网络连接
- 尝试重启 Lima 虚拟机

## 重置和恢复

### 完全重置环境
```bash
# 停止并删除虚拟机
limactl stop orbstack-like
limactl delete orbstack-like

# 删除相关配置
rm -rf ~/.lima/orbstack-like

# 可选：删除系统 resolver 配置
sudo rm -rf /etc/resolver/cluster.local
sudo rm -rf /etc/resolver/svc.cluster.local

# 重新运行安装脚本
./setup.sh
```

### 仅重置 Kubernetes 集群
```bash
# 在虚拟机内重置 k3s
limactl shell orbstack-like sudo /usr/local/bin/k3s-killall.sh
limactl shell orbstack-like sudo /usr/local/bin/k3s-uninstall.sh

# 然后重启虚拟机或重新安装 k3s
```