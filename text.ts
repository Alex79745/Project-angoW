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

##############################################################################################################################################

##################################################################################

apiVersion: cilium.io/v2alpha1
kind: CiliumBGPAdvertisement
metadata:
  name: advertise-loadbalancers
  labels:
    advertise: "true" # Label used for selection
spec:
  # In 1.17, these must be in a list
  advertisements:
    - advertisementType: "Service"
      service:
        addresses:
          - "LoadBalancerIP"
      # This selector is optional; leave empty {} to advertise all LB services
      selector:
        matchLabels: {}
#######################################################################################################################

###############################################


# 1. Update your existing ClusterConfig to use a PeerConfigRef
apiVersion: cilium.io/v2alpha1
kind: CiliumBGPClusterConfig
metadata:
  name: bgp-config
spec:
  nodeSelector:
    matchLabels:
      cilium-bgp: "enabled"
  bgpInstances:
    - name: "instance-64513"
      localASN: 64513
      peers:
        - name: "proxmox-host"
          peerASN: 64512
          peerAddress: "192.168.1.138"
          peerConfigRef:
            name: "proxmox-peer-config" # Link to the new PeerConfig

---
# 2. Create the PeerConfig to hold the advertisement selector
apiVersion: cilium.io/v2alpha1
kind: CiliumBGPPeerConfig
metadata:
  name: "proxmox-peer-config"
spec:
  families:
    - afi: ipv4
      safi: unicast
      advertisements:
        matchLabels:
          advertise: "true" # This selects the Advertisement resource below

---
# 3. Create the Advertisement with matching labels
apiVersion: cilium.io/v2alpha1
kind: CiliumBGPAdvertisement
metadata:
  name: "bgp-advertisements"
  labels:
    advertise: "true" # Matches the PeerConfig selector above
spec:
  advertisements:
    - advertisementType: "Service"
      service:
        addresses:
          - "LoadBalancerIP"
###############################################

apiVersion: gateway.networking.k8s.io/v1
kind: GRPCRoute
metadata:
  name: consul-grpc-route
  namespace: consul
spec:
  parentRefs:
    - name: cilium-ingress # Points to your Cilium Gateway
  rules:
    - matches:
        - method:
            service: "consul.v1.ConfigEntryService" # Or relevant Consul gRPC service
      backendRefs:
        - name: consul-server
          port: 8502

###################################################

# Save as gateway-class.yaml
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: envoy-gateway
spec:
  controllerName: gateway.envoyproxy.io/gatewayclass-controller
###################################################################

apiVersion: "cilium.io/v2alpha1"
kind: CiliumLoadBalancerIPPool
metadata:
  name: "management-pool"
spec:
  blocks:
    - cidr: "192.168.1.240/29" # Assigns IPs .200 through .207




