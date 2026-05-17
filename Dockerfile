FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies + sshpass tool to automate the password login
RUN apt-get update && apt-get install -y --no-install-recommends \
    qemu-system-x86 \
    qemu-utils \
    cloud-image-utils \
    wget \
    unzip \
    net-tools \
    openssh-client \
    sshpass \
    && rm -rf /var/lib/apt/lists/*

# Create working directories
RUN mkdir -p /data /seed

# Download Ubuntu Cloud Image to a secure internal template path
RUN wget -q https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img -O /ubuntu-template.img

# Cloud-init user-data config to set root credentials and change Hostname
RUN bash -c 'cat > /seed/user-data' <<EOF
#cloud-config
hostname: WalksysDev
manage_etc_hosts: true

users:
  - name: root
    plain_text_passwd: "root"
    lock_passwd: false
    shell: /bin/bash
    sudo: ALL=(ALL) NOPASSWD:ALL

ssh_pwauth: true
disable_root: false
chpasswd:
  expire: false
EOF

# Required cloud-init metadata file
RUN touch /seed/meta-data

# Generate the seed image used by cloud-init
RUN cloud-localds /data/seed.img /seed/user-data /seed/meta-data

# Dynamic Startup Script with AUTOMATED TERMINAL ATTACH
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
VM_RAM="${RAM:-2048}"\n\
VM_CORES="${CORES:-2}"\n\
VM_DISK_SIZE="${DISK_SIZE:-20G}"\n\
\n\
echo "⚙️ Configuring VM Resource Specifications..."\n\
echo "   -> Allocation: RAM=${VM_RAM}MB | CPU Cores=${VM_CORES} | Virtual Disk=${VM_DISK_SIZE}"\n\
\n\
if [ ! -f /data/ubuntu22.qcow2 ]; then\n\
    echo "🆕 Fresh container deployment: Provisioning permanent volume..."\n\
    cp /ubuntu-template.img /data/ubuntu22.qcow2\n\
    qemu-img resize /data/ubuntu22.qcow2 "${VM_DISK_SIZE}" > /dev/null\n\
else\n\
    echo "💾 Container restart detected: Loading your saved data safely!"\n\
fi\n\
\n\
echo "🚀 Initializing Ubuntu Virtual Machine in background..."\n\
\n\
# Boot QEMU purely in background without blocking stdio/keyboard\n\
qemu-system-x86_64 \\\n\
  -m "${VM_RAM}" \\\n\
  -smp "${VM_CORES}" \\\n\
  -vga virtio \\\n\
  -drive file=/data/ubuntu22.qcow2,format=qcow2,if=virtio \\\n\
  -drive file=/data/seed.img,format=raw,if=virtio \\\n\
  -netdev user,id=net0,hostfwd=tcp::2026-:22 \\\n\
  -device virtio-net,netdev=net0 \\\n\
  -nographic \\\n\
  -vnc :0 &\n\
\n\
echo "⏳ Waiting for network service initialization (10s)..."\n\
sleep 10\n\
\n\
echo "========================================================================="\n\
echo " 🌐 Connecting you directly to WalksysDev Terminal..."\n\
echo "========================================================================="\n\
\n\
# Automatically inject password and log you in inside the SAME main terminal\n\
sshpass -p "root" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@localhost -p 2026\n\
\n\
# Keep container alive if user exits the SSH session\n\
tail -f /dev/null\n' > /start.sh && chmod +x /start.sh

# Persistent storage volume inside the container layers
VOLUME /data

# SSH networking port
EXPOSE 2026

CMD ["/start.sh"]
