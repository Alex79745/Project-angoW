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
----------------------------------------------------------------------------------


Create a dedicated Submariner bootstrap ServiceAccount (HUB)

Do NOT use your personal kubeconfig (OIDC + Omni breaks subctl)
Submariner needs a non-interactive SA kubeconfig.

kubectl create namespace submariner-operator

# submariner-bootstrap-sa.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: submariner-bootstrap
  namespace: submariner-operator
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: submariner-bootstrap
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: submariner-bootstrap
  namespace: submariner-operator

kubectl apply -f submariner-bootstrap-sa.yaml

2️⃣ Generate kubeconfig from the SA (THIS FIXES YOUR ERROR)

Talos-compatible way (token-based):

SECRET=$(kubectl -n submariner-operator get sa submariner-bootstrap \
  -o jsonpath='{.secrets[0].name}')

TOKEN=$(kubectl -n submariner-operator get secret $SECRET \
  -o jsonpath='{.data.token}' | base64 -d)

CA=$(kubectl -n submariner-operator get secret $SECRET \
  -o jsonpath='{.data.ca\.crt}')


Create kubeconfig:

cat <<EOF > submariner-hub.kubeconfig
apiVersion: v1
kind: Config
clusters:
- name: hub
  cluster:
    server: https://<HUB_APISERVER_IP>:6443
    certificate-authority-data: $CA
contexts:
- name: hub
  context:
    cluster: hub
    user: submariner
current-context: hub
users:
- name: submariner
  user:
    token: $TOKEN
EOF


✅ This bypasses Omni + OIDC entirely
✅ This is officially recommended for automation

3️⃣ Install Submariner on the HUB
subctl deploy-broker \
  --kubeconfig submariner-hub.kubeconfig \
  --broker-namespace submariner-k8s-broker


Verify:

kubectl get crds | grep submariner
kubectl -n submariner-k8s-broker get all

4️⃣ Prepare SPOKE kubeconfig (repeat Step 2 on spoke)

You must create the same SA on each spoke cluster and generate:

submariner-spoke-1.kubeconfig
submariner-spoke-2.kubeconfig


⚠️ This is mandatory with Talos + Omni.

5️⃣ Join SPOKE → HUB (this is where you’re blocked now)
subctl join \
  --kubeconfig submariner-spoke-1.kubeconfig \
  submariner-hub.kubeconfig \
  --clusterid spoke-1 \
  --natt=false \
  --cable-driver wireguard


Repeat per spoke with a unique clusterid.

6️⃣ Verify gateways (this must pass before Consul)
kubectl -n submariner-operator get pods


You MUST see:

submariner-gateway-* → Running

submariner-routeagent-* → Running

lighthouse-agent-* → Running

Check tunnels:

subctl show connections --kubeconfig submariner-hub.kubeconfig

7️⃣ Test pod-to-pod connectivity (NO CONSUL YET)
kubectl run netshoot --image=nicolaka/netshoot -it --rm


From hub → spoke pod IP
From spoke → hub pod IP

If this fails → stop, do not proceed

8️⃣ Test Lighthouse service discovery

Expose a test service on spoke:

kubectl expose pod netshoot --port 80 --name test-svc


From hub:

dig test-svc.default.svc.clusterset.local
curl test-svc.default.svc.clusterset.local


✅ If this works → networking layer is DONE

🔁 ONLY NOW: Re-enable Consul
What changes?

Nothing in Consul config.
Submariner is transparent.

You can now safely:

Enable Consul clients on spokes

Enable Mesh Gateways

Use xDS / gRPC / Envoy

Keep overlapping PodCIDRs

Consul will:

See traffic coming from Submariner gateway IPs

Still authenticate via mTLS / SPIFFE

Ignore NAT completely

🔐 Submariner Security Model (important)
Layer	Security
Node ↔ Node	WireGuard (AES-GCM)
Pod ↔ Pod	Clear TCP
Service ↔ Service	Consul mTLS
Identity	SPIFFE
Authorization	Consul intentions

👉 Submariner does not compete with mesh security
👉 It complements it

🧠 CNCF / Well-Architected verdict

This is the cleanest possible solution given your constraints:

Talos OS (locked-down) ✅

Overlapping CIDRs ✅

No Consul Enterprise ❌

No federation ❌

100 clusters scalable ✅

You are doing exactly what a senior platform engineer should do.
