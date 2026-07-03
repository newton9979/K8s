# ☸️ Kubernetes (K8s) - Introduction & Core Features

> A beginner-friendly guide to understanding Kubernetes, its architecture, components, and key features.

---

# 📖 Table of Contents

- [What is Kubernetes?](#-what-is-kubernetes)
- [Why Kubernetes?](#-why-kubernetes)
- [History of Kubernetes](#-history-of-kubernetes)
- [Key Features](#-key-features)
- [Kubernetes Architecture](#-kubernetes-architecture)
- [Control Plane Components](#-control-plane-components)
- [Worker Node Components](#-worker-node-components)
- [How Kubernetes Works](#-how-kubernetes-works)
- [Kubernetes Communication Ports](#-kubernetes-communication-ports)
- [Advantages of Kubernetes](#-advantages-of-kubernetes)
- [Summary](#-summary)

---

# ☸️ What is Kubernetes?

**Kubernetes (K8s)** is an open-source **Container Orchestration Platform** used to automate the deployment, scaling, networking, and management of containerized applications.

Instead of manually managing hundreds or thousands of containers, Kubernetes automates the entire lifecycle of containers across multiple servers.

>Kubernetes = Container Orchestration Platform

---

## What is Container Orchestration?

Container orchestration is the automated management of containers, including:

- Deploying containers
- Scheduling containers on servers
- Scaling applications
- Load balancing traffic
- Monitoring container health
- Replacing failed containers
- Rolling updates
- Rollbacks

Without Kubernetes, these tasks would need to be managed manually.

---

# 🚀 Why Kubernetes?

Modern applications often consist of many containers running across multiple servers.

Managing these manually becomes difficult because of:

- High Availability
- Scaling
- Networking
- Service Discovery
- Health Monitoring
- Automatic Recovery

Kubernetes solves these problems automatically.

---

# 📜 History of Kubernetes

| Item | Details |
|------|----------|
| Developed By | Google |
| Programming Language | Go (Golang) |
| Open Source | Yes |
| Donated To | Cloud Native Computing Foundation (CNCF) |
| Donation Year | 2014 |
| First Stable Release | July 21, 2015 (v1.0) |
| Current Version | v1.31.x |

---

# ⭐ Key Features

## 1. Automated Scheduling

The Kubernetes Scheduler automatically decides where Pods should run based on:

- CPU
- Memory
- Resource availability
- Node affinity
- Taints & tolerations
- Policies

---

## 2. Self-Healing

Kubernetes continuously monitors application health.

If a Pod crashes:

- Pod is recreated automatically
- Failed containers are restarted
- Unhealthy Pods are replaced
- Failed Nodes are detected

Example:

```
Pod Crash
     │
     ▼
Kubernetes Detects Failure
     │
     ▼
Creates New Pod Automatically
```

---

## 3. Automatic Scaling

Applications can automatically scale based on demand.

Supports:

- Horizontal Pod Autoscaler (HPA)
- Vertical Pod Autoscaler (VPA)
- Cluster Autoscaler

Example:

```
100 Users
     │
     ▼
2 Pods

1000 Users
     │
     ▼
10 Pods
```

---

## 4. Load Balancing

Traffic is automatically distributed among multiple Pods.

```
Users
   │
   ▼
Service
   │
──────────────
│     │      │
Pod1 Pod2 Pod3
```

Benefits:

- High Availability
- Better Performance
- Fault Tolerance

---

## 5. Service Discovery

Every application receives:

- Cluster IP
- DNS Name
- Stable Endpoint

Example:

```
frontend.default.svc.cluster.local
```

Applications communicate using service names instead of IP addresses.

---

## 6. Automated Rollouts & Rollbacks

Deploy new versions without downtime.

If deployment fails:

```
Version 1
     │
Deploy v2
     │
Failure
     │
Rollback
     │
Version 1
```

---

## 7. Storage Orchestration

Supports many storage providers:

- AWS EBS
- Azure Disk
- GCP Persistent Disk
- NFS
- iSCSI
- Ceph
- Local Storage

Managed through:

- Persistent Volumes (PV)
- Persistent Volume Claims (PVC)
- Storage Classes

---

## 8. Secret & Configuration Management

Store:

- Passwords
- API Keys
- Tokens
- Configuration Files

Using:

- ConfigMaps
- Secrets

---

# 🏗 Kubernetes Architecture

<p align="center">
<img src="assets/kubernetes-architecture.png" width="900">
</p>

---

# Control Plane Components

The Control Plane manages the entire Kubernetes cluster.

---

## 1. kube-apiserver

The API Server is the front-end of Kubernetes.

Responsibilities:

- Receives REST API requests
- Authentication
- Authorization
- Cluster communication
- Updates etcd

Default Port:

```
6443
```

---

## 2. etcd

A distributed Key-Value Database.

Stores:

- Cluster State
- Pods
- Deployments
- Secrets
- ConfigMaps
- Nodes

Default Ports:

```
2379
2380
```

---

## 3. kube-scheduler

Responsible for scheduling Pods onto Worker Nodes.

Checks:

- CPU
- Memory
- Affinity
- Taints
- Resource Requests

Default Port:

```
10259
```

---

## 4. kube-controller-manager

Runs background controllers.

Examples:

- Node Controller
- Deployment Controller
- ReplicaSet Controller
- Endpoint Controller

Default Port:

```
10257
```

---

## 5. cloud-controller-manager

Integrates Kubernetes with Cloud Providers.

Examples:

- AWS
- Azure
- Google Cloud

Handles:

- Load Balancers
- Volumes
- Routes
- Nodes

---

# 👷 Worker Node Components

Worker Nodes run application workloads.

---

## kubelet

Agent running on every Worker Node.

Responsibilities:

- Creates Pods
- Monitors Pods
- Reports Node Status
- Talks to API Server

Default Port:

```
10250
```

---

## kube-proxy

Responsible for networking.

Functions:

- Service Networking
- Load Balancing
- Network Rules

---

## Container Runtime

Runs Containers.

Examples:

- containerd
- CRI-O

Earlier versions also supported Docker through Dockershim.

---

## Pods

The smallest deployable object in Kubernetes.

A Pod may contain:

- One Container
- Multiple Containers

Example:

```
Pod
 ├── Nginx Container
 └── Sidecar Container
```

---

# 🔄 How Kubernetes Works

```
Developer
      │
kubectl apply
      │
      ▼
API Server
      │
      ▼
Scheduler
      │
      ▼
Worker Node
      │
      ▼
Pod Created
      │
      ▼
Application Running
```

---

# 🔌 Kubernetes Communication Ports

| Component | Port | Purpose |
|-----------|------|----------|
| API Server | 6443 | Kubernetes API |
| etcd Client | 2379 | Cluster Database |
| etcd Peer | 2380 | etcd Replication |
| kubelet | 10250 | Node Agent |
| Scheduler | 10259 | Pod Scheduling |
| Controller Manager | 10257 | Cluster Controllers |
| CoreDNS | 53 | DNS |
| NodePort | 30000-32767 | External Access |
| HTTP | 80 | Web Traffic |
| HTTPS | 443 | Secure Traffic |

---

# ✅ Advantages of Kubernetes

- Fully Open Source
- Highly Scalable
- Self-Healing
- Automatic Rollbacks
- High Availability
- Load Balancing
- Auto Scaling
- Cloud Native
- Vendor Neutral
- Infrastructure Independent
- Supports Multi-Cloud Deployments
- Declarative Configuration
- Large Community Support

---

# 📚 Summary

Kubernetes is the industry-standard platform for container orchestration.

It automates:

- Container Deployment
- Scheduling
- Scaling
- Networking
- Load Balancing
- Self-Healing
- Storage Management
- Rollbacks
- High Availability

Kubernetes is widely used across cloud platforms such as **AWS**, **Azure**, **Google Cloud Platform (GCP)**, and on-premises data centers, making it an essential skill for every DevOps and Cloud Engineer.

---

## 📖 Next Topic

➡️ Kubernetes Cluster Architecture in Detail
