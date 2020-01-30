
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
- [Task. Re-create certificates from CA certificate](#Task-Re-create-certificates-from-CA-certificate)
- [Task. Update cluster](#Task-Update-cluster)
- [Task. Rolling updates and rollbacks](#Task-Rolling-updates-and-rollbacks)
<<<<<<< HEAD
- [Task. Create hostPath Persistent Volume](#Task.-Create-hostPath-Persistent-Volume)
- [Task. Create StorageClass,PersistentVolume,PersistentVolumeClaim via local](Task.-Create-StorageClass,PersistentVolume,PersistentVolumeClaim-via-local)
- [Task. Expose Pod via Service](#Task-Expose-Pod-via-Service)
- [Task. Deploy sidecar pod](#Task-Deploy-sidecar-pod)
- [Task. Create a new ResourceQuota](#Task-Create-a-new-ResourceQuota)
- [Task. Name Resolution for Pod and Service](#Task-Name-Resolution-for-Pod-and-Service)
- [Task. Create nginx pod with environment value](#Task-Create-nginx-pod-with-environment-value)
- [Task. Create Cronjob](#Task-Create-Cronjob)
- [Task. Create pod with livenessProbe and readinessProbe](#Task-Create-pod-with-livenessProbe-and-readinessProbe)
=======
- [Task. Expose pod without yaml](#Task-Expose-pod-without-yaml)
- [Task. Create hostPath Persistent Volume](Task.-Create-hostPath-Persistent-Volume)
- [Task. Deploy sidecar pod](#Task-Deploy-sidecar-pod)
- [Task. Name Resolution for Pod and Service](#Task-Name-Resolution-for-Pod-and-Service)
- [Task. Create a configmap named config with values](#Task-Create-a-configmap-named-config-with-values])
- [Task. Create initContainer](#Task-Create-initContainer)
- [Task. Create Cronjob](#Task-Create-Cronjob)
>>>>>>> db7dfbdad9f77f4ed1420ae6031a6901ac2167ea
- [Task. Create a configmap named config with values](#Task-Create-a-configmap-named-config-with-values)
- [Task. Create an nginx pod with requests and limits](#Task-Create-an-nginx-pod-with-requests-and-limits)
- [Task. Create an nginx deployment with NetworkPolicy](#Task-Create-an-nginx-deployment-with-NetworkPolicy)
- [Task. Create initContainer](#Task-Create-initContainer)
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

&nbsp;
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

<<<<<<< HEAD
&nbsp;
## Task. Re-create certificates from CA certificate
=======
## Task. Expose pod without yaml
- pod - ```name```: ```nginx-pod```, image: ```nginx```
- service - ```name```: ```nginx-svc```, ```type```: ```ClusterIP```
>>>>>>> db7dfbdad9f77f4ed1420ae6031a6901ac2167ea

<details>

```
<<<<<<< HEAD
```
</details>

&nbsp;
## Task. Rolling updates and rollbacks

### Deploy nginx deployment
<details>

```
kubectl run nginx --restart=Always --image=nginx:1.12
```
</details>

### Update image
<details>
```
kubectl set image deployment nginx nignx=nginx:1.13
```
</details>

### Rollback
<details>

```
kubectl rollout history deployment nginx
kubectl get deployment nginx -o yaml | grep image
```

```
kubectl rollout undo deployment nginx
kubectl get deployment nginx -o yaml | grep image
```
</details>

&nbsp;
## Task. Create hostPath Persistent Volume

=======
kubectl run nginx-pod --restart=Never --image=nginx
```

```
kubectl expose pod nginx-pod --name nginx-svc --target-port=80 --port=80 --type=ClusterIP
```

```
curl http://[ClusterIP]:80
```

</details>

## Task. Create ```hostPath``` Persistent Volume
>>>>>>> db7dfbdad9f77f4ed1420ae6031a6901ac2167ea
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

&nbsp;
## Task. Create StorageClass,PersistentVolume,PersistentVolumeClaim via local
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
</details>


### Create PVC ```pvc-local-storage```
<details>

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
</details>

### Create Pod
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
    persistentVolumeClaim:
      claimName: pvc-local-storage
EOF
```
</details>

&nbsp;

## Task. Re-create certificates from CA certificate

| Type               | CN                             | O                         |
|:-------------------|:-------------------------------|:--------------------------|
| Kube Proxy         | system:kube-proxy              | system:node-proxier       |
| Kubelet            | system:node:[instance]         | system:nodes              | 
| API Server         | kubernetes                     | Kubernetes                |
| Controller Manager | system:kube-controller-manager | system:controller-manager |
| Scheduler          | system:kube-scheduler          | system:kube-scheduler     |

<details>

```
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  admin-csr.json | cfssljson -bare admin
```
</details>

&nbsp;
## Task. Expose Pod via Service
### Deploye nginx deployment
<details>

```
kubectl run nginx --restart=Always --image=nginx
```
</details>

### Expose svc via ClusterIP
<details>

```
kubectl expose deployment nginx --port=8080 --target-port=80
```
</details>

### Expose svc via NodePort
<details>

```
kubectl expose deployment nginx --name nginx-nodeport --port=8081 --target-port=80 --type=NodePort 
```
</details>

### Expose pod via ExternalIP (ClusterIP)
<details>

```
kubectl expose deployment nginx --name nginx-externalip --port=8082 --target-port=80 --type=ClusterIP --external-ip=10.0.2.15
```
</details>

&nbsp;
## Task. Deploy sidecar pod
- main-container - name: ```container1```, image=```busybox```
- sidecar - name: ```container2```, image=```busybox``` 

<details>

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
</details>

&nbsp;
## Task. Deploy pod with nodeSelector
<details>

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

&nbsp;
## Task. Deploy pod with podAffinity/podAntiAffinity
- ```podAffinity```: pod-b always runs always with pod-a
- ```podAntiAffinity```: pod-a alwways doesn't run with pod-b

### ```podAffinity```: pod-b always runs always with pod-a
<details>

```
kubectl run pod-a --image=busybox --labels="app=pod-a" --restart=Never -- sleep 3600
```
```
cat <<EOF | kubectl apply -f - 
apiVersion: v1
kind: Pod
metadata:
  name: pod-b
spec:
  affinity:
    podAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchExpressions:
          - key: app
            operator: In
            values:
              - pod-a
        topologyKey: kubernetes.io/hostname
  containers:
    - name: pod-b
      image: busybox
EOF
```
</details>

### ```podAntiAffinity```: pod-a alwways doesn't run with pod-b
<details>

```
kubectl run pod-a --image=busybox --labels="app=pod-a" --restart=Never -- sleep 3600
```

```
cat <<EOF | kubectl apply -f - 
apiVersion: v1
kind: Pod
metadata:
  name: pod-b
spec:
  affinity:
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchExpressions:
          - key: app
            operator: In
            values:
              - pod-a
        topologyKey: kubernetes.io/hostname
  containers:
    - name: pod-b
      image: busybox
EOF
```
</details>

&nbsp;
## Task. Create a new ResourceQuota
- ```name```: ```test-resourcequota```
- limits 1 CPU and 512 MB RAM

<details>

```
cat <<EOF | kubectl apply -f - 
apiVersion: v1
kind: ResourceQuota
metadata:
  name: test-resourcequota
spec:
  hard:
    cpu: "1"
    memory: 512Mi
    pods: "10"
  scopeSelector:
    matchExpressions:
    - operator : In
      scopeName: PriorityClass
      values: ["low"]
EOF
```
</details>

### Create pod with resourcequota

<details>

```
cat <<EOF | kubectl apply -f - 
apiVersion: v1
kind: Pod
metadata:
  name: low-pod
spec:
  containers:
  - name: low-priority
    image: busybox
    command: ["/bin/sh"]
    args: ["-c", "while true; do echo hello; sleep 10;done"]
  priorityClassName: low
EOF
```
</details>

&nbsp;
## Task. Name Resolution for Pod and Service
### Create sample Pod and Service
<details>


```
kubectl run nginx --image=nginx --restart=Never --labels="name=nginx"
kubectl expose deployment nginx --port=8080 --target-port=80 --type="ClusterIP"
```
</details>

### Resolve IP from Name 
<details>

```
kubectl exec -it dnsutils -- nslookup nginx.default.svc.cluster.local
kubectl exec -it dnsutils -- nslookup 10-42-0-128.nginx.default.svc.cluster.local
```
</details>

### Create pod with specific domain
- ```busybox-1.default-subdomain.default.svc.cluster.local```

<details>

```
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: busybox1
  labels:
    name: busybox
spec:
  hostname: busybox-1
  subdomain: default-subdomain
  containers:
  - image: busybox:1.28
    command:
      - sleep
      - "3600"
    name: busybox
EOF
```
<<<<<<< HEAD
```
kubectl exec -it dnsutils -- nslookup busybox-1.default-subdomain.default.svc.cluster.local.
=======
</details>

## Task. Create a new ```ResourceQuota```
- ```name```: ```rq-test```
- This limits 1 CPU and 512 MB RAM

<details>

```
kubectl create namespace rq-test-namespace
```
```
cat <<EOF | kubectl apply -f - 
apiVersion: v1
kind: ResourceQuota
metadata:
  name: pods-high
  namespace: rq-test-namespace
spec:
  hard:
    cpu: "1000"
    memory: 512Mi
    pods: "10"
  scopeSelector:
    matchExpressions:
    - operator : In
      scopeName: PriorityClass
      values: ["high"]
EOF
```

</details>

## Task. Name Resolution for Pod and Service
### Create sample Pod and Service

<details>

```
kubectl run nginx-dns --image=nginx --restart=Never
kubectl expose pod nginx-dns --name nginx-dns --type=ClusterIP --target-port=80 --port=80
```

</details>

### Create dnsutil pod
<details>

```
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: dnsutils
  namespace: default
spec:
  containers:
  - name: dnsutils
    image: gcr.io/kubernetes-e2e-test-images/dnsutils:1.3
    command:
      - sleep
      - "3600"
    imagePullPolicy: IfNotPresent
  restartPolicy: Always
EOF
>>>>>>> db7dfbdad9f77f4ed1420ae6031a6901ac2167ea
```

</details>

<<<<<<< HEAD
&nbsp;
## Task. Create nginx pod with environment value
- ```VAL```=```val1```
=======
### nslookup

<details>

```
kubectl exec -it dnsutils -- nslookup kubernetes 

kubectl exec -it dnsutils -- nslookup [IP]

kubectl exec -it dnsutils -- nslookup 10-42-0-32.nginx-dns.default.svc.cluster.local.
kubectl exec -it dnsutils -- nslookup nginx-dns
```

</details>

## Task. Create nginx pod with environment value
- ```name```: ```nginx-with-env1```
- envirionment value: ```VAL=val1```
>>>>>>> db7dfbdad9f77f4ed1420ae6031a6901ac2167ea

<details>

```
<<<<<<< HEAD
kubectl run nginx --image=nginx --restart=Never --env="VAL1=val1"
=======
kubectl run nginx-with-env --restart=Never --env=VAL=val1 --image=nginx
>>>>>>> db7dfbdad9f77f4ed1420ae6031a6901ac2167ea
```
</details>

&nbsp;
## Task. Create Cronjob
- ```name```: ```testconjob```
- ```image```: ```busybox```
- cmd: ```echo "Hello World!"```
- Run every ```3``` mins

<details>

```
<<<<<<< HEAD
kubectl run testcronjob --image=busybox --restart=OnFailure --schedule="*/1 * * * *" -- echo "Hello World!"
=======
kubectl run testcronjob --image=busybox --restart=OnFailure --schedule="*/3 * * * *" -- sh -c 'echo Hellow World!'
```
```
kubectl exec -it nginx-with-env -- env
>>>>>>> db7dfbdad9f77f4ed1420ae6031a6901ac2167ea
```

</details>

&nbsp;
## Task. Create pod with livenessProbe and readinessProbe
### Create pod with livenessProbe
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

### Create pod with readinessProbe
<details>

```
<<<<<<< HEAD
cat <<EOF | kubectl apply -f - 
apiVersion: v1
kind: Pod
metadata:
  labels:
    test: readiness
  name: readiness-exec
spec:
  containers:
  - name: readiness
    image: k8s.gcr.io/busybox
    args:
    - /bin/sh
    - -c
    - touch /tmp/healthy; sleep 30; rm -rf /tmp/healthy; sleep 600
    readinessProbe:
      exec:
        command:
        - cat
        - /tmp/healthy
      initialDelaySeconds: 5
      periodSeconds: 5
EOF
=======

>>>>>>> db7dfbdad9f77f4ed1420ae6031a6901ac2167ea
```
</details>

&nbsp;
## Task. Create a configmap named config with values
<<<<<<< HEAD
- ```foo=foofoo```
- ```bar=barbar```

### via command line
<details>

```
kubectl create configmap configmap1--from-literal="foo=foofoo" --from-literal="bar=barbar"
=======
- ```name```: ```testconfig``` 
- value 1 - ```foo=foofoo```
- value 2 - ```bar=barbar```

<details>

```
cat <<EOF | kubectl create -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: testconfig
data:
  foo: foofoo
  bar: barbar
EOF
>>>>>>> db7dfbdad9f77f4ed1420ae6031a6901ac2167ea
```

</details>

### via file
<details>

```
echo "foo=foofoo\nbar=barbar" > config.txt
kubectl create configmap configmap2 --from-file="config.txt"
```
</details>

### via file
<details>

```
kubectl create configmap configmap3 --from-file="special=config.txt"
```
</details>

### via yaml
<details>

```
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: testconfimap
  namespace: default
data:
  foo: fofoo
  bar: barbar
EOF
```
</details>


&nbsp;
## Task. Create an nginx pod with requests and limits
<<<<<<< HEAD
- ```requests```: cpu=100m,memory=256Mi
- ```limits```: cpu=200m,memory=512Mi
=======
- ```name```: ```testpod``` 
- requests cpu=100m,memory=256Mi
- limits cpu=200m,memory=512Mi
>>>>>>> db7dfbdad9f77f4ed1420ae6031a6901ac2167ea

<details>

```
cat <<EOF | kubectl create -f -
apiVersion: v1
kind: Pod
metadata:
  name: testpod
spec:
  containers:
  - name: testpod
    image: busybox
    command: ["/bin/sh"]
    args: ["-c", "while true; do echo hello from cnt01; sleep 10;done"]
    resources:
      requests:
        cpu: "100m"
        memory: "256Mi"
      limits:
        cpu: "200m"
        memory: "512Mi"
EOF
```

</details>

<<<<<<< HEAD
&nbsp;
## Task. Create an nginx deployment with NetworkPolicy
- 2 replicas
- expose it via a ClusterIP service on port 80.
- Create a NetworkPolicy so that only pods with labels ```access: true``` can access the deployment and apply it
=======
## Task. Create an nginx deployment with NetworkPolicy
- ```name```: ```testpod``` 
- 2 replicas
- Expose it via a ClusterIP service on port 80.
- Create a NetworkPolicy so that only pods with labels ```access: true``` can access the deployment
>>>>>>> db7dfbdad9f77f4ed1420ae6031a6901ac2167ea

<details>

```
cat <<EOF | kubectl apply -f - 
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: test-network-policy
  namespace: default
spec:
  podSelector:
    matchLabels:
      role: limitedpod
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          access: "true"
    ports:
    - protocol: TCP
      port: 80
EOF
```

```
kubectl run nginx --restart=Never --labels="role=limited" --image=nginx
```
```
<<<<<<< HEAD
curl http://[IP]
kubectl run busybox --restart=Never --image=busybox --labels="access=true" -- curl http://[IP]/
kubectl run busybox --restart=Never --image=busybox --labels="access=false" --rm -- curl http://[IP]/
kubectl run --image=giantswarm/tiny-tools --restart=Never --rm -i tepod -- curl 10.42.0.3
```
=======
>>>>>>> db7dfbdad9f77f4ed1420ae6031a6901ac2167ea

</details>

&nbsp;
## Task. Create initContainer
- ```name```: ```init-container```
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

&nbsp;
## Task. Create a horizontal autoscaling group
Create a horizontal autoscaling group that should start with 2 pods and scale when CPU usage is over 50%.
<<<<<<< HEAD

### Create deployment ```nginx```
<details>

```
kubectl run nginx --image=nginx --replicas=1
=======
- ```name```: ```test-autosclae```

<details>

```

>>>>>>> db7dfbdad9f77f4ed1420ae6031a6901ac2167ea
```

</details>

### Create autoscale
<details>

```
kubectl autoscale deployment nginx --cpu-percent=50 --min=2 --max=10
```
</details>

## Task. Create secret
### Create a secret called mysecret with the values password=mypass
<details>

```
kubectl create secret generic mysecret --from-literal=password=mypass
```
</details>

### Create a secret called mysecret2 that gets key/value from a file

<details>

```
kubectl create secret generic mysecret-from-file --from-file=pass.txt
```
</details>

## Task. Create the YAML for an nginx pod that runs with the user ID 101. No need to create the pod

<details>

```
cat <<EOF | kubectl apply -f - 
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: nginx
  name: nginx
spec:
  securityContext: # insert this line
    runAsUser: 101 # UID for the user
  containers:
  - image: nginx
    imagePullPolicy: IfNotPresent
    name: nginx
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Never
EOF
```
```
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: nginx
  name: nginx
spec:
  containers:
  - image: nginx
    imagePullPolicy: IfNotPresent
    name: nginx
    securityContext: # insert this line
      capabilities: # and this
        add: ["NET_ADMIN", "SYS_TIME"] # this as well
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Never
status: {}
EOF
```
</details>


