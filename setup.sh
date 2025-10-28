#!/bin/bash
set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置变量
INSTANCE_NAME="orbstack-like"
YAML_FILE="orbstack-like.yaml"
DNS_DOMAINS=("cluster.local" "svc.cluster.local")
METALLB_NAMESPACE="metallb-system"
NGINX_DEPLOYMENT="nginx"
NGINX_SERVICE="nginx"
NGINX_IMAGE="nginx:latest"

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查命令是否存在
check_command() {
    local cmd=$1
    if ! command -v "$cmd" &> /dev/null; then
        log_error "$cmd 未找到，请先安装 $cmd"
        exit 1
    fi
}

# 检查系统权限
check_permissions() {
    log_info "检查系统权限..."
    
    # 检查是否可以写入 /etc 目录
    if ! sudo -n true 2>/dev/null; then
        log_info "需要管理员权限，请准备输入密码"
        if ! sudo -v; then
            log_error "无法获取管理员权限"
            return 1
        fi
    fi
    
    # 检查 SIP 状态（仅 macOS）
    if [[ "$OSTYPE" == "darwin"* ]]; then
        log_info "检查系统完整性保护 (SIP) 状态..."
        # 通常我们无法直接检查 SIP 状态，但我们知道 macOS 会限制对系统目录的访问
        log_info "在 macOS 上，您可能需要在 '系统设置' > '隐私与安全性' > '完全磁盘访问权限' 中授权终端应用"
    fi
    
    return 0
}

# 检查 Lima 实例状态
check_lima_status() {
    if limactl list --format='{{.Status}}' "$INSTANCE_NAME" 2>/dev/null | grep -q "Running"; then
        return 0
    else
        return 1
    fi
}

# 等待 Lima 实例启动
wait_for_lima_start() {
    local timeout=60
    local count=0
    
    log_info "等待 Lima 实例启动..."
    while [ $count -lt $timeout ]; do
        if check_lima_status; then
            log_success "Lima 实例已启动"
            return 0
        fi
        sleep 2
        ((count += 2))
    done
    
    log_error "Lima 实例启动超时"
    return 1
}

# 获取 VM IP 地址
get_vm_ip() {
    local vm_ip
    # 使用 sh -c 来正确执行管道命令
    vm_ip=$(limactl shell "$INSTANCE_NAME" sh -c "ip -4 addr show eth0 2>/dev/null | grep -oE 'inet [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | cut -d' ' -f2 | head -n1" 2>/dev/null)
    
    if [ -z "$vm_ip" ]; then
        log_error "无法获取 VM IP 地址，详细信息："
        log_info "尝试直接访问 Lima 虚拟机..."
        # 直接输出调试信息
        log_info "Lima 虚拟机网络接口信息："
        limactl shell "$INSTANCE_NAME" ip addr show eth0 2>/dev/null || log_error "无法访问 Lima 虚拟机或接口 eth0 不存在"
        return 1
    fi
    
    echo "$vm_ip"
    return 0
}

