#!/bin/bash
#===============================================================================
# Script Name : k8s-health-check.sh
# Description : Kubernetes Control Plane Health Check & Auto Diagnostics
# Author      : Newton Nandru
# Role        : Senior Linux & Production Support Engineer | AWS Cloud & DevOps Engineer
# Version     : 1.0
# Created     : 05-Jul-2026
#
# Supported:
#   - Ubuntu
#   - Kubernetes (kubeadm)
#   - containerd
#
# Checks:
#   ✔ Host Information
#   ✔ kubelet Service
#   ✔ Kubernetes Configuration
#   ✔ API Server
#   ✔ Control Plane Containers
#   ✔ Nodes
#   ✔ Pods
#   ✔ Calico
#   ✔ CoreDNS
#   ✔ Cluster Info
#===============================================================================

GREEN="\033[1;32m"
RED="\033[1;31m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
NC="\033[0m"

pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

fail() {
    echo -e "${RED}[FAIL]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

echo
echo "=========================================================="
echo "      Kubernetes Cluster Health Check"
echo "=========================================================="
echo

##############################################
info "Hostname"

hostname

echo

##############################################
info "Checking kubelet Service"

if systemctl is-active --quiet kubelet
then
    pass "kubelet is running"
else
    fail "kubelet is NOT running"
fi

echo

##############################################
info "Checking Kubernetes Configuration"

if [ -f /etc/kubernetes/admin.conf ]
then
    pass "admin.conf found"
    export KUBECONFIG=/etc/kubernetes/admin.conf
else
    fail "/etc/kubernetes/admin.conf NOT found"
    exit 1
fi

echo

##############################################
info "Checking API Server"

if curl -k https://127.0.0.1:6443/version >/dev/null 2>&1
then
    pass "API Server is reachable"
else
    fail "API Server is NOT reachable"
fi

echo

##############################################
info "Checking Control Plane Containers"

crictl ps | grep kube-apiserver >/dev/null \
&& pass "kube-apiserver Running" \
|| fail "kube-apiserver NOT Running"

crictl ps | grep etcd >/dev/null \
&& pass "etcd Running" \
|| fail "etcd NOT Running"

crictl ps | grep kube-controller-manager >/dev/null \
&& pass "Controller Manager Running" \
|| fail "Controller Manager NOT Running"

crictl ps | grep kube-scheduler >/dev/null \
&& pass "Scheduler Running" \
|| fail "Scheduler NOT Running"

echo

##############################################
info "Cluster Information"

kubectl cluster-info

echo

##############################################
info "Nodes"

kubectl get nodes -o wide

echo

##############################################
info "System Pods"

kubectl get pods -n kube-system -o wide

echo

##############################################
info "Checking Calico"

CALICO=$(kubectl get pods -n kube-system | grep calico-node | awk '{print $3}')

if [ "$CALICO" == "Running" ]
then
    pass "Calico is Running"
else
    warn "Calico is NOT Running"
fi

echo

##############################################
info "Checking CoreDNS"

COREDNS=$(kubectl get pods -n kube-system | grep coredns | grep Running | wc -l)

if [ "$COREDNS" -ge 2 ]
then
    pass "CoreDNS is Running"
else
    warn "CoreDNS is NOT Running"
fi

echo

##############################################
info "Checking Cluster Events"

kubectl get events -A --sort-by=.metadata.creationTimestamp | tail -20

echo

##############################################
info "Checking Node Status"

STATUS=$(kubectl get nodes --no-headers | awk '{print $2}')

if [ "$STATUS" == "Ready" ]
then
    pass "Node Status : Ready"
else
    warn "Node Status : $STATUS"
fi

echo

##############################################
info "Recent kubelet Logs"

journalctl -u kubelet -n 20 --no-pager

echo
echo "=========================================================="
echo " Kubernetes Health Check Completed"
echo "=========================================================="
echo
