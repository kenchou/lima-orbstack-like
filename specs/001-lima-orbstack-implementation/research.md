# Research for Lima OrbStack 类似功能实现

## Decision: Lima Configuration Approach
**Rationale**: Using Lima for VM management provides a lightweight alternative to Docker Desktop that's specifically designed for macOS. The configuration file (orbstack-like.yaml) will define the VM settings, port mappings, and disk configuration.
**Alternatives considered**: Docker Desktop, Podman, QEMU directly. Lima was chosen for its specific focus on macOS VM management and its integration with Kubernetes.

## Decision: Service Access via Domain Names
**Rationale**: Using servicename.namespace.svc.cluster.local format follows standard Kubernetes conventions and provides a predictable naming scheme. For local access via servicename.local, we'll use CoreDNS configuration or system resolver files to route these requests to the VM.
**Alternatives considered**: Direct port mapping, IP-based access, VPN. Domain name access was chosen for its similarity to OrbStack functionality and user-friendly access patterns.

## Decision: MetalLB for Load Balancer Services
**Rationale**: MetalLB provides a load balancer implementation for bare metal Kubernetes clusters, which is what we'll have in the Lima VM. This allows services to be exposed with external IPs similar to cloud environments.
**Alternatives considered**: NodePort, HostPort, Ingress controllers. MetalLB was chosen as it most closely replicates the cloud LoadBalancer behavior.

## Decision: One-Click Installation Script
**Rationale**: A setup.sh script will automate the entire process of checking prerequisites, downloading configurations, starting the VM, and verifying the installation. This meets the "开箱即用" requirement from the specification.
**Alternatives considered**: Multiple scripts, manual process, package managers. Single script was chosen for simplicity and to ensure consistent installation experience.

## Decision: Security Approach
**Rationale**: Following project specification to prioritize usability over security, the implementation will use basic default configurations with minimal security hardening. This allows for easier development and troubleshooting.
**Alternatives considered**: Full security hardening, extensive authentication. Basic security was chosen per project requirements to prioritize ease of use.

## Decision: Documentation Language
**Rationale**: Following project constitution requiring all documentation to be in Chinese, all guides and troubleshooting docs will be written in Chinese.
**Alternatives considered**: English documentation, bilingual docs. Chinese documentation chosen to comply with project constitution.

## Decision: macOS Permission Handling
**Rationale**: The setup.sh script will request minimum necessary permissions at appropriate points during installation rather than requesting all permissions at the start. This follows user-friendly practices by explaining why each permission is needed when it's required.
**Alternatives considered**: Request all permissions upfront, provide permission configuration guide for manual setup. On-demand permission requests chosen to improve user experience and reduce initial friction.

## Decision: macOS Version Compatibility
**Rationale**: The implementation will support macOS 12.x (Monterey) and higher as specified in the functional requirements (FR-007), with special handling for System Integrity Protection and Apple Silicon vs Intel architecture differences.
**Alternatives considered**: Limiting to latest macOS version, supporting older versions. The 12.x+ range was chosen as it balances compatibility with modern features needed for Lima.