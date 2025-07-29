# 🚀 GitOps and Argo CD Lecture Notes

## 📘 What is GitOps?

**GitOps** is a modern DevOps practice that uses Git as the single source of truth for declarative infrastructure and application configurations. It relies on automation tools to ensure that the state in Git is continuously synchronized with the actual state in a Kubernetes cluster.

### 🔑 GitOps Principles

* **Declarative**: All desired system states (infrastructure, apps) are stored as code in Git.
* **Versioned and Immutable**: Git provides version control, audit trails, and rollback capability.
* **Pulled Automatically**: A GitOps operator (e.g., Argo CD) continuously reconciles the state from Git to the cluster.
* **Continuously Reconciled**: Any divergence between Git and the live state is automatically corrected.

---

## 🏗️ GitOps Architecture

```text
                +------------------+
                |     Developer    |
                +--------+---------+
                         |
                         v
                 Git Push to Repo
                         |
                         v
                +------------------+
                | Git Repository   |
                | (Infra / App)    |
                +--------+---------+
                         |
                         v
                +------------------+
                |   GitOps Tool    | <------------------+
                |   (e.g., ArgoCD) |                    |
                +--------+---------+                    |
                         |                              |
              Syncs with Cluster                Reconciles State
                         |                              |
                         v                              |
              +--------------------+                    |
              | Kubernetes Cluster |---------------------+
              +--------------------+
```

---

## 🎯 Argo CD — GitOps in Action

**Argo CD** is a declarative, GitOps continuous delivery tool for Kubernetes.

### 💡 Key Features

* Sync Kubernetes resources from Git repositories
* Supports Helm, Kustomize, Jsonnet, and plain YAML
* RBAC, SSO, Web UI, and CLI
* Health status monitoring
* Automated syncing or manual promotion
* Rollbacks and diff comparisons

---

## 📦 Argo CD Custom Resource Definitions (CRDs)

Argo CD uses Kubernetes CRDs to manage applications. The most important CRD is:

### `Application`

This CRD defines a single app to deploy.

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/example/my-repo
    targetRevision: HEAD
    path: k8s-manifests
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

### 🔑 Explanation of Important Keys

| Key                     | Description                                                                                                                           |
| ----------------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| `project`               | Logical grouping of applications                                                                                                      |
| `source.repoURL`        | Git repository URL                                                                                                                    |
| `source.path`           | Path inside the repo to the manifest                                                                                                  |
| `targetRevision`        | Git branch, tag, or commit                                                                                                            |
| `destination.server`    | K8s cluster API server                                                                                                                |
| `destination.namespace` | Namespace to deploy                                                                                                                   |
| `syncPolicy.automated`  | Enables auto-sync of the application. Combined with `prune` and `selfHeal`, it makes the cluster state self-correcting.               |
| `prune`                 | Automatically deletes Kubernetes resources that were removed from Git. Keeps cluster clean and consistent.                            |
| `selfHeal`              | Automatically fixes drifted or modified resources to match the declared Git state. Ensures enforcement of Git as the source of truth. |
| `syncOptions`           | Extra sync behaviors (e.g., auto namespace creation)                                                                                  |

---

## 🔐 Managing Secrets in GitOps with Sealed Secrets

In GitOps, secrets are stored in Git, so encryption is essential.

### 🛡️ What is Sealed Secrets?

**Sealed Secrets** (by Bitnami) is a Kubernetes controller and CLI (`kubeseal`) that encrypts secrets which can safely be committed to Git. The controller decrypts them in the cluster.

### ↻ How It Works

1. You create a Kubernetes Secret.
2. Use `kubeseal` to encrypt it into a `SealedSecret`.
3. Commit `SealedSecret` to Git.
4. Argo CD applies the `SealedSecret` to the cluster.
5. The Sealed Secrets controller decrypts it into a normal Secret.

### ✍️ Sample `SealedSecret`

```yaml
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
  name: my-secret
  namespace: default
spec:
  encryptedData:
    password: AgBj+2x...
  template:
    metadata:
      name: my-secret
      namespace: default
```

---

## 🔗 Integrating Sealed Secrets with GitOps

Sealed Secrets can be integrated with any Git-based workflow to manage secrets securely within GitOps. Here's how to use Sealed Secrets with Argo CD:

### ✅ Step-by-Step

1. **Encrypt Secrets** locally using `kubeseal`:

   ```bash
   kubectl create secret generic my-secret --dry-run=client --from-literal=password=mypassword -o yaml > secret.yaml
   kubeseal --format=yaml < secret.yaml > sealedsecret.yaml
   ```

2. **Commit `sealedsecret.yaml`** to your Git repository (GitHub, GitLab, etc.).

3. **Configure Argo CD** to point to your Git repository:

   ```yaml
   source:
     repoURL: https://github.com/your-org/your-repo.git
     targetRevision: main
     path: manifests/
   ```

4. **Deploy Argo CD** in your cluster, along with the **Sealed Secrets Controller**:


5. Argo CD syncs the `SealedSecret` → Sealed Secrets Controller decrypts → Creates usable K8s `Secret`.

## 📚 Summary

* GitOps uses Git as the single source of truth for infrastructure and apps.
* Argo CD is a GitOps tool that automates the synchronization between Git and Kubernetes.
* CRDs like `Application` define how apps are deployed.
* Sealed Secrets enable secure secret management in GitOps.

---

🧐 *"GitOps isn't just about automation; it's about treating infrastructure the same way you treat code — with discipline, traceability, and security."*
