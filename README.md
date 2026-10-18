# StreamFlix — Secure CI/CD Deployment on Azure Kubernetes Service

[![StreamFlix AKS CI/CD](https://github.com/georgelolu/streamflix-aks/actions/workflows/deploy.yml/badge.svg?branch=main)](https://github.com/georgelolu/streamflix-aks/actions/workflows/deploy.yml)
![Platform](https://img.shields.io/badge/platform-Azure%20AKS-0078D4)
![Container](https://img.shields.io/badge/container-Docker-2496ED)
![Infrastructure](https://img.shields.io/badge/deployment-Kubernetes-326CE5)
![Authentication](https://img.shields.io/badge/authentication-OIDC-2E8B57)

A containerized streaming-service interface deployed to **Azure Kubernetes Service (AKS)** through a GitHub Actions CI/CD pipeline. The project demonstrates container hardening, Azure workload authentication with OpenID Connect (OIDC), Azure Container Registry (ACR), Kubernetes deployment automation, health checks, and namespace-scoped deployment permissions.

**Repository:** https://github.com/georgelolu/streamflix-aks

## Project overview

StreamFlix is a lightweight streaming-platform UI served by NGINX. Its container image is built from source, pushed to Azure Container Registry, and deployed to an existing AKS cluster by GitHub Actions.

The deployment uses immutable Git commit SHA image tags, two application replicas, Kubernetes readiness and liveness probes, resource requests and limits, and a ClusterIP service. The application is kept internal to the cluster; local verification is performed with Kubernetes port forwarding rather than exposing a new public LoadBalancer.

## Architecture

```mermaid
flowchart TD
    Dev["Developer pushes to main"]
    Repo["GitHub repository"]
    Actions["GitHub Actions workflow"]
    OIDC["Microsoft Entra ID<br/>Federated OIDC identity"]
    ACR["Azure Container Registry<br/>Immutable commit-SHA image"]
    AKS["Existing Azure Kubernetes Service cluster"]
    NS["streamflix namespace"]
    SVC["ClusterIP Service<br/>port 80"]
    P1["StreamFlix Pod 1<br/>NGINX :8080"]
    P2["StreamFlix Pod 2<br/>NGINX :8080"]
    Check["Rollout and health verification"]

    Dev --> Repo --> Actions
    Actions --> OIDC
    Actions --> ACR
    Actions --> AKS
    ACR --> AKS
    AKS --> NS
    NS --> SVC
    SVC --> P1
    SVC --> P2
    P1 --> Check
    P2 --> Check
Deployment flow
1. A change to website/**, k8s/**, or the workflow file on main triggers GitHub Actions. A manual workflow dispatch is also supported.
2. GitHub Actions authenticates to Azure using OIDC federation, without storing a long-lived Azure client secret in GitHub.
3. Docker builds the StreamFlix image and tags it with the Git commit SHA.
4. The workflow pushes the image to ACR.
5. The workflow obtains AKS credentials and configures kubelogin.
6. Kubernetes applies the Service and the Deployment with the matching commit-SHA image tag.
7. The workflow waits for the Deployment rollout and checks the resulting Kubernetes resources.
Technology stack
AreaTechnology
ApplicationHTML, CSS, JavaScript
Web serverNGINX Alpine
Container buildDocker
Container registryAzure Container Registry
Kubernetes platformAzure Kubernetes Service
Deployment automationGitHub Actions
Azure authenticationMicrosoft Entra ID workload federation (OIDC)
Kubernetes access controlNamespace-scoped Role and RoleBinding
Health and availabilityKubernetes readiness/liveness probes and rollout checks
Repository structure
streamflix-aks/
├── .github/
│   └── workflows/
│       └── deploy.yml
├── docs/
│   ├── architecture.md
│   └── evidence/
│       ├── README.md
│       ├── collect-evidence.sh
│       └── deployment-verification.txt
├── k8s/
│   ├── deployment.yaml
│   ├── namespace.yaml
│   └── service.yaml
└── website/
    ├── .dockerignore
    ├── Dockerfile
    ├── app.js
    ├── index.html
    ├── nginx.conf
    └── styles.css


CI/CD workflow
The workflow is defined in .github/workflows/deploy.yml.
It builds and pushes a versioned image, then deploys that exact version to AKS. Deployment automation is triggered by relevant changes on main or by a manual workflow dispatch.
GitHub Actions configuration
The workflow reads these non-secret GitHub repository variables:
VariablePurpose
AZURE_CLIENT_IDFederated application client ID
AZURE_TENANT_IDMicrosoft Entra tenant ID
AZURE_SUBSCRIPTION_IDAzure subscription ID
ACR_NAMEACR resource name
ACR_LOGIN_SERVERACR image hostname
AKS_RESOURCE_GROUPAKS resource group
AKS_CLUSTER_NAMEAKS cluster name
No client secret is required by this workflow. Keep credentials, access tokens, and other secrets out of source control and evidence files.
Image versioning
Images are tagged using ${GITHUB_SHA}. This makes each pipeline-built image identifiable by the source commit and avoids relying on a mutable latest tag for deployments.
Deployment verification
After applying the Kubernetes manifests, the workflow waits for the Deployment rollout and retrieves the Deployment and Pod status. A successful workflow indicates that its configured steps completed successfully; ongoing application health should also be checked independently.
Security and reliability controls
Identity and access
- OIDC federation: GitHub Actions exchanges a short-lived federated identity token for Azure authentication rather than relying on a persistent client secret.
- Branch-scoped federation: The configured federated credential is restricted to the repository's main branch subject.
- Registry permissions: The deployment identity has AcrPush on the StreamFlix pipeline's ACR.
- Cluster access: The identity uses the AKS Cluster User role to obtain cluster credentials.
- Kubernetes RBAC: A dedicated Role and RoleBinding restrict deployment permissions to the streamflix namespace. The role allows the workflow's required deployment, Service, ReplicaSet, Pod, and event operations; it does not grant cluster-wide Kubernetes administrator permissions.
- No new public application endpoint: StreamFlix uses a ClusterIP Service, avoiding an additional public LoadBalancer.
Container hardening
The Docker image and Kubernetes manifest are configured with these controls:
- NGINX runs as a non-root user (101:101) on an unprivileged application port (8080).
- Kubernetes sets runAsNonRoot, allowPrivilegeEscalation: false, and drops Linux capabilities.
- The container root filesystem is read-only, with a writable temporary volume mounted for required temporary files.
- The seccomp profile uses RuntimeDefault.
- Kubernetes resource requests and limits help constrain resource consumption.
- Readiness and liveness probes use the /health endpoint.
These settings reduce container privileges and improve operational predictability; they do not replace image scanning, patch management, network controls, or runtime monitoring.
Kubernetes configuration
The manifests under k8s/ define the StreamFlix namespace, Deployment, and Service.
SettingConfigured value
Namespacestreamflix
Deploymentstreamflix
Replicas2
Container port8080
Service typeClusterIP
Service port80
Health endpoint/health
Image tagGit commit SHA in the CI/CD pipeline
The manifests use an image placeholder for the registry image. The CI/CD workflow substitutes the actual ACR hostname and commit SHA when applying the Deployment.
Local development
Requirements: Docker and a shell.
Build the image:
docker build -t streamflix:local ./website


Run the container:
docker run --rm --name streamflix-local -p 8088:8080 streamflix:local


In another terminal, verify the application:
curl -fsS http://localhost:8088/health


Expected health response:
healthy


Open http://localhost:8088 in a browser to view the interface. Stop the local container with Ctrl+C in the terminal running Docker.
Verify the AKS deployment
Prerequisites: Azure CLI, kubectl, access to the existing AKS cluster, and appropriate permissions.
kubectl get namespace streamflix
kubectl rollout status deployment/streamflix -n streamflix
kubectl get deployment streamflix -n streamflix
kubectl get pods -n streamflix
kubectl get service streamflix -n streamflix
kubectl get deployment streamflix -n streamflix \
  -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'


For an application-level check, forward local port 8088 to the Service's port 80:
kubectl port-forward -n streamflix service/streamflix 8088:80


Keep that command running, then use a second terminal:
curl -fsS http://localhost:8088/health
curl -I http://localhost:8088/


The health endpoint should return healthy; the website should return a successful HTTP response.
Evidence and validation
The docs/evidence/ directory contains a reproducible evidence collection script and the deployment verification record. Evidence should be refreshed when the deployment or workflow changes.
The initial end-to-end validation recorded for this project includes:
- GitHub Actions run 39134172236 completed successfully.
- The deployed Deployment reported 2/2 ready replicas.
- Both StreamFlix Pods were reported Running and ready, with zero restarts at the time checked.
- The application root returned HTTP 200 OK.
- The /health endpoint returned healthy.
See docs/evidence/README.md for how to reproduce these checks. The verification text file should reflect the latest locally collected results, not merely historical results.
Troubleshooting
GitHub Actions cannot authenticate to Azure
- Confirm the repository variables match the intended Azure tenant, subscription, and application.
- Confirm the federated credential issuer, audience, and subject match GitHub's token claims for this repository and branch.
- Confirm the workflow has id-token: write.
- Check Azure role assignments and Kubernetes RBAC separately; Azure authentication alone does not guarantee Kubernetes authorization.
Pods fail to start or become ready
kubectl describe deployment streamflix -n streamflix
kubectl get pods -n streamflix
kubectl describe pods -n streamflix
kubectl logs deployment/streamflix -n streamflix
kubectl get events -n streamflix --sort-by=.lastTimestamp


Check the image name and tag, ACR pull permissions, container port, probe path, security context, and resource constraints.
Rollout does not complete
kubectl rollout status deployment/streamflix -n streamflix --timeout=180s
kubectl rollout history deployment/streamflix -n streamflix


Review Pod events and logs before attempting a rollback or changing the running deployment.
Local port forwarding fails
Check that the Service exists, Pods are ready, and local port 8088 is not already in use. Keep kubectl port-forward running while making requests.
Known follow-up improvements
- Review and update GitHub Actions versions when compatible releases are available.
- Add automated container vulnerability scanning and a defined remediation policy.
- Consider a separate non-production environment and a controlled promotion process.
- Add centralized metrics, logs, alerting, and an explicit rollback procedure.
- Consider infrastructure-as-code for repeatable provisioning of the identity, registry permissions, and Kubernetes access policy.
Interview talking points
Be prepared to explain:
1. How OIDC federation avoids long-lived Azure credentials in GitHub Actions.
2. Why images are tagged by commit SHA and how the deployed image can be traced to source.
3. The difference between Azure RBAC and Kubernetes RBAC.
4. Why a namespace-scoped Role is safer than granting cluster-admin access.
5. How non-root execution, a read-only root filesystem, dropped capabilities, and probes improve container security and reliability.
6. How you verified the workflow, Deployment readiness, Service, and health endpoint.
7. What you would improve next for production readiness, observability, and release safety.
Project status
The documented deployment has completed a successful CI/CD run and passed the recorded application and Kubernetes checks. See the linked workflow and evidence records for the run details. This is a hands-on demonstration project; it is not a claim of a fully production-certified streaming platform.

Maintained by georgelolu.
