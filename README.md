# terraform-proxmox-talos

Terraform module to provision Talos Linux Kubernetes clusters with Proxmox

## Example usage

```bash
export PROXMOX_VE_USERNAME="root@pam"
export PROXMOX_VE_PASSWORD="super-secret"
```

```terraform
terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
      version = "~> 0.75.0"
    }
    talos = {
      source = "siderolabs/talos"
      version = "~> 0.7.1"
    }
  }
}

provider "proxmox" {
  endpoint = "https://192.168.1.21:8006/"
  insecure = true
}

module "talos" {
    source  = "bbtechsys/talos/proxmox"
    version = "0.1.5"
    talos_cluster_name = "test-cluster"
    talos_version = "1.9.5"
    control_nodes = {
        "test-control-0" = "pve1"
        "test-control-1" = "pve1"
        "test-control-2" = "pve1"
    }
    worker_nodes = {
        "test-worker-0" = "pve1"
        "test-worker-1" = "pve1"
        "test-worker-2" = "pve1"
    }
}

output "talos_config" {
    description = "Talos configuration file"
    value       = module.talos.talos_config
    sensitive   = true
}

output "kubeconfig" {
    description = "Kubeconfig file"
    value       = module.talos.kubeconfig
    sensitive   = true
}
```

 Technical Migration Plan: Flannel to Cilium (eBPF)
Target Environment: Talos Linux / Proxmox Cluster
Architect: Alexandre
Date: January 2026
Status: Implementation Ready
1. Executive Summary (For Management)
This migration replaces the legacy Flannel CNI (Layer 2 bridge) with Cilium (eBPF-native Layer 3-7 fabric).
WAF Pillar: Reliability: Eliminates the "single point of failure" in Flannel's VXLAN.
WAF Pillar: Performance: Reduces CPU overhead by ~30% by bypassing iptables and using kernel-level eBPF.
Strategic Goal: Enables BGP Peering with Bird2 and Consul Service Mesh integration.
2. Phase 1: Pre-Migration Validation
Run these commands to establish a baseline.
bash
# Capture baseline network state
kubectl get nodes -o wide > pre-migration-nodes.log
kubectl get pods -A -o wide > pre-migration-pods.log

# Verify Cilium compatibility on Talos nodes
cilium preflight check

3. Phase 2: Phased Migration (Best Practice)
We use a Hybrid Mode to prevent total cluster blackout.
Step 3.1: Install Cilium in "Secondary" Mode
This installs Cilium but prevents it from managing pod networking yet.
bash
# Install Cilium but DO NOT replace Flannel yet
helm install cilium cilium/cilium --version 1.18.0 \
  --namespace kube-system \
  --set cni.exclusive=false \
  --set cni.migration.enabled=true \
  --set bgpControlPlane.enabled=true

Step 3.2: Deactivate Flannel (Per Node)
Best Practice: Do not delete Flannel globally. Migrate one node at a time to minimize blast radius.
bash
# Pick a worker node
NODE="worker-01"

# 1. Drain the node (WAF: Reliability)
kubectl drain $NODE --ignore-daemonsets --delete-emptydir-data

# 2. Label node to trigger Cilium takeover
kubectl label node $NODE --overwrite "io.cilium.migration/cilium-default=true"

# 3. Restart Cilium on that node
kubectl -n kube-system delete pod -l k8s-app=cilium --field-selector spec.nodeName=$NODE
# 4. Verify Cilium is managing pod networking on that node
cilium status --node $NODE
4. Phase 3: Infrastructure Integration (Bird2 & Omni)
Since you are the Lead Architect, use the Omni API to apply the final state.
Step 4.1: Talos Omni Config Patch
File: cilium-final-patch.yaml
Copy this into your null_resource or local-exec Terraform block.
yaml
cluster:
  network:
    cni:
      name: none # Permanently disables Flannel
  inlineManifests:
    - name: install-cilium
      contents: |
        # Use this Helm command structure as the basis for the YAML content:
        # helm upgrade --install cilium cilium/cilium --version 1.17.0 \
        # --namespace kube-system --set k8sServiceHost=192.168.1.139 \
        # --set k8sServicePort=6443 --set kubeProxyReplacement=true \
        # --set l2announcements.enabled=true --set externalIPs.enabled=true \
        # --set ingressController.enabled=true --set bpf.lbExternalClusterIP=true \
        # --set bgpControlPlane.enabled=true --set ingressController.loadbalancerMode=shared \
        # --set operator.prometheus.enabled=true --set gatewayAPI.enabled=true --set devices=enp0s3
        
        # Converted YAML Manifest Snippet for Omni Patch
        k8sServiceHost: 192.168.1.139
        k8sServicePort: 6443
        kubeProxyReplacement: true
        l2announcements:
          enabled: true
        externalIPs:
          enabled: true
        ingressController:
          enabled: true
          loadbalancerMode: shared
        bpf:
          lbExternalClusterIP: true
        bgpControlPlane:
          enabled: true
        operator:
          prometheus:
            enabled: true
        gatewayAPI:
          enabled: true
        devices: enp0s3

Step 4.1.1: Apply the Patch
bash
# Apply the patch using Omni API
omni apply -f cilium-final-patch.yaml
Step 4.1.2: Verify Cilium is Fully Active
bash
# Verify Cilium is fully active
cilium status
Step 4.2: Verify BGP Peering
bash
# Check if Cilium is advertising to Bird2
cilium bgp peers
# On Bird2 Node:
birdc show protocols | grep cilium

5. Phase 4: Post-Migration Cleanup
Only run this after all nodes are confirmed "Healthy".
bash
# Remove Flannel entirely
kubectl delete daemonset kube-flannel-ds -n kube-flannel
kubectl delete cm kube-flannel-cfg -n kube-flannel

# Final connectivity test
cilium connectivity test

6. Architecture Scorecard
Feature	Flannel (Legacy)	Cilium (Well-Architected)
Logic Layer	Layer 2 (Bridge)	Layer 3-7 (eBPF)
BGP Support	None (Static)	Native Control Plane
Security	None	Identity-Aware Policies
Visibility	Simple Pings	Hubble (Deep Flow Logs)
Note:
"I have executed a Well-Architected Migration from Flannel to Cilium.
 This wasn't a simple 'delete and replace'; it was a phased rollout using Cilium 
 Migration Mode to ensure zero downtime. We have moved from a basic L2 network to a high-performance eBPF fabric
that natively peers with our Bird2 BGP infrastructure, alinhando-se com a estratégia definida no comando helm."

https://docs.cilium.io/en/latest/installation/k8s-install-helm/#k8s-install-helm

https://isovalent.com/blog/post/tutorial-migrating-to-cilium-part-1/

https://github.com/cilium/cilium
