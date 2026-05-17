# 🐳 Enterprise Ubuntu VM inside Docker (KVM/QEMU)

A high-performance, dynamic **Ubuntu Virtual Machine (VM)** running seamlessly inside a Docker container using QEMU/KVM virtualization. This image features automated cloud-init provisioning, dynamic resource scaling (RAM, CPU Cores, and Disk Size), and full **noVNC** web browser GUI and SSH access.

## ⚡ Key Features

* 🌍 **Universal Base:** Multi-OS compatibility layer supporting Ubuntu 22.04, 24.04, and Debian bases via Build Arguments.
* 🖥️ **Web GUI Access:** Built-in HTML5 noVNC client for clientless desktop access via any browser.
* ⚙️ **Dynamic Resource Allocation:** Adjust RAM, CPU, and Storage limits on-the-fly during boot execution.
* 🔐 **Cloud-Init Ready:** Pre-configured root credentials and SSH access infrastructure out of the box.

## 🔐 Quick Access Credentials

Default Username: root
Default Password: root
Root Access: root / root

## 🚀 Usage & Deployment Profiles

Launch your virtual machine with custom hardware profiles directly from the command line using environment variables (`-e`):

### 💻 Developer Profile (1GB RAM, 1 CPU Core, 15GB Disk)

```bash
docker run -it \
  -p 6080:6080 \
  -p 22:22 \
  -e RAM=1024 \
  -e CORES=1 \
  -e DISK_SIZE=15G \
  walksysdev/ubuntu-vm-kvm

```

### ⚡ Heavy Workload Profile (4GB RAM, 4 CPU Cores, 40GB Disk)

```bash
docker run -it \
  -p 6080:6080 \
  -p 22:22 \
  -e RAM=4096 \
  -e CORES=4 \
  -e DISK_SIZE=40G \
  walksysdev/ubuntu-vm-kvm

```

### 📦 Fallback Standard Mode (Defaults: 2GB RAM, 2 Cores, 20GB Disk)

```bash
docker run -it -p 6080:6080 -p 22:22 walksysdev/ubuntu-vm-kvm

```

---

## 🌐 Network Routing & Access Links

| Connection Type | Target Address / URL | Credentials (User/Pass) |
| --- | --- | --- |
| 🖥️ **Web Browser GUI** | [http://localhost:6080/vnc.html](http://localhost:6080/vnc.html) | *No Password Required* |
| 🔐 **Secure SSH Terminal** | `ssh root@localhost -p 22` | `root` / `root` |

> 💡 **GitHub Codespaces Deployment:** Navigate to the **"Ports"** panel at the bottom of your workspace, look for port `6080`, and click the 🌍 **Open in Browser** option to access the graphical console securely.

---

## 🛠️ Infrastructure Build Customization

If you want to compile and build this image from the source files using a different Linux flavor as the foundational base image:

## 🛠️ Infrastructure Build Management

If you want to pull down the source configurations or compile the container manually:

### Image Download Command

```bash
docker pull walksysdev/ubuntu-vm-kvm:latest

```

### Manual Compilation Pipeline

```bash
docker build -t walksysdev/ubuntu-vm-kvm .

```

*Maintained with 💻 by [@walksysdev](https://hub.docker.com/r/walksysdev).*
