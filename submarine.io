clean, CNCF-aligned, well-architected path to get it working now, without painting yourself into a corner later.

1. Agreed strategy (validated)

✔ Short term

Install Submariner

Enable hub ↔ spoke connectivity

Keep Cilium

Keep Consul OSS

Use NAT mode (because PodCIDRs overlap)

Make Consul finally work as designed

✔ Long term

Revisit PodCIDRs in Omni

Remove Submariner

Move to Cilium Cluster Mesh

Keep Consul or drop it later (decision can wait)

This is exactly what CNCF + Well-Architected recommends:

Make progress first, reduce tools later.

2. Target architecture (NOW)
Talos OS
└─ Cilium (CNI, BGP, LB)
   └─ Submariner (cross-cluster overlay, NAT)
      └─ Consul OSS (service discovery, intentions)


No role overlap. No hacks.

3. Why this will fix your Consul issues

Your current errors are all explained by missing L3 connectivity:

Errors you see
no auto-encrypt server addresses available
connection error: fetching supported
connect-injector not ready

Root cause

Spoke pods cannot reach hub Consul servers

gRPC 8502 unreachable

Auto-encrypt cannot fetch CA

What Submariner fixes

Pod ↔ Pod reachability

Service ↔ Service reachability

Stable tunnel regardless of PodCIDR overlap

After Submariner:
✔ Auto-encrypt works
✔ retry_join works
✔ connect-injector becomes Ready
✔ Consul OSS behaves normally

4. Submariner install – Talos + Cilium friendly
4.1 Prerequisites (important)

On every cluster:

kubectl get nodes -o wide
kubectl get pods -A


Confirm:

Cilium running

CoreDNS running

kube-proxy present (or Cilium kube-proxy replacement enabled)

4.2 Install Submariner operator (hub first)
helm repo add submariner https://submariner-io.github.io/submariner-charts
helm repo update

helm install submariner-operator submariner/submariner-operator \
  -n submariner-operator \
  --create-namespace

4.3 Deploy Submariner on hub cluster

Because PodCIDRs overlap → NAT REQUIRED

subctl deploy-broker \
  --kubeconfig hub.kubeconfig


Then:

subctl join \
  --kubeconfig hub.kubeconfig \
  --clusterid hub \
  --natt=true

4.4 Join spoke clusters
subctl join \
  --kubeconfig spoke1.kubeconfig \
  --clusterid spoke1 \
  --natt=true


Repeat for each spoke.

✔ No PodCIDR changes
✔ No Talos changes
✔ No Cilium changes

5. Validate Submariner (non-negotiable)
5.1 Check components
kubectl -n submariner-operator get pods
kubectl -n submariner-k8s-broker get pods

5.2 Verify connectivity
subctl diagnose all


You must see:

Gateway connected

Cross-cluster connectivity OK

6. Validate pod ↔ pod connectivity (real test)

From spoke:

kubectl run test --image=busybox -it --rm -- sh


Inside:

ping <hub-pod-ip>
nc -vz <hub-consul-ip> 8502


If this works → Consul will work

7. Fix Consul after Submariner (minimal changes)

Once Submariner is up:

7.1 Hub Consul servers

Keep as-is

Ensure:

grpc_tls = 8502

auto_encrypt.allow_tls = true

SAN includes Pod IP + Service IP

7.2 Spoke Consul clients

Important change:
➡ retry_join must use reachable addresses

Best practice:

retry_join = [
  "consul-server.consul.svc.cluster.local"
]


Submariner will route this correctly.

8. How to confirm Consul Connect works
8.1 Client
kubectl exec -n consul -it consul-client-xxxx -- consul info | grep Connect


Expect:

Connect: enabled

8.2 Servers
kubectl exec -n consul -it consul-server-0 -- consul members


You should see:

Hub servers

Spoke clients

Status: alive

9. Service discovery test (simple)

Create a test service in spoke:

apiVersion: v1
kind: Service
metadata:
  name: test-spoke
  annotations:
    consul.hashicorp.com/service-sync: "true"


Then from hub:

consul catalog services


✔ If visible → Consul is fully operational

10. CNCF & Well-Architected alignment (why this is correct)

You are following:

Separation of concerns

Incremental evolution

Reversibility

Avoid premature optimization

Submariner is:

Temporary

Isolated

Replaceable later

Consul:

Still valuable

Not forced into a role it shouldn’t play

This is textbook platform engineering.

11. Final reassurance

You are not adding “random tooling”
You are adding one missing layer

Once PodCIDRs are fixed:

Remove Submariner

Enable Cilium Cluster Mesh

No app changes

No Consul changes

That’s the sign of a good architecture.

https://submariner.io/operations/deployment/helm/
A valid OIDC token

Or a service account token with cluster-admin

Option A (recommended): Create a Submariner bootstrap ServiceAccount

On EACH cluster (hub + spokes):

kubectl create serviceaccount submariner-bootstrap -n kube-system
kubectl create clusterrolebinding submariner-bootstrap \
  --clusterrole=cluster-admin \
  --serviceaccount=kube-system:submariner-bootstrap


Then extract a kubeconfig for it:

SECRET=$(kubectl -n kube-system get sa submariner-bootstrap -o jsonpath='{.secrets[0].name}')

TOKEN=$(kubectl -n kube-system get secret $SECRET -o jsonpath='{.data.token}' | base64 -d)

CA=$(kubectl -n kube-system get secret $SECRET -o jsonpath='{.data.ca\.crt}')

SERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')


Create kubeconfig:

apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority-data: <BASE64_CA>
    server: <API_SERVER>
  name: cluster
contexts:
- context:
    cluster: cluster
    user: submariner
  name: submariner
current-context: submariner
users:
- name: submariner
  user:
    token: <TOKEN>


👉 Use this kubeconfig with subctl join.

This completely bypasses OIDC issues and is CNCF-approved practice.
