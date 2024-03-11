#!/bin/bash

echo ""
echo "┌┬┐┌─┐  ┌┬┐┌─┐┌┐┌┬┌─┐┌─┐┌─┐┌┬┐  ┌─┐┌─┐┌┐┌┌─┐┬─┐┌─┐┌┬┐┌─┐┬─┐"
echo "││││    │││├─┤││││├┤ ├┤ └─┐ │   │ ┬├┤ │││├┤ ├┬┘├─┤ │ │ │├┬┘"
echo "┴ ┴└─┘  ┴ ┴┴ ┴┘└┘┴└  └─┘└─┘ ┴   └─┘└─┘┘└┘└─┘┴└─┴ ┴ ┴ └─┘┴└─"
echo ""

read -p "Enter server name (without special characters or spaces): " servername

NFS_SERVER_IP=$(cat .env | grep NFS_SERVER_IP | cut -d '=' -f 2)
LOCAL_MOUNT_DIR=$(cat .env | grep LOCAL_MOUNT_DIR | cut -d '=' -f 2)

kubectl delete -f manifests/mc-${servername}-manifest.yaml

sudo mount -t nfs ${NFS_SERVER_IP}:/home/mc ${LOCAL_MOUNT_DIR}
rm -fr ${LOCAL_MOUNT_DIR}/${servername}
rm manifests/mc-${servername}-manifest.yaml

echo "Done."