# 配置 DNS 转发
configure_dns() {
    log_info "配置 DNS 转发..."
    
    # 获取 VM IP
    local vm_ip
    vm_ip=$(get_vm_ip)
    if [ $? -ne 0 ]; then
        log_error "无法获取 VM IP"
        return 1
    fi
    
    log_info "VM IP 地址: $vm_ip"
    
    # 检查是否有权限访问 /etc/resolver 目录
    if [ ! -w /etc/resolver ] && [ ! -d /etc/resolver ]; then
        log_info "尝试创建 /etc/resolver 目录..."
        # 尝试创建目录并检查错误
        if ! sudo mkdir -p /etc/resolver 2>/dev/null; then
            log_error "无法创建 /etc/resolver 目录，详细错误信息如下："
            # 输出详细错误信息
            sudo mkdir -p /etc/resolver 2>&1
            log_warning "可能的原因："
            log_warning "1. 权限不足 - 您可能需要在 '系统设置' > '隐私与安全性' > '完全磁盘访问权限' 中授权终端应用"
            log_warning "2. 系统完整性保护 (SIP) 阻止了对系统目录的修改"
            log_warning "3. 需要输入管理员密码但未提供"
            return 1
        fi
        log_success "/etc/resolver 目录创建成功"
    fi
    
    # 为每个域名配置 DNS 转发
    for domain in "${DNS_DOMAINS[@]}"; do
        log_info "配置 $domain 域名解析..."
        
        # 先检查文件是否存在，如果存在则比较内容
        local existing_config=""
        if [ -f "/etc/resolver/$domain" ]; then
            existing_config=$(cat "/etc/resolver/$domain" 2>/dev/null)
            # 检查是否已配置正确的 nameserver 和端口
            if echo "$existing_config" | grep -q "nameserver $vm_ip" && echo "$existing_config" | grep -q "port 5353"; then
                log_info "$domain 的 DNS 配置已存在且正确"
                continue
            else
                log_info "更新 $domain 的 DNS 配置，原配置: $existing_config"
            fi
        fi
        
        # 写入新的 DNS 配置，指定端口 5353（因为 CoreDNS 在此端口运行以避免与 systemd-resolved 冲突）
        local dns_config="nameserver $vm_ip\nport 5353"
        if echo -e "$dns_config" | sudo tee "/etc/resolver/$domain" >/dev/null 2>&1; then
            log_success "成功配置 $domain 域名解析 (端口 5353)"
        else
            log_error "配置 $domain 域名解析失败，详细错误信息如下："
            # 输出详细错误信息
            echo -e "$dns_config" | sudo tee "/etc/resolver/$domain" 2>&1
            log_warning "可能的原因："
            log_warning "1. 权限不足 - 您可能需要在 '系统设置' > '隐私与安全性' > '完全磁盘访问权限' 中授权终端应用"
            log_warning "2. 系统完整性保护 (SIP) 阻止了对系统目录的修改"
            log_warning "3. 需要输入管理员密码但未提供"
            return 1
        fi
    done
    
    log_success "DNS 配置完成 (使用端口 5353 避免与 systemd-resolved 冲突)"
    log_info "DNS 解析将通过 $vm_ip:5353 提供服务"
    return 0
}

# 检查 Kubernetes 集群状态
check_k8s_status() {
    if kubectl cluster-info &>/dev/null; then
        return 0
    else
        return 1
    fi
}

# 等待 Kubernetes 集群就绪
wait_for_k8s_ready() {
    local timeout=120
    local count=0
    
    log_info "等待 Kubernetes 集群就绪..."
    while [ $count -lt $timeout ]; do
        if check_k8s_status; then
            log_success "Kubernetes 集群已就绪"
            return 0
        fi
        sleep 5
        ((count += 5))
    done
    
    log_error "Kubernetes 集群就绪超时"
    return 1
}

# 检查 MetalLB 是否已部署
check_metallb_deployed() {
    if kubectl get namespace "$METALLB_NAMESPACE" &>/dev/null; then
        return 0
    else
        return 1
    fi
}

# 检查 MetalLB 服务状态
check_metallb_status() {
    local controller_ready
    local speaker_ready
    # 获取 Running 状态的控制器 Pod 数量
    controller_ready=$(kubectl get pods -n "$METALLB_NAMESPACE" -l app=metallb,component=controller --no-headers 2>/dev/null | grep -c "Running" 2>/dev/null)
    # 如果命令失败，设置为 0
    if [ $? -ne 0 ] || [ -z "$controller_ready" ] || ! [[ "$controller_ready" =~ ^[0-9]+$ ]]; then
        controller_ready=0
    fi
    
    # 获取 Running 状态的 speaker Pod 数量
    speaker_ready=$(kubectl get pods -n "$METALLB_NAMESPACE" -l app=metallb,component=speaker --no-headers 2>/dev/null | grep -c "Running" 2>/dev/null)
    # 如果命令失败，设置为 0
    if [ $? -ne 0 ] || [ -z "$speaker_ready" ] || ! [[ "$speaker_ready" =~ ^[0-9]+$ ]]; then
        speaker_ready=0
    fi
    
    if [ "$controller_ready" -gt 0 ] && [ "$speaker_ready" -gt 0 ]; then
        return 0
    else
        return 1
    fi
}

