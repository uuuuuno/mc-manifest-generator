#!/bin/bash

read -p "Enter server name (without special characters or spaces): " servername
read -p "Enter a number between 32000 and 32556: " port

if [[ ! $port =~ ^[0-9]+$ ]] || [[ $port -lt 32000 ]] || [[ $port -gt 32556 ]]; then
    echo "Invalid port number. Please enter a number between 32000 and 32556."
    exit 1
fi

NFS_SERVER_IP=$(cat .env | grep NFS_SERVER_IP | cut -d '=' -f 2)
NFS_SERVER_DIR=$(cat .env | grep NFS_SERVER_DIR | cut -d '=' -f 2)
LOCAL_MOUNT_DIR=$(cat .env | grep LOCAL_MOUNT_DIR | cut -d '=' -f 2)
MC_VERSION=$(cat .env | grep MC_VERSION | cut -d '=' -f 2)
MC_TYPE=$(cat .env | grep MC_TYPE | cut -d '=' -f 2)
MC_MEMORY=$(cat .env | grep MC_MEMORY | cut -d '=' -f 2)

cat << EOF > manifests/mc-${servername}-manifest.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: minecraft
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mc-${servername}-deployment
  namespace: minecraft
  labels:
    app: mc-${servername}
spec:
  selector:
    matchLabels:
      app: mc-${servername}
  replicas: 1
  template:
    metadata:
      labels:
        app: mc-${servername}
    spec:
      containers:
      - name: mc-${servername}-container
        image: itzg/minecraft-server
        env:
        - name: EULA
          value: "TRUE"
        - name: VERSION
          value: "${MC_VERSION}"
        - name: TYPE
          value: "${MC_TYPE}"
        - name: MEMORY
          value: "${MC_MEMORY}"
        ports:
        - containerPort: 25565
        volumeMounts:
        - name: mc-${servername}-storage
          mountPath: "/data"
      volumes:
      - name: mc-${servername}-storage
        nfs:
          server: ${NFS_SERVER_IP}
          path: ${NFS_SERVER_DIR}/${servername}/gamefiles
---
apiVersion: v1
kind: Service
metadata:
  name:  mc-${servername}-service-nodeport
  namespace: minecraft
spec:
  selector:
    app:  mc-${servername}
  type:  NodePort
  ports:
  - name:  game-port
    port:  25565
    nodePort: ${port}
    protocol: TCP
EOF

echo "Config file generated: mc-${servername}-manifest.yaml"

sudo mount -t nfs ${NFS_SERVER_IP}:${NFS_SERVER_DIR} ${LOCAL_MOUNT_DIR}

sudo mkdir ${LOCAL_MOUNT_DIR}/${servername}
sudo mkdir ${LOCAL_MOUNT_DIR}/${servername}/config
sudo mkdir ${LOCAL_MOUNT_DIR}/${servername}/gamefiles

cp manifests/mc-${servername}-manifest.yaml ${LOCAL_MOUNT_DIR}/${servername}/config/
cp -r gamefiles/* ${LOCAL_MOUNT_DIR}/${servername}/gamefiles

read -p "Apply the manifest (y/n)? " apply_manifest

if [[ $apply_manifest == "Y" || $apply_manifest == "y" ]]; then
    kubectl apply -f manifests/mc-${servername}-manifest.yaml
    echo "The manifest has been successfully applied."
else
    echo "The manifest does not apply."
fi