# Feature Specification: Lima OrbStack 类似功能实现

**Feature Branch**: `001-lima-orbstack-implementation`  
**Created**: 2025-10-28  
**Status**: Draft  
**Input**: User description: "这是一个使用 Lima 实现类似 OrbStack 功能的项目。本项目旨在创建一个与 OrbStack 类似的体验，但基于 Lima 技术。支持通过 servicename 访问 local 域名。提供一键安装脚本，傻瓜式安装设置，位用户提供开箱即用体验。详细需求参考 @README.md"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - 一键安装和设置虚拟环境 (Priority: P1)

用户希望使用一键安装脚本来快速设置类似 OrbStack 的功能，而无需手动配置复杂的虚拟环境和网络设置。用户只需运行一个脚本即可获得完整的 Linux 环境。

**Why this priority**: 这是最核心的功能，使用户能够快速体验产品，实现"开箱即用"的价值主张。

**Independent Test**: 用户可以在干净的系统上运行一键安装脚本，验证是否能够成功创建虚拟机环境并完成基本配置。

**Acceptance Scenarios**:

1. **Given** 用户在 macOS 上安装了 Lima，**When** 用户运行 setup.sh 一键安装脚本，**Then** 虚拟机成功启动并配置完成
2. **Given** 虚拟机已经配置完成，**When** 用户访问 servicename.local 域名，**Then** 能够成功访问虚拟机中的服务

---

### User Story 2 - 服务访问与网络配置 (Priority: P2)

用户需要通过 servicename.local 域名访问虚拟机中的服务，实现与 OrbStack 类似的本地开发体验。用户希望服务可以通过友好的域名访问，而不只是 IP 地址。

**Why this priority**: 这是提供类似 OrbStack 体验的关键部分，使用户能够方便地访问和测试其服务。

**Independent Test**: 用户启动服务后，可以通过 servicename.namespace.svc.cluster.local 格式的域名在主机上访问该服务。

**Acceptance Scenarios**:

1. **Given** 服务在虚拟机中已经启动，**When** 用户在主机上访问 servicename.namespace.svc.cluster.local，**Then** 请求被正确路由到虚拟机中的服务
2. **Given** MetalLB 已配置，**When** 服务部署，**Then** 服务获得外部 IP 并可通过该 IP 访问

---

### User Story 3 - 自动配置 MetalLB (Priority: P3)

用户需要自动配置 MetalLB 以提供 LoadBalancer 服务。这将允许用户在虚拟机中部署的服务可以通过外部 IP 地址访问。

**Why this priority**: 虽然不是核心功能，但这是提供完整开发环境的重要补充功能。

**Independent Test**: 用户部署服务后，验证 MetalLB 是否自动分配了外部 IP 地址，且该 IP 可以访问服务。

**Acceptance Scenarios**:

1. **Given** MetalLB 已安装，**When** 用户部署 LoadBalancer 服务，**Then** 服务获得外部 IP 地址
2. **Given** 服务有外部 IP，**When** 用户尝试访问该 IP，**Then** 服务响应请求

---

### Edge Cases

