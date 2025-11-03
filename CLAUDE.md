# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository contains OpenStack learning environments using Vagrant + VirtualBox. The main focus is the `openstack-3node` configuration which provides a 3-node OpenStack setup for educational purposes.

## Common Commands

### Vagrant VM Management

```bash
# Navigate to the main project directory
cd openstack-3node

# Start all VMs (initial startup takes 20-30 minutes)
vagrant up

# Start specific VM
vagrant up controller
vagrant up network
vagrant up compute1

# Check VM status
vagrant status

# SSH into VMs
vagrant ssh controller
vagrant ssh network
vagrant ssh compute1

# Stop VMs
vagrant halt

# Restart VMs
vagrant reload

# Destroy VMs completely
vagrant destroy -f
```

### Environment Cleanup

```bash
# Clean up entire environment (Linux/macOS)
bash scripts/cleanup_environment.sh

# Clean up entire environment (Windows PowerShell)
PowerShell -ExecutionPolicy Bypass -File scripts/cleanup_environment.ps1

# Setup VirtualBox network (Linux/macOS)
bash scripts/setup_vbox_network.sh

# Setup VirtualBox network (Windows PowerShell)
PowerShell -ExecutionPolicy Bypass -File scripts/setup_vbox_network.ps1
```

## Architecture

### VM Configuration

- **Controller Node**: 172.16.100.10 (management), 172.16.200.10 (overlay), 192.168.0.181 (external)
  - 8GB RAM, 4 CPUs
  - Runs Keystone (auth), Glance (images), Nova API, Neutron API

- **Network Node**: 172.16.100.20 (management), 172.16.200.20 (overlay), 192.168.0.182 (external)
  - 4GB RAM, 2 CPUs
  - Runs Neutron agents, routing, DHCP

- **Compute Node**: 172.16.100.31 (management), 172.16.200.31 (overlay)
  - 8GB RAM, 4 CPUs
  - Runs Nova compute, hypervisor (KVM/QEMU)
  - Nested virtualization enabled

### Network Design

- **Management Network**: 172.16.100.0/24 (private_network)
- **Overlay Network**: 172.16.200.0/24 (internal VirtualBox network)
- **External Network**: 192.168.0.0/24 (public_network, bridged)

### Learning Phases

The project follows a structured 5-phase approach:

1. **Phase 1**: Environment setup and VM configuration
2. **Phase 2**: Foundation services (MariaDB, RabbitMQ, Memcached)
3. **Phase 3**: Core OpenStack services (Keystone, Glance, Nova, Neutron)
4. **Phase 4**: First VM instance creation
5. **Phase 5**: Basic exercises (web server, volume management)

## System Requirements

- **CPU**: 8+ cores with virtualization support (VT-x/AMD-V)
- **Memory**: 16GB+ (24GB recommended)
- **Disk**: 200GB+ free space (SSD recommended)
- **Software**: VirtualBox 7.0+, Vagrant 2.3+

## Bridge Interface Configuration

The Vagrantfile automatically detects bridge interfaces, but can be manually set:

```bash
# Set bridge interface via environment variable
export BRIDGE_INTERFACE="eth0"  # Linux
export BRIDGE_INTERFACE="en0"   # macOS
set BRIDGE_INTERFACE=Ethernet   # Windows
```

## Important Files

- `openstack-3node/Vagrantfile`: Main VM configuration
- `openstack-3node/docs/`: Comprehensive documentation including phase guides
- `openstack-3node/scripts/`: Utility scripts for environment management
- `openstack-3node/docs/openstack-learning-roadmap.md`: Complete learning path

## Documentation Structure

The docs directory contains:

- **Phase guides**: step-by-step instructions for each learning phase
- **Architecture docs**: detailed system and network design
- **Appendices**: glossary, troubleshooting, references
- **Practical guides**: hands-on exercises and operations

When working with this codebase, always refer to the phase documentation in `openstack-3node/docs/` for context on the learning objectives and proper configuration steps.
