# lima-orbstack-like
Lima template implementing an OrbStack-like environment

## 项目说明
这是一个使用 Lima 实现类似 OrbStack 功能的项目。Lima 是一个 Linux 虚拟机管理器，可以为 macOS 提供 Linux 环境，类似 OrbStack 的功能。本项目旨在创建一个与 OrbStack 类似的体验，但基于 Lima 技术。

## 特性
- 提供与 OrbStack 类似的 Linux 环境
- 支持通过 servicename 访问 local 域名
- 自动配置 MetalLB 以提供 LoadBalancer 服务
- 容器和虚拟机管理

## 使用方法
### 一键安装
1. 确保已安装 Lima 和 kubectl
2. 运行一键安装脚本：
   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```

### 手动安装
1. 安装 Lima (如果尚未安装)
2. 使用提供的配置文件启动虚拟机：
   ```bash
   limactl start orbstack-like.yaml
   ```
3. 配置 KUBECONFIG：
   ```bash
   export KUBECONFIG="$HOME/.lima/orbstack-like/copied-from-guest/kubeconfig.yaml"
   ```
4. 等待 MetalLB 就绪并部署服务

## servicename.local 域名访问
本项目配置了对 servicename.local 域名的支持，允许通过本地域名访问运行在虚拟机中的服务。要使用此功能：

1. 确保虚拟机已启动并运行
2. 服务启动后（如 nginx），可以通过 `servicename.namespace.svc.cluster.local` 在主机上访问
3. 例如，如果在 default namespace 中运行了一个名为 `nginx` 的服务，可以在浏览器中访问 `http://nginx.default.svc.cluster.local`

## 服务访问方式
有多种方式可以访问部署在虚拟机中的服务：

### 1. 通过 MetalLB 分配的外部 IP
- 服务部署后，MetalLB 会分配一个外部 IP（如 `192.168.5.201`）
- 您可以在虚拟机内部访问该 IP：`limactl shell orbstack-like curl 192.168.5.201`
- 从主机访问可能受限于 Lima 的网络配置

### 2. 通过端口转发
- 在 orbstack-like.yaml 中配置端口转发来将服务端口映射到主机
- 需要获取服务的 NodePort：
  ```bash
  kubectl get svc nginx -o jsonpath='{.spec.ports[0].nodePort}'
  ```
- 然后在配置文件中添加端口转发规则

### 3. 通过服务名称 (如果 CoreDNS 工作正常)
- 如果 CoreDNS 服务正常运行，可以通过服务名称访问：
  `http://nginx.default.svc.cluster.local`

## 配置说明
- 主配置文件：`orbstack-like.yaml` - 包含 Lima 实例和 MetalLB 的配置
- 启动脚本：`setup.sh` - 一键安装和配置脚本

## 故障排除
如果遇到连接问题，请尝试：

### 一般问题
1. 检查虚拟机状态：`limactl list`
2. 检查 k8s 服务状态：`kubectl get pods -A`
3. 检查 MetalLB 状态：`kubectl get pods -n metallb-system`
4. 刷新 DNS 缓存 (macOS)：`sudo dscacheutil -flushcache`

### DNS 配置问题
如果您遇到 DNS 配置失败的问题：
1. 确保终端应用有完全磁盘访问权限
   - 打开"系统设置" > "隐私与安全性" > "完全磁盘访问权限"
   - 添加并授权您使用的终端应用（如 Terminal、iTerm2 等）
2. 手动创建 DNS 配置文件：
   ```bash
   sudo mkdir -p /etc/resolver
   echo "nameserver <VM_IP>" | sudo tee /etc/resolver/cluster.local
   echo "nameserver <VM_IP>" | sudo tee /etc/resolver/svc.cluster.local
   ```

### CoreDNS 冲突问题
当前 CoreDNS 服务可能与系统默认的 DNS 服务（systemd-resolved）冲突导致无法启动：
1. 检查 CoreDNS 状态：`limactl shell orbstack-like sudo systemctl status coredns-k8s`
2. 如果无法启动，可以手动启动服务并指定端口：
   ```bash
   # 在虚拟机内部运行
   sudo coredns -conf /etc/coredns-k8s/Corefile -dns.port=5353
   ```
3. 然后在 /etc/resolver/*.cluster.local 文件中，将 nameserver 指向 VM IP 和端口 5353

### 服务访问问题
1. 确认服务已分配外部 IP：`kubectl get svc -o wide`
2. 确认 MetalLB 配置正确：`kubectl get ipaddresspool -n metallb-system`
3. 手动测试服务：`limactl shell orbstack-like curl http://<EXTERNAL_IP>`

## License
MIT
