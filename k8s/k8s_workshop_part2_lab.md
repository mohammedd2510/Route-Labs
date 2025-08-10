# Kubernetes Workshop - Part 2 — Labs

This file contains the **hands-on labs** for the workshop topics. Each lab includes objectives, YAML manifests, and a separate **Commands** section right after the YAML to describe the key commands for running and analyzing the lab.

---

## Lab 1 — Static PV, PVC, and Pod

**Goal:** Create a static PersistentVolume and a PersistentVolumeClaim, then attach the PVC to a Pod.

### pv.yaml
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: static-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: manual
  hostPath:
    path: /mnt/static-data
```

### pvc.yaml
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: static-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: manual
```

### pod.yaml
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pvc-pod
spec:
  containers:
  - name: app
    image: nginx
    volumeMounts:
    - name: storage
      mountPath: /usr/share/nginx/html
  volumes:
  - name: storage
    persistentVolumeClaim:
      claimName: static-pvc
```

**Commands:**

* `kubectl apply -f pv.yaml` — Creates the static PersistentVolume resource.  
* `kubectl apply -f pvc.yaml` — Creates the PersistentVolumeClaim that binds to the PV.  
* `kubectl apply -f pod.yaml` — Deploys a Pod that mounts the PVC.  
* `kubectl get pv,pvc` — Lists the current PVs and PVCs with their statuses.  
* `kubectl describe pod pvc-pod` — Shows detailed information about the pod, including mounted volumes.  

---

## Lab 2 — Dynamic Provisioning with Custom StorageClass

**Goal:** Create a custom StorageClass, a PVC using it, and attach it to a Pod.

### sc.yaml
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: custom-sc
provisioner: rancher.io/local-path
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
```

### pvc.yaml
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
      storage: 1Gi
  storageClassName: custom-sc
```

### pod.yaml
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: dynamic-pvc-pod
spec:
  containers:
  - name: app
    image: nginx
    volumeMounts:
    - name: storage
      mountPath: /usr/share/nginx/html
  volumes:
  - name: storage
    persistentVolumeClaim:
      claimName: dynamic-pvc
```

**Commands:**

* `kubectl apply -f sc.yaml` — Creates the custom StorageClass.  
* `kubectl apply -f pvc.yaml` — Creates the PVC that triggers dynamic provisioning.  
* `kubectl apply -f pod.yaml` — Deploys the Pod using the dynamically provisioned volume.  
* `kubectl get pv,pvc` — Displays PVs and PVCs to confirm automatic PV creation.  
* `kubectl describe pvc dynamic-pvc` — Shows details and events for the dynamically created PVC.  

---

## Lab 3 — StatefulSet with Headless Service & VolumeClaimTemplate

**Goal:** Deploy a StatefulSet with a headless Service, test pod DNS, and verify per-pod PVC creation and ordered termination.

### headless-svc.yaml
```yaml
apiVersion: v1
kind: Service
metadata:
  name: web
spec:
  clusterIP: None
  selector:
    app: web
  ports:
  - port: 80
```

### sts.yaml
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web
spec:
  serviceName: "web"
  replicas: 2
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
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
      storageClassName: custom-sc
```

**Commands:**

* `kubectl apply -f headless-svc.yaml` — Creates a headless Service for direct pod DNS resolution.  
* `kubectl apply -f sts.yaml` — Deploys the StatefulSet.  
* `kubectl get pods` — Lists pods to observe the predictable, ordered naming convention.  
* `kubectl get pvc` — Displays PVCs to confirm each pod has its own claim.  
* `kubectl exec -it web-0 -- nslookup web-0.web` — Tests DNS resolution of the current pod.  
* `kubectl exec -it web-0 -- nslookup web-1.web` — Tests DNS resolution of a peer pod.  
* `kubectl delete sts web` — Deletes the StatefulSet.  
* `kubectl get pods` — Observes the ordered termination of pods.  

---

## Lab 4 — DaemonSet on All Nodes

**Goal:** Deploy a DaemonSet and verify it runs on every node.

### ds.yaml
```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: node-info
spec:
  selector:
    matchLabels:
      app: node-info
  template:
    metadata:
      labels:
        app: node-info
    spec:
      containers:
      - name: node-info
        image: busybox
        command: ["sh", "-c", "sleep 3600"]
```

**Commands:**

* `kubectl apply -f ds.yaml` — Creates the DaemonSet.  
* `kubectl get pods -o wide` — Lists pods with node information to verify each node has a pod.  

---

## Lab 5 — Job with Completions and Parallelism

**Goal:** Create a Job with `completions: 4` and `parallelism: 2`.

### job.yaml
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: calc-pi
spec:
  completions: 4
  parallelism: 2
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: pi
        image: perl
        command: ["perl", "-Mbignum=bpi", "-wle", "print bpi(200)"]
```

**Commands:**

* `kubectl apply -f job.yaml` — Creates the Job.  
* `kubectl get jobs` — Displays the Job and its completion status.  
* `kubectl get pods --watch` — Watches pod creation and completion in parallel.  

---

## Lab 6 — CronJob

**Goal:** Create a CronJob and verify it creates Jobs and Pods.

### cronjob.yaml
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: hello
spec:
  schedule: "*/2 * * * *"
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: OnFailure
          containers:
          - name: hello
            image: busybox
            args:
            - /bin/sh
            - -c
            - date; echo Hello from Kubernetes
```

**Commands:**

* `kubectl apply -f cronjob.yaml` — Creates the CronJob.  
* `kubectl get cronjobs` — Shows the CronJob configuration.  
* `kubectl get jobs --watch` — Watches Jobs being created on schedule.  
* `kubectl get pods --watch` — Watches Pods being created by Jobs.  


---

