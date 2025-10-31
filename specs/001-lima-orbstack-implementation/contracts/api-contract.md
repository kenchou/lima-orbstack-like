# API Contracts for Lima OrbStack 类似功能实现

## 系统管理端点

### 检查系统状态
```
GET /status
```
检查虚拟机环境的整体状态。

**响应**:
```
{
  "vm_status": "running|stopped|error",
  "k8s_status": "ready|not-ready|error",
  "metallb_status": "ready|not-ready|error",
  "timestamp": "ISO8601 datetime"
}
```

### 启动虚拟机
```
POST /vm/start
```
启动Lima虚拟机。

**响应**:
```
{
  "status": "success|error",
  "message": "Human-readable message",
  "vm_name": "Name of the VM"
}
```

### 停止虚拟机
```
POST /vm/stop
```
停止Lima虚拟机。

**响应**:
```
{
  "status": "success|error", 
  "message": "Human-readable message",
  "vm_name": "Name of the VM"
}
```

## 服务管理端点

### 获取服务列表
```
GET /services
```
列出在虚拟机中运行的Kubernetes服务。

**响应**:
```
{
  "services": [
    {
      "name": "Service name",
      "namespace": "K8s namespace",
      "type": "ClusterIP|NodePort|LoadBalancer",
      "cluster_ip": "Internal IP",
      "external_ip": "External IP (if LoadBalancer)",
      "ports": [
        {
          "port": "Port number",
          "target_port": "Target port",
          "protocol": "TCP|UDP"
        }
      ],
      "status": "Running|Pending|Failed"
    }
  ]
}
```

### 创建新服务
```
POST /services
```
在Kubernetes中创建新服务。

**请求体**:
```
{
  "name": "Service name",
  "namespace": "K8s namespace (default: default)",
  "type": "ClusterIP|NodePort|LoadBalancer",
  "selector": {
    "app": "Application label"
  },
  "ports": [
    {
      "port": "Port number",
      "target_port": "Target port",
      "protocol": "TCP|UDP"
    }
  ]
}
```

**响应**:
```
{
  "status": "success|error",
  "message": "Human-readable message",
  "service": {
    "name": "Created service name",
    "namespace": "K8s namespace",
    "external_url": "URL to access the service if applicable"
  }
}
```

## 权限管理端点

### 检查权限状态
```
GET /permissions/status
```
检查当前系统权限状态，特别是与macOS安全相关的权限。

**响应**:
```
{
  "permissions": [
    {
      "type": "accessibility|full-disk-access|developer-tools",
      "granted": "true|false",
      "required": "true|false",
      "description": "Permission description"
    }
  ]
}
```

### 请求权限
```
POST /permissions/request
```
请求必要的系统权限。

**请求体**:
```
{
  "permission_type": "accessibility|full-disk-access|developer-tools",
  "reason": "Reason for requesting permission"
}
```

**响应**:
```
{
  "status": "success|error|pending-user-action",
  "message": "Human-readable message",
  "next_steps": "Instructions for user if needed"
}
```