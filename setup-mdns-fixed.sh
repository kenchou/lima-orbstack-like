#!/bin/bash

# setup-mdns.sh - Script to install and configure mDNS service in Lima VM
# This will allow .local domain names to be resolved from the macOS host

echo "Installing avahi-daemon for mDNS support..."
apt-get update
apt-get install -y avahi-daemon avahi-utils

# Configure avahi-daemon - using simple configuration that works in container environments
cat > /etc/avahi/avahi-daemon.conf << 'EOF'
[server]
host-name=lima-orbstack-like
allow-interfaces=eth0,lima0
[wide-area]
enable-wide-area=yes
[workstation]
[publish]
publish-addresses=yes
publish-hinfo=no
publish-workstation=no
publish-domain=yes
publish-a-on-ipv4=yes
[p2p-publish]
[reflector]
[rlimits]
rlimit-as=64
rlimit-core=0
rlimit-data=16
rlimit-fsize=0
rlimit-nofile=256
rlimit-stack=16
EOF

# Enable and start avahi-daemon
systemctl enable avahi-daemon
systemctl start avahi-daemon

echo "mDNS service configured successfully."