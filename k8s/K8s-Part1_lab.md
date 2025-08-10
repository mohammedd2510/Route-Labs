# Kubernetes Practical Lab

This hands-on lab is designed to help students practice working with core Kubernetes resources in a structured, task-based format. All resources will be created inside a dedicated namespace to maintain isolation.

---

## 🎯 Lab Objectives

* Manage Pods, ReplicaSets, Deployments
* Perform rollouts and rollbacks
* Expose applications using ClusterIP and NodePort Services
* Use ConfigMaps and Secrets for configuration management

---

## 🧱 1. Setup: Create a Namespace

```bash
kubectl create namespace k8s-lab
kubectl config set-context --current --namespace=k8s-lab
```

---

## 🚀 2. Pod: Run a Simple Frontend

### pod.yaml

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
spec:
  containers:
  - name: frontend
    image: nginx:latest
    ports:
    - containerPort: 80
```

### Commands

```bash
kubectl apply -f pod.yaml
kubectl exec -it nginx-pod -- curl localhost
```

✅ You should see output from the frontend app.

---

## ⚙️ 3. ReplicaSet: NGINX with Auto Healing

### replicaset.yaml

```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: nginx-rs
spec:
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
        image: nginx:latest
        ports:
        - containerPort: 80
```

### Commands

```bash
kubectl apply -f replicaset.yaml
kubectl get pods -l app=nginx
kubectl delete pod <any-nginx-pod-name>
# Observe how the ReplicaSet creates a replacement pod automatically

kubectl scale rs nginx-rs --replicas=1
```

---

## 🔄 4. Deployment: Rolling Updates and Rollbacks

### deployment.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend-deploy
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: frontend
        image: mosama25/argocd-lab:v1.0
        ports:
        - containerPort: 80
```

### Commands

```bash
kubectl apply -f deployment.yaml
kubectl set image deployment/frontend-deploy frontend=mosama25/argocd-lab:v2.0
kubectl rollout status deployment/frontend-deploy
kubectl rollout undo deployment/frontend-deploy
```

✅ Watch the old Pods get replaced by the new ones.

---

## 🌐 5. Services: Access Your App

### A. ClusterIP (Internal Access)

```yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend-clusterip
spec:
  selector:
    app: frontend
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
  type: ClusterIP
```

```bash
kubectl apply -f clusterip-service.yaml
kubectl run test-client --rm -it --image=busybox -- /bin/sh
# Inside busybox:
curl http://frontend-clusterip
```

### B. NodePort (External Access)

```yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend-nodeport
spec:
  selector:
    app: frontend
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
    nodePort: 32000
  type: NodePort
```

```bash
kubectl apply -f nodeport-service.yaml
kubectl get service frontend-nodeport
# Access using Node IP and NodePort (e.g., http://<node-ip>:30036)
```

---

## 🔐 6. SQL App with ConfigMap and Secret

### A. ConfigMap: sql-config.yaml

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: sql-config
  namespace: k8s-lab
data:
  DB_NAME: labdb
```

### B. Secret: sql-secret.yaml

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: sql-secret
  namespace: k8s-lab
stringData:
  DB_PASS: supersecret
```

### C. MySQL Deployment: mysql.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql
        image: mysql:5.7
        env:
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: sql-secret
              key: DB_PASS
        - name: MYSQL_DATABASE
          valueFrom:
            configMapKeyRef:
              name: sql-config
              key: DB_NAME
        ports:
        - containerPort: 3306
---
apiVersion: v1
kind: Service
metadata:
  name: mysql-service
spec:
  selector:
    app: mysql
  ports:
  - port: 3306
    targetPort: 3306
```

### D. Apply & Test

```bash
kubectl apply -f sql-config.yaml
kubectl apply -f sql-secret.yaml
kubectl apply -f mysql.yaml
kubectl run mysql-client --rm -it --image=mysql:5.7 -- \
  mysql -h mysql-service -u root -p
# Enter password: supersecret
# After login:
SHOW DATABASES;
```

✅ If `labdb` appears in the list, the ConfigMap and Secret are correctly applied.

---

## ✅ Lab Summary

By completing this lab, students will be able to:

* Isolate resources in a namespace
* Create and manage Pods, ReplicaSets, and Deployments
* Observe ReplicaSet self-healing behavior
* Perform rolling updates and rollbacks
* Expose applications using ClusterIP and NodePort
* Securely inject configuration using ConfigMaps and Secrets


