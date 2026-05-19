FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
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
RUN wget -q https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img -O /data/ubuntu.img

# Cloud-init user-data to set root password and allow login
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

# Required metadata file (can be empty)
RUN touch /seed/meta-data

# Create the seed image used by cloud-init
RUN cloud-localds /data/seed.img /seed/user-data /seed/meta-data

# Setup noVNC
RUN wget https://github.com/novnc/noVNC/archive/refs/heads/master.zip -O /tmp/novnc.zip && \
    unzip /tmp/novnc.zip -d /tmp && \
    mv /tmp/noVNC-master/* /novnc && \
    rm -rf /tmp/novnc.zip /tmp/noVNC-master

# Startup script
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
echo "Starting Ubuntu VM..."\n\
\n\
qemu-system-x86_64 \\\n\
  -m 2048 \\\n\
  -smp 2 \\\n\
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
echo "================================================"\n\
echo " ✅ VM running — Login with user: root / pass: root"\n\
echo " 🌐 Access VNC at http://localhost:6080"\n\
echo " 🔐 SSH via: ssh root@localhost -p 2222"\n\
echo "================================================"\n\
tail -f /dev/null\n' > /start.sh && chmod +x /start.sh

# Persistent volume
VOLUME /data

EXPOSE 6080 2222

CMD ["/start.sh"]