# 部署 MetalLB
deploy_metallb() {
    log_info "检查 MetalLB 状态..."
    
    # 等待 MetalLB 命名空间创建
    local timeout=120
    local count=0
    
    log_info "等待 MetalLB 命名空间创建..."
    while [ $count -lt $timeout ]; do
        if check_metallb_deployed; then
            log_success "MetalLB 命名空间已创建"
            break
        fi
        sleep 5
        ((count += 5))
    done
    
    if [ $count -ge $timeout ]; then
        log_error "等待 MetalLB 命名空间创建超时"
        return 1
    fi
    
    # 等待 MetalLB 组件就绪
    log_info "等待 MetalLB 组件就绪..."
    kubectl wait --for=condition=ready pod -l app=metallb --timeout=120s -n "$METALLB_NAMESPACE" || {
        log_error "等待 MetalLB 组件就绪超时"
        return 1
    }
    
    # 检查是否已存在 IP 池配置
    log_info "检查 MetalLB IP 地址池配置..."
    if kubectl get ipaddresspool lima-pool -n "$METALLB_NAMESPACE" &>/dev/null; then
        log_info "IP 地址池 lima-pool 已存在"
    else
        log_info "未找到 IP 地址池 lima-pool，正在创建..."
        
        # 获取虚拟机 IP 网段，使用当前 IP 的网段来定义 MetalLB IP 池
        local vm_ip
        vm_ip=$(get_vm_ip)
        if [ $? -ne 0 ]; then
            log_warning "无法获取 VM IP，使用默认网段 192.168.5.0/24"
            vm_ip="192.168.5.15"  # 默认值
        fi
        
        # 提取 IP 网段（如 192.168.5）
        local ip_prefix
        ip_prefix=$(echo "$vm_ip" | cut -d'.' -f1-3)
        
        # 创建 IP 地址池，避免与当前 VM IP 冲突
        local start_ip="${ip_prefix}.200"
        local end_ip="${ip_prefix}.250"
        
        log_info "使用 IP 池范围: $start_ip-$end_ip"
        
        cat <<EOF | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: lima-pool
  namespace: $METALLB_NAMESPACE
spec:
  addresses:
  - $start_ip-$end_ip
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: lima-l2
  namespace: $METALLB_NAMESPACE
spec:
  ipAddressPools:
  - lima-pool
EOF
        if [ $? -eq 0 ]; then
            log_success "IP 地址池和 L2 广告配置创建成功"
            
            # 等待配置生效
            sleep 5
        else
            log_error "IP 地址池和 L2 广告配置创建失败"
            return 1
        fi
    fi
    
    # 检查 L2 广告配置
    log_info "检查 MetalLB L2 广告配置..."
    if kubectl get l2advertisement lima-l2 -n "$METALLB_NAMESPACE" &>/dev/null; then
        log_info "L2 广告 lima-l2 已存在"
    else
        log_info "未找到 L2 广告 lima-l2，但应该在之前的步骤中已创建"
        log_warning "L2 广告配置不存在，这可能表示之前的配置创建失败"
        return 1
    fi
    
    # 验证配置是否创建成功
    log_info "验证 IP 地址池配置..."
    if kubectl get ipaddresspool lima-pool -n "$METALLB_NAMESPACE" &>/dev/null; then
        log_success "IP 地址池 lima-pool 配置成功"
    else
        log_error "IP 地址池 lima-pool 配置失败"
        return 1
    fi
    
    log_info "验证 L2 广告配置..."
    if kubectl get l2advertisement lima-l2 -n "$METALLB_NAMESPACE" &>/dev/null; then
        log_success "L2 广告 lima-l2 配置成功"
    else
        log_error "L2 广告 lima-l2 配置失败"
        return 1
    fi
    
    # 等待 MetalLB 配置完全生效
    log_info "等待 MetalLB 配置生效..."
    sleep 10
    
    return 0
}

# 检查 Nginx 部署状态
check_nginx_deployed() {
    if kubectl get deployment "$NGINX_DEPLOYMENT" &>/dev/null; then
        return 0
    else
        return 1
    fi
}

