# Kubernetes Setup Scripts

This repository contains scripts to automate the setup of a Kubernetes cluster on both Ubuntu/Debian and Red Hat/CentOS based systems.

## Prerequisites

-   A fresh installation of a supported operating system.
-   `git` and `curl` installed on all machines.
-   At least 2 CPU cores and 2GB of RAM per machine is recommended.
-   Root or sudo privileges on all machines.

## Setup Instructions

Follow these steps to set up your Kubernetes cluster.

### Step 1: Run Setup Script on All Nodes

This step needs to be performed on **every** node in your cluster (both control-plane and worker nodes).

Choose the script that matches your operating system.

**For Ubuntu/Debian:**
```bash
bash setup_ubuntu.sh
```

**For Red Hat/CentOS:**
```bash
bash setup_redhat.sh
```

### Step 2: Run Master Script on the Control-Plane Node

This step should **only** be performed on the node you want to be your control-plane (master) node.

Choose the script that matches your operating system.

**For Ubuntu/Debian:**
```bash
bash master_ubuntu.sh
```

**For Red Hat/CentOS:**
```bash
bash master_redhat.sh
```

### Step 3: Join Worker Nodes to the Cluster

After the master script completes, it will output a `kubeadm join` command. Copy this command and run it on each of your worker nodes to join them to the cluster.

The command will look something like this:

```bash
kubeadm join <control-plane-host>:<control-plane-port> --token <token> --discovery-token-ca-cert-hash sha256:<hash>
```

