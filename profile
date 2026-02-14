Skills demonstrated (rare combo)

You are actively combining:

Consul (OSS)

Envoy

Cilium

BGP (BIRD)

Kubernetes internals

Zero-trust networking

Hub-and-spoke multi-cluster thinking

CNFC / Well-Architected mindset
Senior Platform Engineer
----
Designed and implemented a cloud-native ingress and service discovery architecture using Consul (OSS), Envoy, and Cilium, enabling secure, scalable access to Kubernetes services without relying on traditional ingress controllers.

Built a hub-and-spoke architecture where:

External traffic is routed via BGP-advertised virtual IPs into an Envoy-based edge gateway

Service discovery and routing are handled dynamically via xDS (EDS/CDS/RDS) from Consul

Kubernetes workloads are identified by service identity (sidecar-based) rather than static IPs

Load balancers are treated as transport only, decoupled from service identity

Implemented TLS termination and passthrough at the edge, dynamic hostname-based routing, and zero-trust service communication using Consul intentions.

Designed the platform to support multi-cluster expansion (hub/spoke) and future cross-cluster connectivity, minimizing operational overhead while remaining 100% open-source.

Delivered the full design and implementation independently, including architecture, debugging, and production validation.
