#!/bin/bash
set -euo pipefail
COREFILE="/etc/coredns-k8s/Corefile"
TEMPFILE="$(mktemp)"

# 准备 hosts 文件内容
HOSTSFILE="/etc/coredns-k8s/hosts"
HOSTSTEMP="$(mktemp)"

# 获取并生成 hosts 文件内容
if command -v jq >/dev/null; then
  # 获取 LoadBalancer 服务
  LB_ENTRIES=$(/usr/local/bin/k3s kubectl get svc --all-namespaces -o json 2>/dev/null | \
    jq -r '.items[] | select(.spec.type == "LoadBalancer") | .metadata.namespace as $ns | .metadata.name as $name | .status.loadBalancer.ingress[0].ip as $ip | select($ip != null) | "\($ip) \($name).\($ns).svc.cluster.dev"' 2>/dev/null)
  
  # 获取 ClusterIP 服务
  CI_ENTRIES=$(/usr/local/bin/k3s kubectl get svc --all-namespaces -o json 2>/dev/null | \
    jq -r '.items[] | select(.spec.type == "ClusterIP") | .metadata.namespace as $ns | .metadata.name as $name | .spec.clusterIP as $ip | select($ip != null) | "\($ip) \($name).\($ns).svc.cluster.dev"' 2>/dev/null)
  
  # 清空 hosts 临时文件
  > "$HOSTSTEMP"
  
  # 添加 LoadBalancer 服务条目
  if [ -n "$LB_ENTRIES" ]; then
    echo "$LB_ENTRIES" >> "$HOSTSTEMP"
  fi
  
  # 添加 ClusterIP 服务条目
  if [ -n "$CI_ENTRIES" ]; then
    echo "$CI_ENTRIES" >> "$HOSTSTEMP"
  fi
fi

# 比较并更新 hosts 文件
if ! cmp -s "$HOSTSFILE" "$HOSTSTEMP" 2>/dev/null; then
    mv "$HOSTSTEMP" "$HOSTSFILE"
    HOSTS_UPDATED=true
else
    rm "$HOSTSTEMP"
    HOSTS_UPDATED=false
fi

# 构建 Corefile 但不内联 hosts 条目，而是使用文件方式
cat > "$TEMPFILE" <<'EOL'
.:5353 {
    errors
    log
    hosts /etc/coredns-k8s/hosts {
        fallthrough
    }
    forward . 10.43.0.10
    cache 30
    reload
}
EOL

# 比较并更新 Corefile
if ! cmp -s "$COREFILE" "$TEMPFILE"; then
    mv "$TEMPFILE" "$COREFILE"
    systemctl reload coredns-k8s 2>/dev/null || systemctl restart coredns-k8s
    echo "✅ DNS updated at $(date)"
else
    rm "$TEMPFILE"
    if [ "$HOSTS_UPDATED" = true ]; then
        # 即使 Corefile 没有改变，hosts 文件改变了，也需要重启服务使更改生效
        systemctl reload coredns-k8s 2>/dev/null || systemctl restart coredns-k8s
        echo "✅ Hosts file updated at $(date)"
    fi
fi