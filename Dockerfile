FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    qemu-system-x86 \
    qemu-utils \
    cloud-image-utils \
    wget \
    unzip \
    net-tools \
    openssh-client \
    && rm -rf /var/lib/apt/lists/*

# Create working directories
RUN mkdir -p /data /seed

# Download Ubuntu Cloud Image
RUN wget -q https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img -O /data/ubuntu.img

# Cloud-init user-data config
RUN cat > /seed/user-data <<'EOF'
#cloud-config
hostname: walksysdev
prefer_fqdn_over_hostname: true

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

# Generate the seed image
RUN cloud-localds /data/vms.img /seed/user-data /seed/meta-data

# Fixed startup script - copy from file instead of echo escaping
COPY <<'EOF' /start.sh
#!/bin/bash
set -e

VM_RAM="${RAM:-2048}"
VM_CORES="${CORES:-2}"
VM_DISK_SIZE="${DISK_SIZE:-10G}"

echo "⚙️ Configuring VM Resource Specifications..."
echo "   -> Allocation: RAM=${VM_RAM}MB | CPU Cores=${VM_CORES} | Virtual Disk=${VM_DISK_SIZE}"

if [ ! -f /data/ubuntu.img ]; then
  echo "❌ Missing VM disk image!"
  exit 1
fi

qemu-img resize /data/ubuntu.img "${VM_DISK_SIZE}" >/dev/null

echo "🚀 Initializing Ubuntu Virtual Machine boot sequence..."

exec qemu-system-x86_64 \
  -m "${VM_RAM}" \
  -smp "${VM_CORES}" \
  -vga virtio \
  -drive file=/data/ubuntu.img,format=qcow2,if=virtio \
  -drive file=/data/seed.img,format=raw,if=virtio \
  -netdev user,id=net0,hostfwd=tcp::2026-:22 \
  -device virtio-net,netdev=net0 \
  -nographic \
  -serial mon:stdio \
  -vnc :0

sleep 5

echo "========================================================================="
echo " ✅ VM is up and running successfully!"
echo " 🔐 Secure SSH Access  : ssh root@localhost -p 2026 (Password: root)"
echo "========================================================================="
tail -f /dev/null
EOF

RUN chmod +x /start.sh

VOLUME /data
EXPOSE 2026

CMD ["/start.sh"]
