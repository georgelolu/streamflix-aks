# StreamFlix Deployment Evidence

This directory contains reproducible verification evidence for the StreamFlix
application deployed to Azure Kubernetes Service (AKS).

## Files

- `collect-evidence.sh` — collects the current Git, Kubernetes, deployment,
  image, Service, and application health information.
- `deployment-verification.txt` — output from the most recent evidence
  collection. Results are time-specific and should be refreshed after a
  deployment change.

## Prerequisites

- Access to the existing AKS cluster.
- Azure CLI and `kubectl` configured for that cluster.
- `curl` and Git installed.
- The StreamFlix deployment and Service deployed in namespace `streamflix`.

## Collect evidence

From the repository root, run:

```bash
./docs/evidence/collect-evidence.sh
For the application health check to pass, keep the following command running
in a separate terminal:
kubectl port-forward -n streamflix service/streamflix 8088:80


The application health endpoint should return healthy.
CI/CD evidence
Review the GitHub Actions workflow and its run history:
https://github.com/georgelolu/streamflix-aks/actions/workflows/deploy.yml
A successful workflow run demonstrates that its configured steps completed.
The Kubernetes rollout and application health checks provide additional
deployment verification.
Handling evidence safely
Refresh the verification file when relevant infrastructure or application
changes occur. Review the generated output before committing it. Do not include
access tokens, credentials, client secrets, kubeconfig contents, or other
sensitive information in committed evidence.
