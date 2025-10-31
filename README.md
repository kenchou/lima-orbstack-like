# Lima OrbStack 类似功能实现

这是一个使用 Lima 实现类似 OrbStack 功能的项目。本项目旨在创建一个与 OrbStack 类似的体验，但基于 Lima 技术。支持通过 servicename 访问 local 域名。提供一键安装脚本，傻瓜式安装设置，为用户提供开箱即用体验。

## 功能特点

- 基于 Lima 的虚拟机环境管理
- 一键安装脚本 (setup.sh)
- 通过 servicename.local 域名访问服务
- 自动配置 MetalLB 以提供 LoadBalancer 服务
- 支持 k8s 和 docker 使用相同的 registry
- DNS 配置以便方便地调用 k8s 中的 service

## 系统要求

- macOS 12.x (Monterey) 或更高版本
- Lima
- kubectl
- Docker CLI

## 安装

```bash
# 给脚本执行权限
chmod +x setup.sh

# 运行一键安装脚本
./setup.sh
```

## 使用

安装完成后，您可以：

1. 使用 `kubectl` 管理 Kubernetes 集群
2. 使用 `docker` 命令操作容器
3. 通过 servicename.local 域名访问服务

## 文档

- [配置指南](docs/configuration.md)
- [故障排除](docs/troubleshooting.md)
- [快速开始](docs/quickstart.md)

## 许可证

MIT 许可证