FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    qemu-system-x86 \
    qemu-utils \
    cloud-image-utils \
    novnc \
    websockify \
    wget \
    unzip \
    net-tools \
    openssh-client \
    && rm -rf /var/lib/apt/lists/*

# Create working directories
RUN mkdir -p /data /seed /novnc

# Download Ubuntu Cloud Image
RUN wget -q https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img -O /data/ubuntu.img

# Cloud-init user-data config to set root credentials
RUN bash -c 'cat > /seed/user-data' <<EOF
#cloud-config
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

# Download and extract noVNC Web UI
RUN wget https://github.com/novnc/noVNC/archive/refs/heads/master.zip -O /tmp/novnc.zip && \
    unzip /tmp/novnc.zip -d /tmp && \
    mv /tmp/noVNC-master/* /novnc && \
    rm -rf /tmp/novnc.zip /tmp/noVNC-master

# Dynamic Startup Script with Environment Variable parsing
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
# Set fallback defaults if runtime variables are missing\n\
VM_RAM="${RAM:-2048}"\n\
VM_CORES="${CORES:-2}"\n\
VM_DISK_SIZE="${DISK_SIZE:-20G}"\n\
\n\
echo "⚙️ Configuring VM Resource Specifications..."\n\
echo "   -> Allocation: RAM=${VM_RAM}MB | CPU Cores=${VM_CORES} | Virtual Disk=${VM_DISK_SIZE}"\n\
\n\
# Dynamically scale the virtual disk image partition\n\
qemu-img resize /data/ubuntu.img "${VM_DISK_SIZE}" > /dev/null\n\
\n\
echo "🚀 Initializing Ubuntu Virtual Machine boot sequence..."\n\
\n\
qemu-system-x86_64 \\\n\
  -m "${VM_RAM}" \\\n\
  -smp "${VM_CORES}" \\\n\
  -vga virtio \\\n\
  -drive file=/data/ubuntu.img,format=qcow2,if=virtio \\\n\
  -drive file=/data/seed.img,format=raw,if=virtio \\\n\
  -netdev user,id=net0,hostfwd=tcp::2222-:22 \\\n\
  -device virtio-net,netdev=net0 \\\n\
  -nographic \\\n\
  -serial mon:stdio \\\n\
  -vnc :0 &\n\
\n\
sleep 5\n\
websockify --web /novnc 6080 localhost:5900 &\n\
\n\
echo "========================================================================="\n\
echo " ✅ VM is up and running successfully!"\n\
echo " 🌐 Web UI VNC Access  : http://localhost:6080/vnc.html"\n\
echo " 🔐 Secure SSH Access  : ssh root@localhost -p 2222 (Password: root)"\n\
echo "========================================================================="\n\
tail -f /dev/null\n' > /start.sh && chmod +x /start.sh

# Persistent storage mount point
VOLUME /data

# VNC and SSH networking ports
EXPOSE 6080 2222

CMD ["/start.sh"]
