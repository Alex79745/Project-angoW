helm install cilium cilium/cilium --version 1.18.6 \
  --namespace kube-system \
  --set ipam.mode=kubernetes \
  --set kubeProxyReplacement=true \
  --set securityContext.capabilities.ciliumAgent="{CHOWN,KILL,NET_ADMIN,NET_RAW,IPC_LOCK,SYS_ADMIN,SYS_RESOURCE,DAC_OVERRIDE,FOWNER,SETGID,SETUID}" \
  --set securityContext.capabilities.cleanCiliumState="{NET_ADMIN,SYS_ADMIN,SYS_RESOURCE}" \
  --set cgroup.autoMount.enabled=false \
  --set cgroup.hostRoot=/sys/fs/cgroup \
  --set k8sServiceHost=localhost \
  --set k8sServicePort=7445 \
  --set bgpControlPlane.enabled=true \
  --set l2announcements.enabled=true \
  --set externalIPs.enabled=true \
  --set bpf.hostLegacyRouting=true
  --set gatewayAPI.enabled=true

https://docs.cilium.io/en/stable/installation/k8s-install-helm/
https://docs.siderolabs.com/kubernetes-guides/cni/deploying-cilium
https://docs.cilium.io/en/stable/helm-reference/