time="2026-05-04T15:52:36Z" level=error msg="Failed to dial steve aggregation server: read tcp 10.244.1.45:55668->10.19.143.82:443: read: connection reset by peer"      │
│ time="2026-05-04T15:52:36Z" level=warning msg="[2] encountered error \"write tcp 10.244.1.45:57512->10.19.143.74:443: write: broken pipe\" while writing error \"tunnel  │
│ time="2026-05-04T15:52:36Z" level=error msg="Remotedialer proxy error" error="read tcp 10.244.1.45:57512->10.19.143.74:443: read: connection reset by peer"              │
│ time="2026-05-04T15:52:36Z" level=warning msg="[2] encountered error \"write tcp 10.244.1.45:57512->10.19.143.74:443: write: broken pipe\" while writing error \"writeto │
│ time="2026-05-04T15:52:46Z" level=error msg="Failed to dial steve aggregation server: read tcp 10.244.1.45:44736->10.19.143.74:443: read: connection reset by peer"      │
│ time="2026-05-04T15:52:46Z" level=info msg="Connecting to wss://rancher-klusterx.de.bosch.com/v3/connect with token starting with prc8rgw97spjtzvnn2skw6hnlqt"           │
│ time="2026-05-04T15:52:46Z" level=info msg="Connecting to proxy" url="wss://rancher-klusterx.de.bosch.com/v3/connect"                                                    │
│ time="2026-05-04T15:52:46Z" level=info msg="Connected to proxy" url="wss://rancher-klusterx.de.bosch.com/v3/connect"                                                     │
│ time="2026-05-04T15:52:51Z" level=error msg="Remotedialer proxy error" error="read tcp 10.244.1.45:41276->10.19.143.82:443: read: connection reset by peer"              │
│ time="2026-05-04T15:52:56Z" level=error msg="Failed to dial steve aggregation server: read tcp 10.244.1.45:58720->10.19.143.82:443: read: connection reset by peer"      │
│ time="2026-05-04T15:53:01Z" level=info msg="Connecting to wss://rancher-klusterx.de.bosch.com/v3/connect with token starting with prc8rgw97spjtzvnn2skw6hnlqt"           │
│ time="2026-05-04T15:53:01Z" level=info msg="Connecting to proxy" url="wss://rancher-klusterx.de.bosch.com/v3/connect"                                                    │
│ time="2026-05-04T15:53:01Z" level=info msg="Connected to proxy" url="wss://rancher-klusterx.de.bosch.com/v3/connect"                                                     │
│ time="2026-05-04T15:53:06Z" level=error msg="Failed to dial steve aggregation server: read tcp 10.244.1.45:54604->10.19.143.74:443: read: connection reset by peer"      │
│ time="2026-05-04T15:53:06Z" level=error msg="Remotedialer proxy error" error="read tcp 10.244.1.45:54614->10.19.143.74:443: read: connection reset by peer"              │
│ time="2026-05-04T15:53:16Z" level=error msg="Failed to dial steve aggregation server: read tcp 10.244.1.45:50798->10.19.143.82:443: read: connection reset by peer"      │
│ time="2026-05-04T15:53:16Z" level=info msg="Connecting to wss://rancher-klusterx.de.bosch.com/v3/connect with token starting with prc8rgw97spjtzvnn2skw6hnlqt"           │
│ time="2026-05-04T15:53:16Z" level=info msg="Connecting to proxy" url="wss://rancher-klusterx.de.bosch.com/v3/connect"                                                    │
│ time="2026-05-04T15:53:16Z" level=info msg="Connected to proxy" url="wss://rancher-klusterx.de.bosch.com/v3/connect"                                                     │
│ time="2026-05-04T15:53:21Z" level=error msg="Remotedialer proxy error" error="read tcp 10.244.1.45:34906->10.19.143.74:443: read: connection reset by peer"              │
│ time="2026-05-04T15:53:26Z" level=error msg="Failed to dial steve aggregation server: read tcp 10.244.1.45:55152->10.19.143.82:443: read: connection reset by peer"      │
│ time="2026-05-04T15:53:31Z" level=info msg="Connecting to wss://rancher-klusterx.de.bosch.com/v3/connect with token starting with prc8rgw97spjtzvnn2skw6hnlqt"           │
│ time="2026-05-04T15:53:31Z" level=info msg="Connecting to proxy" url="wss://rancher-klusterx.de.bosch.com/v3/connect"                                                    │
│ time="2026-05-04T15:53:31Z" level=info msg="Connected to proxy" url="wss://rancher-klusterx.de.bosch.com/v3/connect"                                                     │
│ time="2026-05-04T15:53:36Z" level=error msg="Failed to dial steve aggregation server: read tcp 10.244.1.45:52876->10.19.143.74:443: read: connection reset by peer"      │
│ time="2026-05-04T15:53:36Z" level=warning msg="[2] encountered error \"write tcp 10.244.1.45:52882->10.19.143.74:443: write: broken pipe\" while writing error \"tunnel  │
│ time="2026-05-04T15:53:36Z" level=error msg="Remotedialer proxy error" error="read tcp 10.244.1.45:52882->10.19.143.74:443: read: connection reset by peer"              │
│ time="2026-05-04T15:53:36Z" level=warning msg="[2] encountered error \"write tcp 10.244.1.45:52882->10.19.143.74:443: write: broken pipe\" while writing error \"dial tc │
│ time="2026-05-04T15:53:46Z" level=error msg="Failed to dial steve aggregation server: read tcp 10.244.1.45:60800->10.19.143.82:443: read: connection reset by peer"      │
│ time="2026-05-04T15:53:46Z" level=info msg="Connecting to wss://rancher-klusterx.de.bosch.com/v3/connect with token starting with prc8rgw97spjtzvnn2skw6hnlqt"           │
│ time="2026-05-04T15:53:46Z" level=info msg="Connecting to proxy" url="wss://rancher-klusterx.de.bosch.com/v3/connect"                                                    │
│ time="2026-05-04T15:53:46Z" level=info msg="Connected to proxy" url="wss://rancher-klusterx.de.bosch.com/v3/connect"                                                     │
│ time="2026-05-04T15:53:50Z" level=warning msg="[2] encountered error \"write tcp 10.244.1.45:45476->10.19.143.74:443: write: broken pipe\" while writing error \"tunnel  │
│ time="2026-05-04T15:53:50Z" level=error msg="Remotedialer proxy error" error="read tcp 10.244.1.45:45476->10.19.143.74:443: read: connection reset by peer"              │
│ time="2026-05-04T15:53:50Z" level=warning msg="[2] encountered error \"write tcp 10.244.1.45:45476->10.19.143.74:443: write: broken pipe\" while writing error \"writeto │
│ time="2026-05-04T15:53:56Z" level=error msg="Failed to dial steve aggregation server: read tcp 10.244.1.45:51740->10.19.143.74:443: read: connection reset by peer"      │
│ time="2026-05-04T15:54:00Z" level=info msg="Connecting to wss://rancher-klusterx.de.bosch.com/v3/connect with token starting with prc8rgw97spjtzvnn2skw6hnlqt"           │
│ time="2026-05-04T15:54:00Z" level=info msg="Connecting to proxy" url="wss://rancher-klusterx.de.bosch.com/v3/connect"                                                    │
│ time="2026-05-04T15:54:00Z" level=info msg="Connected to proxy" url="wss://rancher-klusterx.de.bosch.com/v3/connect"                                    
