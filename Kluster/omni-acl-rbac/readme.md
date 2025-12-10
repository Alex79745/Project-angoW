1. Why Omni Is Needed (Equivalent to AWS IAM + EKS Access Entry)

In EKS:

AWS IAM manages identity (users, roles)

aws_eks_access_entry maps IAM → Kubernetes

Kubernetes RBAC determines permissions inside the cluster

In Omni (Talos clusters):

Omni replaces all AWS IAM & EKS access logic.

Omni Provides:
Function	AWS Equivalent
Omni Users	IAM Users
Omni Groups	IAM Groups
AccessPolicy	aws_eks_access_entry
Kubernetes Impersonation Groups	kubernetes_groups
Kubeconfig with OIDC plugin	aws eks get-token

So Omni is your identity provider + RBAC mapping engine.

⚙️ 2. When You Create a User in Omni — What Happens?

When you add a user in Omni:

User logs in via Omni Portal

Omni generates a kubeconfig for that user

The kubeconfig contains a special OIDC plugin

When the user runs kubectl:

Omni verifies identity

Omni checks your AccessPolicy

Omni injects impersonation groups

Kubernetes RBAC uses those groups to allow/deny access

Meaning:

Omni decides who the user is and assigns a group
Kubernetes RBAC decides what they can do

Exactly like AWS IAM + EKS access entry.

🧠 3. Basic RBAC Concepts (Clear & Simple)
ClusterRole

Defines a list of permissions

Works cluster-wide

Example:

ClusterRole: can list/watch pods in every namespace

Role

Same idea but only inside one namespace

Example:

Role: can list/watch pods only in namespace `online-boutique`

RoleBinding

Connects Role ⇢ User/Group

Only used inside a namespace

ClusterRoleBinding

Connects ClusterRole ⇢ User/Group

Global permissions

⚙️ 4. How Omni and Kubernetes RBAC Work Together

Let’s compare:

AWS EKS Flow
IAM User -> Access Entry -> kubernetes_groups -> RBAC

Talos Omni Flow
Omni User -> AccessPolicy -> impersonate.groups -> RBAC


It is exactly the same architecture, only the mechanism changes.

📌 5. Example Flow (Admin + Developer + CI/CD)
Omni Access Policy

Equivalent to your EKS access entry:

admin  -> impersonate group: system:masters
dev    -> impersonate group: dev-online-boutique
ci     -> impersonate group: system:masters

Kubernetes RBAC

Bind system:masters → full cluster

Bind dev-online-boutique → namespaced role

🔥 6. Why Omni Is Required (Especially for Talos)

Talos clusters do not have IAM, and do not support the AWS token generator.
You must use Omni for:

Authentication

User identity

Access mapping

Kubeconfig generation

Impersonation groups

Without Omni, there is no secure way to provide user access to Talos clusters.

📘 7. Official Omni Documentation
🔗 ACL (AccessPolicy)

https://docs.siderolabs.com/omni/reference/acls/

🔗 Managing ACLs

https://docs.siderolabs.com/omni/security-and-authentication/how-to-manage-acls/

🔗 API Reference for AccessPolicy

https://docs.siderolabs.com/omni/reference/acls/#accesspolicy

🔗 Using kubectl with Omni

https://docs.siderolabs.com/omni/getting-started/use-kubectl-with-omni/

🔗 CLI (omnictl) for managing YAML

https://docs.siderolabs.com/omni/reference/cli/


🟢 8. correct order

export OMNICTL_SERVER=https://omni-web.omnilocalwebxaaas.dpdns.org
export OMNICTL_AUTH_TOKEN="<jwt>"
Aplicar:

omnictl apply -f groups.yaml
omnictl apply -f group-members.yaml
omnictl apply -f access-policy.yaml
Depois Kubernetes:

kubectl apply -f namespace.yaml
kubectl apply -f developer-role.yaml
kubectl apply -f developer-binding.yaml
kubectl apply -f admin-cluster-role.yaml
kubectl apply -f admin-cluster-binding.yaml
