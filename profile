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
I am responsible for the end-to-end design, implementation, and operation of the platform ingress and service connectivity architecture,
spanning Kubernetes and VM-based environments. This includes L4/L7 traffic handling, service mesh integration, and production routing decisions.
I currently act as the primary knowledge holder for this stack and am leading internal knowledge transfer to reduce operational risk.

------------------------------------------------------------------------------------

Make it your conversation
Use this form as a guide to the topics you would like to discuss during the annual Contribution Dialog (What is Contribution?). It is not mandatory to fill in all fields. Although the questions are asked from the perspective of the associate, both dialog partners should prepare from their perspective. The questions should be an inspiration for you - you decide which aspects should be the focus of the conversation.

 

 

Prepare yourself
The quality of the conversation depends to a large extent on the preparation of all participants. You can prepare the notes in the tool (visible for all dialog partners) or offline in any form (e.g. with this preparation template).You can ask your colleagues for additional feedback to gather more perspectives for your further development. You can use Bosch Competence Model as a basis for your dialog.

 

 

Stay flexible
Close this form only at the end of the year together with the goal achievement (in the "Dialog Notes" step). This way you can always adjust the goals or add notes from interim meetings. You can also attach documents (e.g. goals and goal achievement from other tools, for example, OKR) to the dialog form. Note: Attachments will only be available in HR Global during the retention period and will not be archived afterwards. Please do not attach any salary related documents.

 

 
Meeting Details
Dialog Date Year Planning	
03/30/2026
Additional Dialog Partners	
|||
Size
||

 



 
Job Responsibility
Our Comments	
|||
Size
||

 
Motivation
Motivation
Describe your motivation and strengths.
• Which topics or tasks motivate me? What would I like to do more / less of?
• Which tasks fit my strengths?
• What else is important to me (e.g. working conditions, special projects/exposure, work content, further development, compensation, etc.)?

Our Comments	
|||
Size
||

 
My Contribution/Goals (Results | Learning | Collaboration)

Create New
Contribution Goals

(Results | Learning | Collaboration)

 

By fulfilling your tasks, you contribute to achieving excellent business results.

 

Together with your manager, define 4-6 goals that are crucial for your success and the success of the company.

Please ensure that the following is taken into account when setting tasks and goals, as well as evaluating the achievement:

• Your contribution to results and competitiveness: Effect on profitability / liquidity / growth. In addition, strengthening competitiveness and the Lead Work Win #LikeABosch focus points.
• Your contribution to long-term success and sustainability: Continuously striving for improvements to achieve the best for customers, associates and society

 

Take compliance into account, especially the provisions in the Code of Conduct.

 

Expand AllCollapse All
Goal
 
Learning & Development
Learning & Development
Describe your ideas for personal development and the support you need. Watch this video to get inspired.
• In which topics can I gain new or more experience?
• What competencies and skills do I want to build?
• What are your recommendations for my further development?
 

Our Comments	
|||
Size
||

 
Development Measures

Create New
Expand AllCollapse All
Goal
 
CptM
We confirm that we have conducted CptM Process and discussed the requirements (e.g. for CptM-Curricula, strategic competencies and/or individual learning measures).
We confirm that we have conducted CptM Process and discussed the requirements (e.g. for CptM-Curricula, strategic competencies and/or individual learning measures).
 
Compliance
At Bosch, Compliance means that we abide by laws, observe the Code of Conduct and adhere to other internal rules in our daily work for the Bosch Group
I have read the Code of Conduct and all internal regulations relevant to my work and will carry out my tasks in accordance with them. If I have questions, I contact my supervisor, or the Compliance Organization. Possible violations can be reported via our reporting system.

I have read the Code of Conduct and all internal regulations relevant to my work and will carry out my tasks in accordance with them. If I have questions, I contact my supervisor or the Compliance Organization. Possible violations can be reported via our reporting system "Speak up!“ also anonymously. I am aware that whistleblowers are afforded special protection.
 



 
Dialog Date Year Review
Dialog Date Year Review	
 
Positive Highlights & Successes
Positive Highlights & Successes
Describe your positive highlights, successes, and contribution.
• What positive highlights and successes have I had recently?  Which am I proud of?
• What did I contribute to achieve our common goals?
• What new skills, experiences and knowledge have I gained?
• What do I still want to work on?

Our Comments	
|||
Size
||

 
Appreciation & Collaboration
Appreciation & Collaboration
Describe your team collaboration in regard to knowledge sharing, feedback culture, dealing with failures.
• What do I appreciate about working with you / our team / our network?
• What feedback have I received about collaborating with me?
• What are your recommendations for my further development in terms of collaboration?

Our Comments	
|||
Size
||

 
Other topics
Other topics
This is your place to note other topics connected to contribution if you wish to do so.
