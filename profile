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



##################

Use statements like these — results-oriented, senior, and impact driven:

Example Responsibilities (Portuguese / English):

Desenvolvimento e entrega de uma arquitetura de malha de serviço (service mesh) em produção usando Consul OSS e Envoy, para resolver descoberta de serviços, roteamento dinâmico e identidade de serviço.

Concepção e implementação de uma solução de entrada (ingress) segura e escalável, combinando BGP (Cilium), Bird2 e Envoy, suportando tráfego TLS com descoberta de backends via xDS/EDS.

Integração de serviços Kubernetes e máquinas virtuais externas, com roteamento por SNI/host e descoberta automática de instâncias via Consul, incluindo túneis de tráfego e políticas de intenção (intentions).

Garantia de conectividade multi-cluster e planeamento para cenário hub-spoke com Consul e Submariner, removendo dependência de ingressos estáticos e reduzindo custos operacionais.

Responsável pelo ciclo completo de desenvolvimento: projeto, deploy, monitorização e troubleshooting, com documentação técnica associada e validação de performance e segurança.

Manutenção e evolução contínua da plataforma, incluindo integração de operacionalização de tráfego real com proxies Envoy, política zero-trust de serviços, e melhorias de UX para acessos externos via VIP.

👉 Write them in first person if required, e.g.:

“Responsável por projetar e implementar…” etc.
End-to-end architecture

Hybrid (VM + Kubernetes)

L4 + L7 networking

Service mesh ownership

Ingress strategy

Operational model definition

Knowledge transfer (workshops)
