# Kubernetes Workshop - Part 2

## 1. Persistent Volumes (PV) & Persistent Volume Claims (PVC)

### 1.1 What is a Persistent Volume (PV)?

* **Persistent Volume (PV)**: A cluster-wide storage resource managed by Kubernetes. It represents actual physical storage from your infrastructure (local disk, NFS, cloud provider disks, etc.).
* Exists **independently of pods** and retains data beyond the lifecycle of individual pods.
* Can be provisioned manually (static) or automatically (dynamic) through StorageClasses.

**YAML Example:**

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: my-pv
spec:
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: standard
  hostPath:
    path: /mnt/data
```

---

### 1.2 Types of PV

**1. Static Provisioning**

* In static provisioning, the administrator manually creates PV objects in advance.
* PVs are pre-configured with specific storage capacity, access modes, and backend details.

**Types of Static Provisioning:**

1. **HostPath** – Uses a directory on the node’s filesystem (for single-node testing only).
2. **NFS (Network File System)** – Uses a shared directory from an NFS server.
3. **Cloud Provider Static Disks** – Pre-created volumes in AWS, Azure, GCP manually bound to PVs.

**Example (NFS-based Static PV):**

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: static-nfs-pv
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  storageClassName: manual
  nfs:
    path: /data
    server: 10.0.0.5
```

**2. Dynamic Provisioning**

* In dynamic provisioning, Kubernetes automatically creates a PV when a PVC is made.
* Requires a **StorageClass** that defines the provisioner (e.g., AWS EBS, GCE PD, Ceph).
* Ideal for environments where storage needs change frequently.

**Example:**

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: dynamic-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  storageClassName: gp2
```

*This PVC will automatically create a PV using the `gp2` StorageClass provisioner.*

---

### 1.3 What is a Persistent Volume Claim (PVC)?

* A **request for storage** by a user/application.
* PVCs are bound to PVs that match the request's size, access mode, and StorageClass.

**YAML Example:**

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: standard
```

---

### 1.4 PVC Access Modes

* **ReadWriteOnce (RWO)** – Mounted as read-write by a single node.
* **ReadOnlyMany (ROX)** – Mounted read-only by many nodes.
* **ReadWriteMany (RWX)** – Mounted read-write by many nodes.
* **ReadWriteOncePod (RWOP)** – Mounted as read-write by a single pod only (Kubernetes 1.22+).

---

### 1.5 Reclaim Policies

* **Retain** – PV and data are preserved after PVC deletion (manual cleanup required).
* **Delete** – PV and its storage are deleted automatically after PVC deletion.
* **Recycle** (deprecated) – Basic wipe of data, then reused.

---

### 1.6 StorageClass

* Defines provisioner and parameters for dynamic PV creation.
* Specifies reclaim policy and binding mode.

**Volume Binding Mode:**

* **Immediate** – PV is bound to PVC as soon as PVC is created, regardless of which node will use it.
* **WaitForFirstConsumer** – PV is bound to PVC only when a pod that uses the PVC is scheduled. This ensures the storage is provisioned in the correct zone/region for that node.

**YAML Example:**

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: standard
provisioner: kubernetes.io/aws-ebs
parameters:
  type: gp2
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
```

---

## 2. Mounting PVC, ConfigMap, and Secrets in Pods

### 2.1 Pod mounting PVC, ConfigMap, and Secret together

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-pod
spec:
  containers:
  - name: app
    image: nginx
    volumeMounts:
    - name: pvc-storage
      mountPath: /usr/share/nginx/html
    - name: config-vol
      mountPath: /etc/config
    - name: secret-vol
      mountPath: /etc/secret
  volumes:
  - name: pvc-storage
    persistentVolumeClaim:
      claimName: my-pvc
  - name: config-vol
    configMap:
      name: my-config
  - name: secret-vol
    secret:
      secretName: my-secret
```

(Assumes `my-pvc`, `my-config`, and `my-secret` are created separately.)

---

### 2.2 Mounting ConfigMap as Volume

```yaml
volumes:
- name: config-vol
  configMap:
    name: my-config
volumeMounts:
- name: config-vol
  mountPath: /etc/config
```

---

### 2.3 Mounting Secret as Volume

```yaml
volumes:
- name: secret-vol
  secret:
    secretName: my-secret
volumeMounts:
- name: secret-vol
  mountPath: /etc/secret
```

---

## 3. StatefulSet in Kubernetes

### 3.1 Definition

* A **StatefulSet** manages the deployment and scaling of a set of Pods, and provides guarantees about the ordering and uniqueness of these Pods.
* Ideal for stateful applications such as databases, Kafka, or Redis.

**Pod Naming and Creation Order:**

* Pods are created sequentially: `pod-0`, `pod-1`, `pod-2`, etc.
* When scaling down, pods are removed in reverse order.
* Each pod gets a persistent identifier and storage that is reused if the pod is rescheduled.

**Pod DNS Names with Headless Service:**

* Each pod can be accessed with the pattern:

  ```
  <pod-name>.<service-name>.<namespace>.svc.cluster.local
  ```

  Example:

  ```
  web-0.nginx.default.svc.cluster.local
  ```

