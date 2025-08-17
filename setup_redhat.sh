#!/bin/bash
#
# Common setup for all servers (Control Plane and Nodes) for Red Hat/CentOS
#
# This script has been updated to use the new, official pkgs.k8s.io repository
# and the correct CRI-O repository for modern distributions.

set -euxo pipefail

# Variable Declaration
# It's best practice to use a recent version. Let's stick with 1.26.3 as requested,
# but be aware that newer versions will require updating the URL and CRIO versions.
KUBERNETES_VERSION="1.26.3"

# Disable swap permanently
sudo swapoff -a
# Keeps the swap off during reboot by commenting out the line in /etc/fstab
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# --- START CRI-O Setup ---
# Using CentOS 8/9 as the base.
# This CRI-O version should match the Kubernetes major/minor version (e.g., v1.26).
OS="CentOS_8"
VERSION="1.26"

# Create the .conf file to load the modules at bootup
cat <<EOF | sudo tee /etc/modules-load.d/crio.conf
overlay
br_netfilter
EOF

# Load the modules now
sudo modprobe overlay
sudo modprobe br_netfilter

# Set up required sysctl params, these persist across reboots.
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

# Apply sysctl settings from all system config files
sudo sysctl --system

# Install CRI-O
# This is the official method for RHEL and compatible distributions.
# This assumes the correct OS version and CRI-O version.
# Make sure to change OS and VERSION variables at the top of the file if needed.
sudo dnf module enable -y cri-o:$VERSION
sudo dnf install -y cri-o

sudo systemctl daemon-reload
sudo systemctl enable crio --now

echo "CRI runtime installed successfully"
# --- END CRI-O Setup ---

# --- START Kubernetes Installation ---
# The old repository (packages.cloud.google.com) is deprecated and will result in 404 errors.
# We are now using the new, community-maintained pkgs.k8s.io repository.
# Note: This URL must match your Kubernetes minor version.
# For v1.26, the URL is pkgs.k8s.io/core:/stable:/v1.26/rpm/
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.26/rpm/
enabled=1
gpgcheck=1
repo_gpgcheck=1
# The GPG key has also changed for the new repository.
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.26/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl
EOF

# The new repo requires importing the GPG key first.
sudo rpm --import https://pkgs.k8s.io/core:/stable:/v1.26/rpm/repodata/repomd.xml.key

# The --disableexcludes=kubernetes flag is used to override any exclude settings in other repos.
sudo dnf install -y kubelet-${KUBERNETES_VERSION} kubeadm-${KUBERNETES_VERSION} kubectl-${KUBERNETES_VERSION} --disableexcludes=kubernetes

sudo systemctl enable --now kubelet

echo "Kubernetes components installed successfully"
# --- END Kubernetes Installation ---

# Install jq for JSON parsing
sudo dnf install -y jq

# Set node IP
# Assumes the primary interface is eth1. If your interface has a different name (e.g., eth0, ens33),
# you will need to change the 'eth1' value below.
local_ip="$(ip --json a s | jq -r '.[] | if .ifname == "eth1" then .addr_info[] | if .family == "inet" then .local else empty end else empty end')"
cat > /etc/default/kubelet << EOF
KUBELET_EXTRA_ARGS=--node-ip=$local_ip
EOF
