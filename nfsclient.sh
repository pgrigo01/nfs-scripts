#!/bin/bash
# nfs-client.sh: Mounts an NFS share from a CloudLab NFS server with dynamic DNS lookup

set -e

# Define a default hostname for the NFS server (update as needed)
DEFAULT_SERVER_HOSTNAME="nfs-server.example.com"

# If the first argument is not provided, resolve the default hostname.
if [ -z "$1" ]; then
    echo "No server IP provided; attempting to resolve hostname ${DEFAULT_SERVER_HOSTNAME}..."
    SERVER_IP=$(getent hosts "${DEFAULT_SERVER_HOSTNAME}" | awk '{print $1}')
    if [ -z "$SERVER_IP" ]; then
        echo "Error: Could not resolve hostname ${DEFAULT_SERVER_HOSTNAME}"
        exit 1
    fi
else
    SERVER_IP="$1"
fi

# Use the second argument for the mount point, default to /mnt/nfsshare.
MOUNT_POINT=${2:-"/mnt/nfsshare"}

# Use a third argument for the NFS export path; default to a generic path.
NFS_PATH=${3:-"/nfsshare"}

echo "Setting up NFS client to connect to server $SERVER_IP..."
echo "Mounting NFS share: $SERVER_IP:$NFS_PATH at $MOUNT_POINT"

# Install NFS client if necessary.
if ! dpkg -l | grep -q nfs-common; then
    echo "Installing NFS client software..."
    sudo apt-get update && sudo apt-get install -y nfs-common
fi

# Create the mount point if it doesn't exist.
if [ ! -d "$MOUNT_POINT" ]; then
    echo "Creating mount point: $MOUNT_POINT"
    sudo mkdir -p "$MOUNT_POINT"
fi

# Check if already mounted.
if mount | grep -q "$MOUNT_POINT"; then
    echo "NFS share already mounted at $MOUNT_POINT"
else
    # Mount the NFS share.
    echo "Mounting NFS share from $SERVER_IP:$NFS_PATH to $MOUNT_POINT..."
    sudo mount -t nfs "$SERVER_IP:$NFS_PATH" "$MOUNT_POINT"
    
    # Check if mount was successful.
    if mount | grep -q "$MOUNT_POINT"; then
        echo "NFS share mounted successfully!"
    else
        echo "Failed to mount NFS share. Please check connectivity and NFS server status."
        exit 1
    fi
fi

# Add the mount to /etc/fstab for persistence across reboots (optional).
if ! grep -q "$SERVER_IP:$NFS_PATH" /etc/fstab; then
    echo "Adding mount to /etc/fstab for persistence..."
    echo "$SERVER_IP:$NFS_PATH $MOUNT_POINT nfs defaults,_netdev 0 0" | sudo tee -a /etc/fstab
fi

echo "NFS client setup complete. Share from $SERVER_IP mounted at $MOUNT_POINT"
echo "Listing contents of $MOUNT_POINT:"
ls -la "$MOUNT_POINT"