**YAML Example:**

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web
spec:
  serviceName: "nginx"
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
        volumeMounts:
        - name: www
          mountPath: /usr/share/nginx/html
  volumeClaimTemplates:
  - metadata:
      name: www
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 1Gi
```

---

### 3.2 Difference from Deployment

| Feature      | Deployment          | StatefulSet                          |
| ------------ | ------------------- | ------------------------------------ |
| Pod Identity | Random              | Stable, ordered (pod-0, pod-1...)    |
| Storage      | Shared or ephemeral | Dedicated persistent storage per pod |
| Scaling      | Parallel            | Ordered creation/deletion            |
| Use Cases    | Stateless apps      | Databases, queues, clustered apps    |

---

### 3.3 VolumeClaimTemplate

* Template in StatefulSet spec to generate PVC for each pod automatically.
* Ensures each pod has its own independent storage.

---

### 3.4 Headless Service

* A Service with `clusterIP: None` that allows direct DNS resolution to each pod.

**YAML Example:**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx
spec:
  clusterIP: None
  selector:
    app: nginx
  ports:
  - port: 80
```

---

## 4. DaemonSet in Kubernetes

### 4.1 What is a DaemonSet?
- A **DaemonSet** ensures that a copy of a Pod runs on all or a subset of nodes in the cluster based on selectors, affinities, or tolerations.
- Common use cases:
  * Log collection agents (e.g., Fluentd, Filebeat) so each node ships its logs.
  * Monitoring agents (e.g., Prometheus node exporter) to gather node-level metrics.
  * Networking components (CNI plugins like Calico or Cilium) that need a presence on every node.
  * Security/inspection agents that require node-level visibility.

### 4.2 Behavior and Guarantees
- Pods are created on existing nodes and automatically scheduled on new nodes as they join the cluster.
- Removal happens when nodes are removed; DaemonSet pods are not scaled by replica count but driven by node matching rules.
- Placement can be constrained with `nodeSelector`, `affinity`, or `tolerations` (e.g., exclude control-plane nodes or target only Linux nodes).

### 4.3 YAML Example
```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: node-exporter
  labels:
    app: node-exporter
spec:
  selector:
    matchLabels:
      app: node-exporter
  template:
    metadata:
      labels:
        app: node-exporter
    spec:
      containers:
      - name: node-exporter
        image: prom/node-exporter:latest
        ports:
        - containerPort: 9100
        volumeMounts:
        - name: proc
          mountPath: /host/proc
          readOnly: true
        - name: sys
          mountPath: /host/sys
          readOnly: true
        args:
        - --path.procfs=/host/proc
        - --path.sysfs=/host/sys
      hostNetwork: true
      hostPID: true
      volumes:
      - name: proc
        hostPath:
          path: /proc
      - name: sys
        hostPath:
          path: /sys
```
---

## 5. Jobs and CronJobs in Kubernetes

### 5.1 Jobs

* A **Job** creates one or more Pods and ensures that a specified number of them successfully complete.
* Common use cases:

  * Data processing tasks
  * Database migrations
  * One-time batch jobs
* Jobs can run Pods in parallel, retry failed Pods, and control completion behavior.

**Key Fields:**

* **parallelism**: Number of pods that can run in parallel.
* **completions**: Number of successfully completed pods required for the job to be considered complete.
* **backoffLimit**: Number of retries before the job is marked as failed.
* **restartPolicy**: Pod restart policy, usually `OnFailure` or `Never`.

**YAML Example:**

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: example-job
spec:
  parallelism: 2
  completions: 4
  backoffLimit: 3
  template:
    spec:
      restartPolicy: never
      containers:
      - name: pi
        image: perl
        command: ["perl", "-Mbignum=bpi", "-wle", "print bpi(200)"]
```

---

### 5.2 CronJobs

* A **CronJob** creates Jobs on a repeating schedule, similar to Unix/Linux cron.
* Common use cases:

  * Nightly backups
  * Regular report generation
  * Scheduled cleanup tasks

**Key Fields:**

* **schedule**: Cron format string specifying when to run.
* **concurrencyPolicy**: Controls job concurrency.

  * `Allow` – Run jobs concurrently.
  * `Forbid` – Skip new job if previous is still running.
  * `Replace` – Replace currently running job with a new one.
* **suspend**: If `true`, suspends subsequent executions.

**YAML Example:**

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: example-cronjob
spec:
  schedule: "*/5 * * * *" # Every 5 minutes
  concurrencyPolicy: Forbid
  suspend: false
  jobTemplate:
    spec:
      backoffLimit: 2
      template:
        spec:
          restartPolicy: OnFailure
          containers:
          - name: hello
            image: busybox
            args:
            - /bin/sh
            - -c
            - date; echo Hello from Kubernetes CronJob
```
---

## Summary

* **PV**: Cluster-managed storage resource.
* **PVC**: Storage request by a pod.
* **Access Modes**: RWO, ROX, RWX, RWOP.
* **Reclaim Policies**: Retain, Delete, Recycle.
* **StorageClass**: Defines dynamic provisioning and volume binding behavior.
* **StatefulSet**: Stable IDs, storage, ordered deployment, and predictable DNS names.
* **Headless Service**: Provides DNS for each pod in a StatefulSet.
* **DaemonSet**: Ensures a pod runs on all or selected nodes for node-level workloads.
* **Job**: Runs tasks to completion.
* **CronJob**: Runs jobs on a schedule.