- 什么 happens 当虚拟机配置文件已存在时？应该提供选项来覆盖或更新现有配置
- 如何处理网络冲突问题？例如，当某些端口或 IP 已被占用时
- 当安装脚本失败时，系统如何处理回滚或提供错误信息？
- 如果用户没有管理员权限或特定系统权限，安装过程如何处理？

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: 系统 MUST 提供一键安装脚本(setup.sh)，以简化整个安装过程
- **FR-002**: 系统 MUST 使用 Lima 技术实现类似 OrbStack 的 Linux 虚拟机环境
- **FR-003**: 用户 MUST 能够通过 servicename.namespace.svc.cluster.local 格式访问虚拟机中的服务
- **FR-004**: 系统 MUST 自动配置 MetalLB 以提供 LoadBalancer 服务
- **FR-005**: 系统 MUST 提供开箱即用的体验，减少用户的手动配置需求
- **FR-006**: 一键安装脚本只需要适配 macOS 即可，作为 Lima 宿主系统。Lima 中运行 Ubuntu 系统，使用 Lima 模板提供的默认版本
- **FR-007**: 系统 MUST 兼容 macOS Monterey (12.x) 及以上版本
- **FR-008**: 一键安装脚本 MUST 在 macOS 所有现代版本上正常运行，包括处理权限和系统完整性保护
- **FR-009**: 一键安装脚本 MUST 请求最小必要权限并在需要时提示用户
- **FR-010**: 系统 MUST 提供详细错误日志以方便问题调查
- **FR-011**: 系统 MUST 提供与 OrbStack 类似的环境，使 k8s 和 docker 能够使用相同的 registry，并设置 DNS 以便方便地调用 k8s 中的 service。首选使用 docker context 来访问 lima 中的 containerd，如果此方法无法访问，则使用 wrapper 脚本替代原始的 docker，名称应是 docker 以保持兼容性
- **FR-012**: 一键安装程序优先确保正确安装和配置，不考虑性能优化

### Key Entities

- **虚拟机实例**: 表示通过 Lima 创建和管理的 Linux 环境，包括配置、状态和网络设置
- **网络配置**: 包含 DNS 设置、servicename.local 域名映射和 MetalLB 配置
- **一键安装脚本**: 包含整个安装和配置过程的自动化脚本，确保开箱即用体验

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 用户可以在 5 分钟内通过运行一键安装脚本完成完整的虚拟机环境设置
- **SC-002**: 系统能够支持用户部署的服务通过 servicename.local 域名 95% 的时间都能被成功访问
- **SC-003**: 90% 的用户能够成功完成一键安装过程，无需查阅额外文档或进行手动调试
- **SC-004**: 服务通过 MetalLB 获得外部 IP 的时间不超过 2 分钟
- **SC-005**: 一键安装脚本在支持的macOS版本上成功率超过95%，包括正确处理权限请求
- **SC-006**: 所有错误情况都提供详细错误日志以方便问题调查
- **SC-007**: 安装成功后用户能够通过 kubectl 和 docker 命令直接操作虚拟机中的资源

## Clarifications
### Session 2025-10-28

- Q: 安全措施与易用性的权衡 → A: 系统仅在需要时应用安全措施，优先考虑易用性而非安全性
- Q: 如何处理外部依赖失败 → A: 系统应优雅处理外部依赖失败并提供有意义的错误信息
- Q: 数据规模和容量假设 → A: 支持单用户开发环境，无需考虑多用户并发
- Q: 可观测性需求 → A: 实现基本日志记录供故障排除
- Q: 错误处理和恢复 → A: 系统应提供清晰的错误信息和故障恢复指导
- Q: 一键安装脚本对macOS的支持程度 → A: 一键安装脚本必须在macOS所有现代版本上正常运行，包括处理权限和系统完整性保护
- Q: macOS权限处理方式 → A: 安装脚本应请求最小必要权限并在需要时提示用户
- Q: Ubuntu发行版支持 → A: 一键安装脚本只需要适配macOS即可。也就是macOS作为lima宿主。lima中运行的是ubuntu系统，lima模板提供的默认版本就可以了。其他系统作为宿主暂不用考虑
- Q: 错误日志详细程度 → A: 所有错误应提供详细错误日志方便调查问题
- Q: API接口需求 → A: 没有API,所有操作都是针对k8s和docker
- Q: 一键安装程序性能要求 → A: 一键安装程序不考虑性能，要确保正确安装和配置
- Q: k8s和docker集成方式 → A: 系统提供与OrbStack类似的环境，使k8s和docker能够使用相同的registry，并设置DNS以便方便地调用k8s中的service。首选使用docker context来访问lima中的containerd，如果此方法无法访问，则使用wrapper脚本替代原始的docker，名称应是docker以保持兼容性
- Q: 安装时间要求 → A: SC-001中的5分钟目标是一个可达成的目标，但在FR-012中明确正确性优先于性能。如果为了确保正确安装需要更多时间，则优先保证正确性