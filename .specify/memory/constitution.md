<!-- 
SYNC IMPACT REPORT
Version change: 1.0.0 → 1.1.0
Modified principles: 
- Added Principle I: 中文交流与文档 (new)
- Added Principle II: 虚拟机环境管理 (new)
- Added Principle III: 服务访问与网络 (new)
- Added Principle IV: 配置与脚本自动化 (new)
- Added Principle V: 文档完整性与故障排除 (new)
Added sections: 附加约束, 开发工作流程
Removed sections: none
Templates requiring updates: 
- ✅ .specify/templates/plan-template.md: 合规检查部分可能需要识别新的原则
- ✅ .specify/templates/spec-template.md: 需确保需求对齐
- ✅ .specify/templates/tasks-template.md: 任务分类需反映新原则
Follow-up TODOs:
- RATIFICATION_DATE 需要确定项目的实际批准日期
-->
# lima-orbstack-like Constitution

## Core Principles

### I. 中文交流与文档
所有项目交流必须使用中文，所有项目文档必须使用中文编写。This ensures clear communication and understanding among all team members regardless of their English proficiency.

### II. 虚拟机环境管理
实现类似OrbStack的Linux虚拟机环境管理功能。所有功能应基于Lima技术，提供与OrbStack类似的用户体验。必须提供稳定、高效的Linux环境管理能力。

### III. 服务访问与网络
支持servicename.local域名访问，自动配置MetalLB以提供LoadBalancer服务。网络配置应确保服务的可访问性和稳定性。

### IV. 配置与脚本自动化
提供一键安装脚本(setup.sh)和配置文件(orbstack-like.yaml)，以简化项目部署过程。自动化脚本必须具备错误处理和状态检查功能。

### V. 文档完整性与故障排除
提供详尽的配置说明和故障排除指南。文档应包含常见问题的解决方案，确保使用者能够自助解决问题。

## 附加约束
- 技术栈：基于Lima和Kubernetes
- 兼容性：支持macOS系统环境
- 许可证：MIT许可证

## 开发工作流程
- 代码审查：所有提交必须经过同行审查
- 测试要求：对核心功能进行充分测试
- 部署流程：通过配置文件和脚本自动化部署过程

## Governance
宪法是项目的最高指导原则，高于所有其他实践和约定。所有PR和审查必须验证合规性，复杂性必须有合理依据。更新需经过项目维护者批准。

**Version**: 1.1.0 | **Ratified**: TODO(RATIFICATION_DATE): 需要确定项目创建或初始宪法批准日期 | **Last Amended**: 2025-10-28