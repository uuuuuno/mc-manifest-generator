#!/bin/bash
read -p "Enter server name (without special characters or spaces): " servername

NFS_SERVER_IP=$(cat .env | grep NFS_SERVER_IP | cut -d '=' -f 2)
LOCAL_MOUNT_DIR=$(cat .env | grep LOCAL_MOUNT_DIR | cut -d '=' -f 2)

sudo mount -t nfs ${NFS_SERVER_IP}:/home/mc ${LOCAL_MOUNT_DIR}
rm -rf ${LOCAL_MOUNT_DIR}/${servername}
rm manifests/mc-${servername}-manifest.yaml

echo "Done."

read -p "Delete the manifest (y/n)? " delete_manifest

if [[ $delete_manifest == "Y" || $delete_manifest == "y" ]]; then
    kubectl delete -f mc-${servername}-manifest.yaml
    echo "Manifest deleted successfully."
else
    echo "Manifest not deleted."
fi