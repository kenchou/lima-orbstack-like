# Tasks: Lima OrbStack 类似功能实现

**Input**: Design documents from `/specs/001-lima-orbstack-implementation/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: The examples below include test tasks. Tests are OPTIONAL - only include them if explicitly requested in the feature specification.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Single project**: `src/`, `tests/` at repository root
- **Web app**: `backend/src/`, `frontend/src/`
- **Mobile**: `api/src/`, `ios/src/` or `android/src/`
- Paths shown below assume single project - adjust based on plan.md structure

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [x] T001 Create project structure per implementation plan with orbstack-like.yaml, setup.sh, configure-context.sh, docker-wrapper.sh, and dns-setup.sh files
- [x] T002 [P] Verify prerequisite tools (Lima, kubectl, Docker CLI) are available on system
- [x] T003 [P] Create initial README.md in Chinese with project overview

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

Foundational tasks for Lima-based environment:

- [x] T004 Create base orbstack-like.yaml configuration template for Lima VM with Kubernetes and Docker enabled
- [x] T005 [P] Configure initial VM settings (CPUs, Memory, Disk) in orbstack-like.yaml from data model
- [x] T006 [P] Set up base directory structure for project including docs/ directory
- [x] T007 Create initial setup.sh script with prerequisite checking functionality
- [x] T008 Configure basic networking settings in orbstack-like.yaml template
- [x] T009 [P] Create placeholder files for configure-context.sh and docker-wrapper.sh
- [x] T010 [P] Configure orbstack-like.yaml to use Lima's default Ubuntu version as per FR-006
- [x] T011 [P] Configure orbstack-like.yaml to enable shared registry between k8s and docker as per FR-011

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - 一键安装和设置虚拟环境 (Priority: P1) 🎯 MVP

**Goal**: Create one-click installation script that sets up Lima VM with YAML template configuration

**Independent Test**: User can run setup.sh script and validate that VM starts successfully with basic configuration

### Implementation for User Story 1

- [x] T012 [P] [US1] Implement prerequisite validation functions in setup.sh
- [x] T013 [P] [US1] Add Lima VM creation functionality to setup.sh using orbstack-like.yaml
- [x] T014 [US1] Implement VM startup and verification in setup.sh
- [x] T015 [US1] Add error handling and rollback functionality to setup.sh
- [x] T016 [US1] Create basic troubleshooting.md documentation in Chinese
- [x] T017 [US1] Implement macOS permission request handling in setup.sh according to FR-009
- [x] T018 [US1] Validate setup completes within 5 minutes as per success criteria

**Checkpoint**: ✅ At this point, User Story 1 should be fully functional and testable independently

---

## Phase 4: User Story 2 - 服务访问与网络配置 (Priority: P2)

**Goal**: Enable access to services in VM via servicename.local domain names from host machine

**Independent Test**: User can start a service in the VM and access it via servicename.namespace.svc.cluster.local format on host

### Implementation for User Story 2

- [x] T019 [P] [US2] Implement DNS configuration in dns-setup.sh script for service discovery
- [x] T020 [P] [US2] Configure system resolver files for .local domain routing to VM
- [x] T021 [US2] Set up CoreDNS or modify resolver to route servicename.local requests
- [x] T022 [US2] Test service accessibility using standard Kubernetes service DNS names
- [x] T023 [US2] Implement shared registry configuration between k8s and docker as per FR-011
- [x] T024 [US2] Document service access procedures in configuration.md in Chinese

**Checkpoint**: ✅ At this point, User Stories 1 AND 2 should both work independently

---

## Phase 5: User Story 3 - 自动配置 MetalLB (Priority: P3)

**Goal**: Automatically configure MetalLB to provide LoadBalancer services in the VM

**Independent Test**: User deploys a LoadBalancer service and verifies it gets an external IP that can be accessed

### Implementation for User Story 3

- [x] T025 [P] [US3] Add MetalLB installation to setup.sh script
- [x] T026 [P] [US3] Configure MetalLB address pools as specified in data model
- [x] T027 [US3] Test LoadBalancer service deployment and external IP assignment
- [x] T028 [US3] Validate service gets external IP within 2 minutes as per success criteria
- [x] T029 [US3] Document MetalLB usage in configuration.md in Chinese

**Checkpoint**: ✅ All user stories should now be independently functional

---

## Phase 6: Docker/K8s Access Setup

**Goal**: Implement context and wrapper methods to access Docker and K8s from host

**Independent Test**: User can run kubectl and docker commands from host that operate on resources in the VM

### Implementation for Docker/K8s Access

- [x] T030 [P] [US4] Implement configure-context.sh to set up K8s context on host
- [x] T031 [P] [US4] Implement configure-context.sh to provide Docker access from host via docker context to access containerd in Lima VM
- [x] T032 [US4] Create docker wrapper script as alternative access method to VM services if docker context method fails, wrapper script should be named 'docker' for compatibility
- [x] T033 [US4] Test kubectl and docker command execution from host to VM
- [x] T034 [US4] Document both access methods in configuration.md in Chinese

**Checkpoint**: ✅ Docker/K8s Access Setup complete

---

## Phase 7: Error Logging and Diagnostics

**Goal**: Implement detailed error logging for troubleshooting as per FR-010

**Independent Test**: When errors occur, detailed logs are available for investigation

### Implementation for Error Logging

- [x] T035 [P] [US5] Add error logging functionality to setup.sh with detailed diagnostics
- [x] T036 [US5] Create error log rotation mechanism with daily rotation and retention policy
- [x] T037 [US5] Document error log locations and interpretation in troubleshooting.md

**Checkpoint**: ✅ Error Logging and Diagnostics complete

---

## Phase N: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [x] T039 [P] Update README.md with complete installation and usage instructions in Chinese
- [x] T040 [P] Create quickstart.md with step-by-step instructions following quickstart guide
- [x] T041 Add error handling and logging to all scripts per research decisions
- [x] T042 [P] Add basic validation and test functions to all scripts
- [x] T043 Run end-to-end validation using quickstart.md procedures
- [x] T044 Implement security measures as specified in research (minimal hardening)
- [x] T045 Validate all success criteria from spec.md are met
- [x] T046 [P] Add comprehensive troubleshooting guide in Chinese
- [x] T047 [P] Focus verification on installation and configuration correctness over performance per FR-012
- [x] T048 [P] Validate shared registry and DNS configuration between k8s and docker as per FR-011

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P2 → P3)
- **Polish (Final Phase)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - Depends on US1 (VM must be running)
- **User Story 3 (P3)**: Can start after Foundational (Phase 2) - Depends on US1 (VM must be running)
- **Docker/K8s Access (US4)**: Can start after Foundational (Phase 2) - Depends on US1 (VM must be running)
- **Error Logging and Diagnostics (US5)**: Can start after Foundational (Phase 2) - Depends on US1 (VM must be running)

### Within Each User Story

- Tests (if included) MUST be written and FAIL before implementation
- Models before services
- Services before endpoints
- Core implementation before integration
- Story complete before moving to next priority

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- All Foundational tasks marked [P] can run in parallel (within Phase 2)
- Once Foundational phase completes, all user stories can start in parallel (if team capacity allows)
- All tests for a user story marked [P] can run in parallel
- Models within a story marked [P] can run in parallel
- Different user stories can be worked on in parallel by different team members

---

## Parallel Example: User Story 1

```bash
# Launch all setup tasks for User Story 1 together:
Task: "Implement prerequisite validation functions in setup.sh"
Task: "Add Lima VM creation functionality to setup.sh using orbstack-like.yaml"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Test User Story 1 independently
5. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → Deploy/Demo (MVP!)
3. Add User Story 2 → Test independently → Deploy/Demo
4. Add User Story 3 → Test independently → Deploy/Demo
5. Add Docker/K8s Access → Test independently → Deploy/Demo
6. Add API Contracts → Test independently → Deploy/Demo
7. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1 (One-click installation with macOS permission handling)
   - Developer B: User Story 2 (Service access & network configuration)
   - Developer C: User Story 3 (MetalLB configuration)
   - Developer D: User Story 4 (Docker/K8s access)
   - Developer E: User Story 5 (Error logging and diagnostics)
3. Stories complete and integrate independently

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Verify tests fail before implementing
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Avoid: vague tasks, same file conflicts, cross-story dependencies that break independence