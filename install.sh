#!/bin/bash

# Docker-Termux Automated Installer
# Created: 2026-05-12

set -e # Exit on error

echo "🚀 Starting Docker-Termux Automated Installer..."

# 1. Install Dependencies
echo "📦 Installing dependencies (qemu, wget, curl)..."
pkg install qemu-utils qemu-common qemu-system-x86_64-headless wget curl -y || { echo "❌ Failed to install dependencies"; exit 1; }

# 2. Get Latest Alpine Version
echo "🔍 Searching for latest Alpine Linux Virt ISO..."
BASE_URL="https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/x86_64/"
ISO_NAME=$(curl -s $BASE_URL | grep -oE 'alpine-virt-[0-9.]+-x86_64.iso' | head -n 1)

if [ -z "$ISO_NAME" ]; then
    echo "❌ Could not detect latest Alpine version. Falling back to 3.23.4."
    ISO_NAME="alpine-virt-3.23.4-x86_64.iso"
    ISO_URL="https://dl-cdn.alpinelinux.org/alpine/v3.23/releases/x86_64/$ISO_NAME"
else
    MAJOR_MINOR=$(echo $ISO_NAME | grep -oE '[0-9]+\.[0-9]+')
    ISO_URL="https://dl-cdn.alpinelinux.org/alpine/v$MAJOR_MINOR/releases/x86_64/$ISO_NAME"
    echo "✅ Found latest: $ISO_NAME"
fi

# 3. Create Directory
mkdir -p alpine && cd alpine

# 4. Download ISO
if [ ! -f "$ISO_NAME" ]; then
    echo "📥 Downloading $ISO_NAME..."
    wget "$ISO_URL" || { echo "❌ Download failed"; exit 1; }
else
    echo "ℹ️ ISO already exists, skipping download."
fi

# 5. Create Disk
if [ ! -f "alpine.img" ]; then
    echo "💾 Creating 5GB virtual disk..."
    qemu-img create -f qcow2 alpine.img 5G || { echo "❌ Disk creation failed"; exit 1; }
else
    echo "ℹ️ Disk image already exists."
fi

# 6. Generate run_qemu.sh
echo "📝 Generating run_qemu.sh with GUI support (Port 9000)..."
cat <<EOF > run_qemu.sh
#!/bin/bash
# Boot script with Portainer port forwarding (9000)
qemu-system-x86_64 \\
    -machine q35 -m 1024 -smp cpus=2 -cpu qemu64 \\
    -drive if=pflash,format=raw,read-only=on,file=\$PREFIX/share/qemu/edk2-x86_64-code.fd \\
    -netdev user,id=n1,dns=8.8.8.8,hostfwd=tcp::2222-:22,hostfwd=tcp::9000-:9000 \\
    -device virtio-net,netdev=n1 \\
    -nographic alpine.img \\
    \$@
EOF
chmod +x run_qemu.sh

echo ""
echo "✅ Installation phase 1 complete!"
echo "-------------------------------------------------------"
echo "NEXT STEPS:"
echo "1. Run './alpine/run_qemu.sh -cdrom alpine/$ISO_NAME' to boot the ISO."
echo "2. Login as 'root' and run 'setup-alpine'."
echo "3. After install, poweroff and run './alpine/run_qemu.sh' normally."
echo "4. Inside Alpine, run these to start Docker + GUI:"
echo "   apk add docker && service docker start && rc-update add docker"
echo "   docker run -d -p 9000:9000 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock portainer/portainer-ce:latest"
echo "5. Open http://localhost:9000 in your Android browser."
echo "-------------------------------------------------------"
