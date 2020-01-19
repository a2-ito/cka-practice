# CKA/CKAD Practice

## Exam curriculum - 01/2020
### CKA
```
 8% - Application Lifecycle Management
12% - Installation, Configuration & Validation
19% - Core Concepts
11% - Networking
 5% - Scheduling
12% - Security
11% - Cluster Maintenance
 5% - Logging / Monitoring 
 7% - Storage
10% - Troubleshooting 
```

### CKAD
```
13% - Core Concepts
18% - Configuration
10% - Multi-Container Pods
18% - Observability
20% - Pod Design
13% - Services & Networking
 8% - State Persistence
```

## Task Summary
- [Task. Backup and restore etcd data](#Task-Backup-and-restore-etcd-data)
- [Task. Update cluster](#Task-Update-cluster)
- [Task. Re-create certificates from CA certificate](#Task-Re-create-certificates-from-CA-certificate)
- [Task. Rolling updates and rollbacks](#Task-Rolling-updates-and-rollbacks)
- [Task. Expose pod](#Task-Expose-pod)
- [Task. expose](#Task-expose)
- [Task. Deploy sidecar pod](#Task-Deploy-sidecar-pod)
- [Task. Create a configmap named config with values](#Task-Create-a-configmap-named-config-with-values])
- [Task. Create initContainer](#Task-Create-initContainer)
- [Task. Create a configmap named config with values](#Task-Create-a-configmap-named-config-with-values)
- [Task. Create an nginx pod with requests and limits](#Task-Create-an-nginx-pod-with-requests-and-limits)
- [Task. Create an nginx deployment with NetworkPolicy](#Task-Create-an-nginx-deployment-with-NetworkPolicy)
- [Task. Create a horizontal autoscaling group](#Task-Create-a-horizontal-autoscaling-group)

## Task. Backup and restore etcd data

### Backup

- CA Certificate - ```/etc/etcd/ca.pem```
- Cluster Certificate - ```/etc/etcd/kubernetes.pem```
- Cluster Secret key - ```/etc/etcd/kuberntes-key.pem```

<details>
 
```
$ sudo su - 
# ETCDCTL_API=3 etcdctl snapshot save snapshot.db \
--endpoints=https://127.0.0.1:2379 \
--cacert=/etc/etcd/ca.pem \
--cert=/etc/etcd/kubernetes.pem \
--key=/etc/etcd/kubernetes-key.pem
```

```
# ETCDCTL_API=3 etcdctl snapshot status snapshot.db
```
</details>

### Restore
<details>

```
$ sudo systemctl stop kube-apiserver
$ sudo systemctl stop etcd
```
```
$ sudo su -
# ETCDCTL_API=3 etcdctl \
snapshot restore snapshot.db \
--name=master1 \
--cert=/etc/kubernetes/kubernetes.pem \
--key=/etc/kubernetes/kubernetes-key.pem \
--data-dir /var/lib/etcd-from-backup \
--initial-cluster master1=https://192.168.33.11:2380 \
--initial-cluster-token etcd-cluster \
--initial-advertise-peer-urls https://192.168.33.11:2380
```
</details>

#### Edit ```/etc/systemd/system/etcd.service```
<details>

```
--data-dir /var/lib/etcd
->
--data-dir /var/lib/etcd-from-backup
```
```
sudo systemctl start etcd
sudo systemctl start kube-apiserver
```
</details>

## Task. Update cluster
### drain worker nodes for maintainance
<details>

```
kubectl drain worker1
```
```
-- update tasks --
```
</details>

### uncordon worker
<details>

```
kubectl uncordon wokrer1
```

</details>

## Task. Create ```hostPath``` Persistent Volume
### Create hostfile at ```/tmp/data/hostfile```

<details>

```
mkdir /tmp/data
echo hoge >> /tmp/data/hostfile
cat /tmp/data/hostfile
```
</details>

### Create Pod with hostPath
<details>

```
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: testpod
spec:
  containers:
  - image: busybox
    name: testpod
    args: 
    - sleep 
    - "3600"
    volumeMounts:
    - mountPath: /hostdata
      name: test-volume
  volumes:
  - name: test-volume
    hostPath:
      path: /tmp/data
      type: Directory
EOF
```
</details>

### Verify
<details>

```
kubectl exec -it testpod -- cat /hostdata/hostfile
```
```
kubectl delete pod testpod
```
</details>

## Task. Create StorageClass/PersistentVolume/PersistentVolumeClaim via local
### Create StorageClass ```local-storage```
<details>

```
cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-storage
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
EOF
```

```
kubectl get sc
```
</details>

### Create PersistentVolume ```pv-local-storage```
<details>

```
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-local-storage
spec:
  capacity:
    storage: 1Gi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-storage
  local:
    path: /tmp/data/
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - cka-node1
EOF
```

### Create PVC
```
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-local-storage
spec:
  storageClassName: local-storage
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
EOF
```

### Create Pod
```
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: testpod
spec:
  containers:
  - image: busybox
    name: testpod
    args: 
    - sleep 
    - "3600"
    volumeMounts:
    - mountPath: /hostdata
      name: test-volume
  volumes:
  - name: test-volume
    persistentVolumeClaim:
      claimName: pvc-local-storage
EOF
```

## Task. Re-create certificates from CA certificate

| Type               | CN                             | O                         |
|:------------------:|:------------------------------:|:-------------------------:|
| Kube Proxy         | system:kube-proxy              | system:node-proxier       |
| Kubelet            | system:node:[instance]         | system:nodes              | 
| API Server         | kubernetes                     | Kubernetes                |
| Controller Manager | system:kube-controller-manager | system:controller-manager |
| Scheduler          | system:kube-scheduler          | system:kube-scheduler     |

```
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  admin-csr.json | cfssljson -bare admin
```

## Task. Rolling updates and rollbacks
### Deploy nginx deployment
```
kubectl run nginx --restart=Always --image=nginx:1.12
```

### Update image
```
kubectl set image deployment nginx nignx=nginx:1.13
```

### Rollback
```
kubectl rollout history deployment nginx
kubectl get deployment nginx -o yaml | grep image
```
```
kubectl rollout undo deployment nginx
kubectl get deployment nginx -o yaml | grep image
```

## Task. Expose pod
### Deploye nginx deployment
```
kubectl run nginx --restart=Always --image=nginx
```

### Expose svc via ClusterIP
```
kubectl expose deployment nginx --port=8080 --target-port=80
```

### Expose svc via NodePort
```
kubectl expose deployment nginx --name nginx-nodeport --port=8081 --target-port=80 --type=NodePort 
```

### Expose pod via ExternalIP (ClusterIP)
```
kubectl expose deployment nginx --name nginx-externalip --port=8082 --target-port=80 --type=ClusterIP --external-ip=10.0.2.15
```

## Task. Deploy sidecar pod
- name: ```container1```, image=```busybox```
- name: ```container2```, image=```busybox``` 

```
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: two-containers
spec:
  restartPolicy: Never
  volumes:
  - name: shared-data
    emptyDir: {}

  containers:
  - name: master-container
    image: busybox
    volumeMounts:
    - name: shared-data
      mountPath: /usr/share/nginx/html

  - name: sidecar-container
    image: debian
    volumeMounts:
    - name: shared-data
      mountPath: /pod-data
    command: ["/bin/sh"]
    args: ["-c", "echo Hello from the debian container > /pod-data/index.html"]
EOF
```

## Task. Deploy pod with nodeSelector
```
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  labels:
    env: test
spec:
  containers:
  - name: nginx
    image: nginx
    imagePullPolicy: IfNotPresent
  nodeSelector:
    kubernetes.io/hostname: cka-node1
EOF
```
</details>

## Task. Deploy pod with podAffinity/podAntiAffinity
### podAffinity
<details>

```
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: with-pod-affinity
spec:
  affinity:
    podAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchExpressions:
          - key: security
            operator: In
            values:
            - S1
          topologyKey: kubernetes.io/hostname
  containers:
  - name: with-pod-affinity
    image: k8s.gcr.io/pause:2.0
EOF
```


```
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis-cache
spec:
  selector:
    matchLabels:
      app: store
  replicas: 1
  template:
    metadata:
      labels:
        app: store
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: app
                operator: In
                values:
                - store
            topologyKey: "kubernetes.io/hostname"
      containers:
      - name: redis-server
        image: redis:3.2-alpine
EOF
```
</details>

### podAntiAffinity
<details>

```
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-server
spec:
  selector:
    matchLabels:
      app: web-store
  replicas: 1
  template:
    metadata:
      labels:
        app: web-store
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: app
                operator: In
                values:
                - web-store
            topologyKey: "kubernetes.io/hostname"
      containers:
      - name: web-app
        image: nginx:1.12-alpine
EOF
```
```
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: with-pod-antiaffinity
spec:
  selector:
    matchLabels:
      app: web-store
  replicas: 1
  template:
    metadata:
      labels:
        app: web-store
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: app
                operator: In
                values:
                - web-store
            topologyKey: "kubernetes.io/hostname"
      containers:
      - name: web-app
        image: nginx:1.12-alpine
EOF
```
```
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: with-pod-affinity
spec:
  selector:
    matchLabels:
      app: web-store
  replicas: 1
  template:
    metadata:
      labels:
        app: web-store
    spec:
      affinity:
        podAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: app
                operator: In
                values:
                - web-store
            topologyKey: "kubernetes.io/hostname"
      containers:
      - name: web-app
        image: nginx:1.12-alpine
EOF
```
```
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: with-pod-antiaffinity
spec:
  affinity:
    podAntiAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 1
        podAffinityTerm:
          labelSelector:
            matchExpressions:
            - key: app
              operator: In
              values:
              - web-store
          topologyKey: kubernetes.io/hostname
  containers:
  - name: with-pod-antiaffinity
    image: k8s.gcr.io/pause:2.0
EOF
```
</details>

## Task. Create a new ```ResourceQuota``` which limits 1 CPU and 512 MB RAM

## Task. Name Resolution for Pod and Service
### Create sample Pod and Service
<details>

```
```
</details>

## Task. Create nginx pod with environment value ```VAL=val1```
<details>

```
echo 
```
</details>

## Task. Create Cronjob
<details>

```
echo 
```
</details>

## Task. Create pod with ```livenessProbe``` and ```readinessProbe```
### livenessProbe
<details>

```
cat <<EOF | kubectl apply -f - 
apiVersion: v1
kind: Pod
metadata:
  labels:
    test: liveness
  name: liveness-exec
spec:
  containers:
  - name: liveness
    image: k8s.gcr.io/busybox
    args:
    - /bin/sh
    - -c
    - touch /tmp/healthy; sleep 30; rm -rf /tmp/healthy; sleep 600
    livenessProbe:
      exec:
        command:
        - cat
        - /tmp/healthy
      initialDelaySeconds: 5
      periodSeconds: 5
EOF
```
</details>

### readinessProbe
<details>

```
```
</details>

## Task. Create a configmap named config with values
- ```foo=foofoo```
- ```bar=barbar```
<details>

```
```
</details>

## Task. Create an nginx pod with requests and limits
- requests cpu=100m,memory=256Mi
- limits cpu=200m,memory=512Mi

<details>

```
cat <<EOF | kubectl create -f -
apiVersion: v1
kind: Pod
metadata:
  name: busybox1
spec:
  containers:
  - name: busybox-cnt01
    image: busybox
    command: ["/bin/sh"]
    args: ["-c", "while true; do echo hello from cnt01; sleep 10;done"]
    resources:
      requests:
        cpu: "0.5"
      limits:
        cpu: "2"
        memory: "100Mi"
EOF
```
</details>

## Create an nginx deployment with NetworkPolicy
- 2 replicas
- expose it via a ClusterIP service on port 80. Create a NetworkPolicy so that only pods with labels 'access: true' can access the deployment and apply it
<details>

```
```
</details>

## Task. Create initContainer
- main container: ```name=nginx-container```, ```image=nginx```
- init container: ```name=init-container```, ```image=busybox```
<details>

```
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: init-container
  labels:
    app: myapp
spec:
  restartPolicy: Never
  volumes:
  - name: shared-data
    emptyDir: {}

  containers:
  - name: nginx-container
    image: nginx
    volumeMounts:
    - name: shared-data
      mountPath: /usr/share/nginx/html

  initContainers:
  - name: init-container
    image: busybox
    volumeMounts:
    - name: shared-data
      mountPath: /pod-data
    command: ['wget', 'https://kubernetes.io']
EOF
```
</details>

## Task. Create a horizontal autoscaling group
Create a horizontal autoscaling group that should start with 2 pods and scale when CPU usage is over 50%.
<details>

```
```
</details>

