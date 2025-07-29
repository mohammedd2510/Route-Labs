# 🚀 ArgoCD Lab: GitOps with K3D and Sealed Secrets

## 🧠 Overview

This lab demonstrates GitOps in action using ArgoCD on a local Kubernetes environment powered by K3D. You'll:

- Create a K3D cluster
- Install and configure ArgoCD with Helm
- Deploy a sample app using ArgoCD Application CRD
- Perform automated updates via Git
- Secure sensitive data using Sealed Secrets

---

## 🧱 Step 1: Create a Local Kubernetes Cluster with K3D

Use the following command to create a multi-node Kubernetes cluster with 1 server and 2 agents:

```bash
k3d cluster create mycluster \
  --agents 2 \
  --port "80:80@loadbalancer" \
  --k3s-arg "--kubelet-arg=--resolv-conf=/etc/resolv.conf@agent:*" \
  --k3s-arg "--kubelet-arg=--resolv-conf=/etc/resolv.conf@server:0"
```

### 🔍 Explanation of Flags:

- `--agents 2`: Creates 2 worker nodes in addition to the single server node.
- `--port "80:80@loadbalancer"`: Maps port 80 on your local machine to port 80 on the cluster's load balancer, enabling access to HTTP services running inside the cluster (e.g., ArgoCD UI).
- `--k3s-arg "--kubelet-arg=--resolv-conf=/etc/resolv.conf@agent:*"`: Ensures all agent nodes use the system DNS resolver, which avoids issues with default resolv.conf in containerized environments.
- `--k3s-arg "--kubelet-arg=--resolv-conf=/etc/resolv.conf@server:0"`: Applies the same DNS fix to the server node, ensuring consistency in DNS resolution.

These settings help ensure that services like ArgoCD, which depend on hostname resolution, work smoothly inside the cluster.

---

## 🔀 Step 2: Switch Kubernetes Context to Your New Cluster

Change your current kubectl context to the one created by K3D:

```bash
kubectl config use-context k3d-mycluster
```

---

## 📦 Step 3: Add and Download the ArgoCD Helm Chart

Add the Argo Helm repository and pull the chart locally:

```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm pull argo/argo-cd --version 8.2.2
tar -xzf argo-cd-8.2.2.tgz
```

---

## 🛠️ Step 4: Configure ArgoCD via values.yaml

Edit the extracted `values.yaml` file to expose the ArgoCD UI via ingress:

```yaml
config:
  params:
    server.insecure: true

server:
  ingress:
    enabled: true
    hosts:
      - argocd.local
```

---

## 🧱 Step 5: Install ArgoCD in the Cluster

Create a dedicated namespace and install ArgoCD using Helm:

```bash
kubectl create namespace argocd
helm install argocd ./argo-cd -n argocd -f values.yaml
```

---

## 🛍️ Step 6: Configure Local DNS for ArgoCD

Edit your machine’s hosts file to route traffic to your ArgoCD UI:

- **Linux/macOS:** `/etc/hosts`
- **Windows:** `C:\Windows\System32\drivers\etc\hosts`

Add:

```
<EC2_PUBLIC_IP>    argocd.local
```

---

## 🌐 Step 7: Access and Login to the ArgoCD UI

Visit `http://argocd.local` in your browser.

To retrieve the initial admin password:

```bash
kubectl -n default get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

---

## 📁 Step 8: Create a GitHub Repo with Kubernetes Manifests

Organize your manifests in the following structure:

```
argocd-lab/
└── k8s-manifests/
    ├── deployment.yaml
    ├── service.yaml
    └── ingress.yaml
```

### 📄 deployment.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: argocd-lab
spec:
  replicas: 1
  selector:
    matchLabels:
      app: argocd-lab
  template:
    metadata:
      labels:
        app: argocd-lab
    spec:
      containers:
        - name: argocd-lab
          image: mosama25/argocd-lab:v1.0
          ports:
            - containerPort: 8080
```

### 📄 service.yaml

```yaml
apiVersion: v1
kind: Service
metadata:
  name: argocd-lab
spec:
  selector:
    app: argocd-lab
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8080
  type: ClusterIP
```

### 📄 ingress.yaml

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-lab
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
    - host: argocd-lab.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: argocd-lab
                port:
                  number: 80
```

---

## 📦 Step 9: Deploy the App via ArgoCD Application CRD

Create a file named `app.yaml` with this ArgoCD Application definition:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: argocd-lab-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/your-user/your-repo.git
    targetRevision: main
    path: argocd-lab/k8s-manifests
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      selfHeal: true
      prune: true
    syncOptions:
      - CreateNamespace=true
```

Apply with:

```bash
kubectl apply -f app.yaml
```

---

## 🚀 Step 10: Access the Deployed App

Add another line to your `/etc/hosts` or Windows hosts file:

```
<EC2_PUBLIC_IP>    argocd-lab.local
```

Visit `http://argocd-lab.local` to see your deployed application.

---

## 🔀 Step 11: Trigger a Sync by Updating Git

To simulate a deployment update:

- Change the container image tag in `deployment.yaml` to `v2.0`
- Commit and push to GitHub
- ArgoCD will automatically sync the change and redeploy

---

## 🔐 Step 12: Install Sealed Secrets for GitOps Secrets Management

Install the Sealed Secrets CLI and controller:

```bash
curl -OL "https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.30.0/kubeseal-0.30.0-linux-amd64.tar.gz"
tar -xvzf kubeseal-0.30.0-linux-amd64.tar.gz kubeseal
sudo install -m 755 kubeseal /usr/local/bin/kubeseal
rm -rf kubeseal*
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.30.0/controller.yaml
```

---

## 🔒 Step 13: Create and Encrypt a Kubernetes Secret

Now that Sealed Secrets is installed in your cluster, you can securely create and encrypt Kubernetes secrets for GitOps workflows.

### ✅ Generate a Kubernetes Secret:

```bash
kubectl create secret generic test-secret \
  --dry-run=client \
  --from-literal=key1=value1 \
  -o yaml > test-secret.yaml
```

### 🔒 Encrypt the Secret Using kubeseal:

```bash
kubeseal --format yaml < test-secret.yaml > sealed-secret.yaml
```

Now push `sealed-secret.yaml` to your Git repository. Once ArgoCD detects the update, it will decrypt and apply the secret to your cluster using the controller running in the background.

### 🔍 Verify the Secret:

```bash
kubectl get secrets
```

You should see `test-secret` among the listed secrets, confirming successful encryption and decryption.

---

## 🌟 Learning Objectives Recap

By completing this lab, you have:

✅ **Created a local Kubernetes cluster with K3D** — including multi-node setup and custom port/DNS configuration.

✅ **Installed ArgoCD using Helm** — and exposed its UI via ingress for browser-based GitOps management.

✅ **Deployed applications via Git** — by defining and applying an ArgoCD Application CRD linked to a GitHub repo.

✅ **Enabled automated synchronization** — with `selfHeal` and `prune` policies that reflect Git as the source of truth.

✅ **Secured sensitive data with Sealed Secrets** — by encrypting secrets before committing to Git and managing them declaratively.

You now have hands-on experience with a full GitOps lifecycle, from infrastructure provisioning to secure CI/CD operations, using ArgoCD and Sealed Secrets on a local Kubernetes cluster.