# 部署 Nginx 服务
deploy_nginx() {
    log_info "检查 Nginx 部署状态..."
    
    if check_nginx_deployed; then
        log_info "Nginx 部署已存在，检查服务状态..."
        
        # 检查服务是否存在
        if kubectl get service "$NGINX_SERVICE" &>/dev/null; then
            log_info "Nginx 服务已存在"
        else
            log_info "创建 Nginx 服务..."
            kubectl expose deployment "$NGINX_DEPLOYMENT" --port=80 --type=LoadBalancer --name="$NGINX_SERVICE"
        fi
    else
        log_info "部署 Nginx..."
        kubectl create deployment "$NGINX_DEPLOYMENT" --image="$NGINX_IMAGE"
        
        log_info "创建 Nginx 服务..."
        kubectl expose deployment "$NGINX_DEPLOYMENT" --port=80 --type=LoadBalancer --name="$NGINX_SERVICE"
    fi
    
    # 等待服务 EXTERNAL-IP 分配
    log_info "等待 LoadBalancer 服务分配 EXTERNAL-IP..."
    local timeout=120  # 增加等待时间
    local count=0
    
    while [ $count -lt $timeout ]; do
        local external_ip
        external_ip=$(kubectl get service "$NGINX_SERVICE" -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
        
        if [ -n "$external_ip" ]; then
            log_success "服务已分配 EXTERNAL-IP: $external_ip"
            break
        fi
        
        sleep 5
        ((count += 5))
        
        # 每20秒打印一次服务状态和 MetalLB 日志
        if [ $((count % 20)) -eq 0 ]; then
            log_info "当前服务状态:"
            kubectl get service "$NGINX_SERVICE" -o wide
            log_info "检查 MetalLB 日志 (最近10行):"
            kubectl logs -n "$METALLB_NAMESPACE" -l app=metallb,component=controller --tail=10 2>/dev/null || log_info "无法获取 MetalLB 日志"
        fi
    done
    
    if [ -z "$external_ip" ]; then
        log_warning "在超时时间内未分配 EXTERNAL-IP，但服务已创建"
        # 显示服务详细信息
        kubectl get service "$NGINX_SERVICE" -o wide
        
        # 显示服务事件，这可能包含为什么 IP 未分配的信息
        log_info "服务事件详情:"
        kubectl describe service "$NGINX_SERVICE"
        
        # 检查 MetalLB 配置
        log_info "检查 MetalLB IP 地址池:"
        kubectl get ipaddresspool -n "$METALLB_NAMESPACE" -o yaml 2>/dev/null || log_info "无法获取 IP 地址池信息"
        
        log_info "检查 MetalLB L2 广告配置:"
        kubectl get l2advertisement -n "$METALLB_NAMESPACE" -o yaml 2>/dev/null || log_info "无法获取 L2 广告信息"
        
        # 检查 MetalLB 日志
        log_info "MetalLB 控制器日志:"
        kubectl logs -n "$METALLB_NAMESPACE" -l app=metallb,component=controller 2>/dev/null || log_info "无法获取 MetalLB 控制器日志"
    else
        # 显示服务详细信息
        kubectl get service "$NGINX_SERVICE" -o wide
    fi
    
    return 0
}

# 测试服务连通性
test_service_connectivity() {
    log_info "测试服务连通性..."
    
    # 首先检查服务是否具有外部 IP
    local external_ip
    external_ip=$(kubectl get service "$NGINX_SERVICE" -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
    
    if [ -n "$external_ip" ]; then
        log_info "使用外部 IP 测试连通性: $external_ip"
        log_info "注意: 从主机访问虚拟机 IP 可能因 Lima 网络配置而受限"
        local max_attempts=5
        local attempt=1
        
        while [ $attempt -le $max_attempts ]; do
            log_info "尝试连接外部 IP (第 $attempt/$max_attempts 次)..."
            
            if limactl shell "$INSTANCE_NAME" curl -s --connect-timeout 10 "http://$external_ip" > /dev/null; then
                log_success "虚拟机内部外部 IP 连接测试成功"
                break
            else
                log_info "虚拟机内部外部 IP 连接测试失败，等待重试..."
            fi
            
            sleep 5
            ((attempt++))
        done
        
        if [ $attempt -gt $max_attempts ]; then
            log_warning "虚拟机内部外部 IP 连接测试失败"
        fi
    else
        log_warning "服务未分配外部 IP，跳过外部 IP 连接测试"
    fi
    
    # 然后测试通过内部服务名访问
    log_info "测试内部服务名访问: http://nginx.default.svc.cluster.local"
    log_info "注意: 如果此测试失败，可能是因为 CoreDNS 与 systemd-resolved 冲突"
    
    # 尝试使用虚拟机内部访问服务名
    local max_attempts=10
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        log_info "尝试连接内部服务名 (第 $attempt/$max_attempts 次)..."
        
        # 首先尝试访问服务的 ClusterIP
        local cluster_ip
        cluster_ip=$(kubectl get service "$NGINX_SERVICE" -o jsonpath='{.spec.clusterIP}' 2>/dev/null)
        
        if [ -n "$cluster_ip" ] && limactl shell "$INSTANCE_NAME" curl -s --connect-timeout 10 "http://$cluster_ip" > /dev/null; then
            log_success "虚拟机内部 ClusterIP 连接测试成功"
            log_info "服务 ClusterIP: $cluster_ip"
            break
        else
            log_info "虚拟机内部 ClusterIP 连接测试失败，等待重试..."
        fi
        
        sleep 5
        ((attempt++))
    done
    
    if [ $attempt -gt $max_attempts ]; then
        log_warning "虚拟机内部 ClusterIP 连接测试失败"
    fi
    
    log_info "如需从主机通过服务名访问，请参考 README.md 中关于 CoreDNS 与 systemd-resolved 冲突的解决方案"
    return 0
}

# 主函数
main() {
    log_info "开始部署 Lima-Orbstack-Like 环境..."
    
    # 检查必要的命令
    log_info "检查必要的命令..."
    check_command "limactl"
    check_command "kubectl"
    check_command "curl"
    
    # 检查系统权限
    if ! check_permissions; then
        log_error "系统权限检查失败"
        exit 1
    fi
    
    # 检查 Lima 实例状态
    if check_lima_status; then
        log_info "Lima 实例已在运行"
    else
        log_info "启动 Lima 实例..."
        limactl start "$YAML_FILE"
        
        # 等待 Lima 实例启动
        if ! wait_for_lima_start; then
            log_error "无法启动 Lima 实例"
            exit 1
        fi
    fi
    
    # 配置 DNS
    if ! configure_dns; then
        log_error "DNS 配置失败"
        log_info "注意：如果持续出现 DNS 配置失败，您可以："
        log_info "1. 手动在系统设置中为终端应用授权完全磁盘访问权限"
        log_info "2. 或者跳过自动 DNS 配置，使用服务的外部 IP 进行访问"
        exit 1
    fi
    
    # 等待 Kubernetes 集群就绪
    if ! wait_for_k8s_ready; then
        log_error "Kubernetes 集群未就绪"
        exit 1
    fi
    
    # 部署 MetalLB
    if ! deploy_metallb; then
        log_error "MetalLB 部署失败"
        exit 1
    fi
    
    # 部署 Nginx
    if ! deploy_nginx; then
        log_error "Nginx 部署失败"
        exit 1
    fi
    
    # 等待一段时间让 DNS 配置生效
    log_info "等待 DNS 配置生效..."
    sleep 10
    
    # 测试服务连通性
    test_service_connectivity
    
    log_success "Lima-Orbstack-Like 环境部署完成！"
    log_info "您可以使用以下方式访问 Nginx 服务："
    log_info "1. 通过外部 IP: 访问 $(kubectl get service nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip' 2>/dev/null || echo '获取失败，请稍后重试')"
    log_info "2. 通过内部服务名: http://nginx.default.svc.cluster.local"
    log_info "3. 通过自定义域名: http://nginx.default.svc.cluster.local (如果 DNS 已正确更新)"
    log_info ""
    log_info "注意: 如果无法立即访问，可能需要等待 CoreDNS 更新或尝试刷新 DNS 缓存"
    log_info "刷新 DNS 缓存命令: sudo dscacheutil -flushcache (macOS)"
    
    # 提供额外的故障排除建议
    log_info ""
    log_info "如需故障排除，请参考 README.md 中的故障排除部分"
}

# 调用主函数
main "$@"
