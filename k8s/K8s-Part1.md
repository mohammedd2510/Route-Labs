# Kubernetes Basics Lecture

## Table of Contents
1. [What is Kubernetes?](#what-is-kubernetes)
2. [Kubernetes Features](#kubernetes-features)
3. [Kubernetes Architecture](#kubernetes-architecture)
4. [Master Node Components](#master-node-components)
5. [Worker Node Components](#worker-node-components)
6. [Kubernetes Objects](#kubernetes-objects)
7. [Services](#services)
8. [Configuration Management](#configuration-management)

---

## What is Kubernetes?

Kubernetes (K8s) is an open-source container orchestration platform that automates the deployment, scaling, and management of containerized applications. Originally developed by Google, it provides a robust framework for running distributed systems resiliently.

**Key Benefits:**
- Automated deployment and scaling
- Self-healing capabilities
- Load balancing and service discovery
- Rolling updates and rollbacks
- Resource optimization

---

## Kubernetes Features

### 1. **Container Orchestration**
- Manages containers across multiple hosts
- Ensures containers are running and healthy

### 2. **Auto-scaling**
- Horizontal Pod Autoscaler (HPA)
- Vertical Pod Autoscaler (VPA)
- Cluster Autoscaler

### 3. **Self-healing**
- Automatically restarts failed containers
- Replaces and reschedules containers when nodes die
- Kills containers that don't respond to health checks

### 4. **Load Balancing**
- Distributes network traffic across multiple containers
- Built-in service discovery

### 5. **Rolling Updates and Rollbacks**
- Zero-downtime deployments
- Easy rollback to previous versions

### 6. **Secret and Configuration Management**
- Manages sensitive information securely
- Separates configuration from application code

---

## Kubernetes Architecture

Kubernetes follows a master-worker architecture pattern. The cluster consists of:

- **Master Node (Control Plane)**: Manages the cluster and makes global decisions
- **Worker Nodes**: Run the actual application workloads

![Kubernetes Architecture](https://miro.medium.com/v2/resize:fit:1100/format:webp/1*HHRp0HENvfAu2hXT8Gto9g.png)

The architecture ensures high availability, scalability, and fault tolerance through distributed components that work together to maintain the desired state of applications.

---

## Master Node Components

The Master Node (Control Plane) contains several critical components that manage the entire cluster:

### 1. **API Server**
- **Purpose**: Central management entity and entry point for all REST commands
- **Functions**:
  - Validates and configures data for API objects
  - Serves as the frontend to the cluster's shared state
  - All components communicate through the API server

### 2. **etcd (Key-Value Store)**
- **Purpose**: Distributed key-value store that stores all cluster data
- **Functions**:
  - Stores configuration data, state information, and metadata
  - Provides backup and restore capabilities
  - Ensures data consistency across the cluster

### 3. **Controller Manager**
- **Purpose**: Runs controller processes that regulate the state of the cluster
- **Types of Controllers**:
  - Node Controller: Monitors node health
  - Replication Controller: Maintains correct number of pods
  - Endpoints Controller: Manages service endpoints
  - Service Account Controller: Creates default service accounts

### 4. **Scheduler**
- **Purpose**: Assigns pods to nodes based on resource requirements and constraints
- **Functions**:
  - Watches for newly created pods with no assigned node
  - Selects optimal nodes based on resource availability
  - Considers affinity, anti-affinity, and other constraints

---

## Worker Node Components

Worker Nodes run the application workloads and contain these essential components:

### 1. **Kubelet**
- **Purpose**: Primary node agent that communicates with the API server
- **Functions**:
  - Manages pods and their containers
  - Reports node and pod status to the API server
  - Performs health checks on containers

### 2. **Container Runtime**
- **Purpose**: Software responsible for running containers
- **Common Runtimes**:
  - Docker
  - containerd
  - CRI-O
- **Functions**:
  - Pulls container images
  - Starts and stops containers
  - Manages container lifecycle

### 3. **Kube-proxy**
- **Purpose**: Network proxy that maintains network rules on nodes
- **Functions**:
  - Implements Kubernetes Service concept
  - Handles load balancing for services
  - Manages iptables rules for traffic routing

### 4. **Optional Add-ons**
- **DNS**: Provides DNS services for the cluster
- **Dashboard**: Web-based UI for cluster management
- **Monitoring**: Tools like Prometheus for cluster monitoring

---

## Kubernetes Objects
---
### Pods

**What is a Pod?**
- The smallest deployable unit in Kubernetes
- Represents a single instance of a running process
- Can contain one or more containers that share storage and network

**Key Characteristics:**
- Containers in a pod share the same IP address and port space
- Pods are ephemeral and disposable
- Each pod gets a unique IP address

**Example Pod YAML:**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
spec:
  containers:
  - name: my-container
    image: nginx:1.20
    ports:
    - containerPort: 80
```

**Imperative Command:**
```bash
kubectl run my-pod --image=nginx:1.20 --port=80
```
### Namespace

* **Purpose**: Logical separation of resources within a cluster

#### YAML:

```yaml
tapiVersion: v1
kind: Namespace
metadata:
  name: my-namespace
```

#### Command:

```bash
kubectl create namespace my-namespace
```
### ReplicaSet

**What is a ReplicaSet?**
- Ensures a specified number of pod replicas are running at any given time
- Maintains pod availability and scalability
- Replaced the older Replication Controller

**Key Features:**
- Monitors pod health and replaces failed pods
- Supports set-based label selectors
- Can scale up or down based on requirements

**Example ReplicaSet YAML:**
```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: my-replicaset
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: my-container
        image: nginx:1.20
```

**Imperative Command:**
```bash
# Note: ReplicaSet doesn't have direct imperative command
# Create deployment first, then scale down to create ReplicaSet
kubectl create replicaset my-replicaset --image=nginx:1.20 --replicas=3
# Or create from YAML file
kubectl apply -f replicaset.yaml
```

### Deployment

**What is a Deployment?**
- Higher-level abstraction that manages ReplicaSets
- Provides declarative updates for pods and ReplicaSets
- Enables rolling updates and rollbacks

**Key Benefits:**
- Rolling updates with zero downtime
- Easy rollback to previous versions
- Scaling capabilities
- Update strategies (RollingUpdate, Recreate)

**Example Deployment YAML:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-deployment
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: my-container
        image: nginx:1.20
        ports:
        - containerPort: 80
```

**Imperative Command:**
```bash
kubectl create deployment my-deployment --image=nginx:1.20 --replicas=3
```

---

## Services

**Why do we need Services?**
- Pods are ephemeral and can be created/destroyed frequently
- Pod IP addresses change when pods are recreated
- Services provide stable network endpoints
- Enable load balancing across multiple pods
- Facilitate service discovery within the cluster

### Service Types

### 1. **ClusterIP (Default)**
**Purpose**: Exposes service only within the cluster

**Characteristics:**
- Internal cluster communication only
- Gets a cluster-internal IP address
- Default service type

**Use Cases:**
- Internal microservices communication
- Database connections within cluster

**Example:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-clusterip-service
spec:
  type: ClusterIP
  selector:
    app: my-app
  ports:
  - port: 80
    targetPort: 8080
```

**Imperative Command:**
```bash
kubectl expose deployment my-deployment --name=my-clusterip-service --port=80 --target-port=8080 --type=ClusterIP
```

### 2. **NodePort**
**Purpose**: Exposes service on each node's IP at a static port

**Characteristics:**
- Accessible from outside the cluster
- Port range: 30000-32767
- Creates ClusterIP automatically

**Use Cases:**
- Development and testing environments
- Simple external access without load balancer

**Example:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-nodeport-service
spec:
  type: NodePort
  selector:
    app: my-app
  ports:
  - port: 80
    targetPort: 8080
    nodePort: 30080
```

**Imperative Command:**
```bash
kubectl expose deployment my-deployment --name=my-nodeport-service --port=80 --target-port=8080 --type=NodePort --overrides='{"spec":{"ports":[{"port":80,"targetPort":8080,"nodePort":30080}]}}'

```

### 3. **LoadBalancer**
**Purpose**: Exposes service externally using cloud provider's load balancer

**Characteristics:**
- Creates NodePort and ClusterIP automatically
- Requires cloud provider support
- Gets external IP address

**Use Cases:**
- Production environments
- High availability external access
- Cloud-based deployments

**Example:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-loadbalancer-service
spec:
  type: LoadBalancer
  selector:
    app: my-app
  ports:
  - port: 80
    targetPort: 8080
```

**Imperative Command:**
```bash
kubectl expose deployment my-deployment --name=my-loadbalancer-service --port=80 --target-port=8080 --type=LoadBalancer
```

---

## Configuration Management

### ConfigMap

**What is a ConfigMap?**
- Kubernetes object used to store non-confidential configuration data
- Separates configuration from application code
- Can be consumed as environment variables, command-line arguments, or configuration files

**Key Features:**
- Stores configuration in key-value pairs
- Can hold entire configuration files
- Enables configuration changes without rebuilding images

**Example ConfigMap:**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-config
data:
  database_url: "mongodb://localhost:27017"
  debug_mode: "true"
  config.properties: |
    app.name=MyApplication
    app.version=1.0.0
    app.environment=production
```

**Imperative Commands:**
```bash
# Create ConfigMap from literal values
kubectl create configmap my-config --from-literal=database_url="mongodb://localhost:27017" --from-literal=debug_mode="true"
# Create ConfigMap from file
kubectl create configmap my-config --from-file=config.properties
```

### Secret

**What is a Secret?**
- Kubernetes object used to store and manage sensitive information
- Similar to ConfigMap but designed for confidential data
- Data is base64 encoded (not encrypted by default)

**Key Features:**
- Stores sensitive data like passwords, tokens, keys
- Can be mounted as files or environment variables
- Provides better security than storing secrets in images

**Types of Secrets:**
- **Opaque**: Arbitrary user-defined data
- **kubernetes.io/dockerconfigjson**: Docker registry credentials
- **kubernetes.io/tls**: TLS certificates

**Example Secret:**
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: my-secret
type: Opaque
data:
  username: YWRtaW4=  # base64 encoded 'admin'
  password: cGFzc3dvcmQ=  # base64 encoded 'password'
```

**Imperative Commands:**
```bash
# Create Secret from literal values
kubectl create secret generic my-secret --from-literal=username=admin --from-literal=password=password

# Create Secret from file
kubectl create secret generic my-secret --from-file=username.txt --from-file=password.txt

# Create Docker registry secret
kubectl create secret docker-registry my-registry-secret --docker-server=registry.io --docker-username=user --docker-password=pass --docker-email=user@example.com

# Create TLS secret
kubectl create secret tls my-tls-secret --cert=cert.crt --key=cert.key
```

### ConfigMap vs Secret - Key Differences

| Aspect | ConfigMap | Secret |
|---------|-----------|---------|
| **Purpose** | Non-sensitive configuration data | Sensitive information |
| **Data Storage** | Plain text | Base64 encoded |
| **Security** | No special security measures | Limited access, can be encrypted at rest |
| **Use Cases** | App settings, environment configs | Passwords, tokens, certificates |
| **Visibility** | Can be viewed by anyone with cluster access | Restricted access through RBAC |

### **Example: Using ConfigMap and Secret in a Deployment**

**ConfigMap YAML (my-config.yaml):**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-config
data:
  database_url: "mongodb://localhost:27017"
  debug_mode: "true"
  app_port: "8080"
  config.properties: |
    app.name=MyApplication
    app.version=1.0.0
    app.environment=production
    logging.level=INFO
```

**Secret YAML (my-secret.yaml):**
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: my-secret
type: Opaque
data:
  username: YWRtaW4=  # base64 encoded 'admin'
  password: cGFzc3dvcmQ=  # base64 encoded 'password'
  api-key: bXlfc3VwZXJfc2VjcmV0X2FwaV9rZXk=  # base64 encoded 'my_super_secret_api_key'
```

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: my-app
        image: my-app:1.0.0
        ports:
        - containerPort: 8080
        
        # Using ConfigMap as environment variables
        envFrom:
        - configMapRef:
            name: my-config
        
        # Using Secret as environment variables
        env:
        - name: DB_USERNAME
          valueFrom:
            secretKeyRef:
              name: my-secret
              key: username
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: my-secret
              key: password
        
        # Mounting ConfigMap as volume
        volumeMounts:
        - name: config-volume
          mountPath: /etc/config
        - name: secret-volume
          mountPath: /etc/secrets
          readOnly: true
      
      volumes:
      - name: config-volume
        configMap:
          name: my-config
      - name: secret-volume
        secret:
          secretName: my-secret
```

**Best Practices:**
1. Use ConfigMaps for non-sensitive configuration
2. Use Secrets for passwords, tokens, and certificates
3. Mount secrets as volumes when possible (more secure than environment variables)
4. Implement proper RBAC to restrict access to secrets
5. Consider using external secret management tools for enhanced security
6. Regularly rotate secrets and certificates

---

## Summary

This lecture covered the fundamental concepts of Kubernetes:

1. **Architecture**: Master-worker pattern with distributed components
2. **Master Node**: API Server, etcd, Controllers, and Scheduler
3. **Worker Node**: Kubelet, Container Runtime, and Kube-proxy
4. **Core Objects**: Pods, ReplicaSets, and Deployments for application management
5. **Services**: ClusterIP, NodePort, and LoadBalancer for networking
6. **Configuration**: ConfigMaps and Secrets for managing application configuration

Understanding these concepts provides a solid foundation for working with Kubernetes and deploying containerized applications at scale.


