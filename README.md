# Installing Docker in Termux
This repository contains instructions on how to install Docker in [Termux](https://termux.com/), a powerful terminal emulator for Android.

# Prerequisites
Before proceeding with the installation, make sure you have the following prerequisites:
- An Android device with Termux installed. You can download Termux from the [F-Droid](https://f-droid.org/packages/com.termux/) app store.
- Stable internet connection.

# Installation Steps
Follow the steps below to install Docker in Termux:

1. Open Termux on your Android device.

2. Update and upgrade the packages by running the following command:
```bash
pkg update -y && pkg upgrade -y
```

3. Install the necessary dependencies by running the following command:
```bash
pkg install qemu-utils qemu-common qemu-system-x86_64-headless wget -y
```

4. Create a separate directory:
```bash
mkdir alpine && cd alpine
```

5. Download Alpine Linux 3.21.3 (virt optimized) ISO:
```bash
wget https://dl-cdn.alpinelinux.org/alpine/v3.21/releases/x86_64/alpine-virt-3.21.3-x86_64.iso
```

6. Create a disk (note it won't actually take 5GB of space, more like 500-600MB):
```bash
qemu-img create -f qcow2 alpine.img 5G
```

7. Boot it up:
```bash
qemu-system-x86_64 -machine q35 -m 1024 -smp cpus=2 -cpu qemu64 -drive if=pflash,format=raw,read-only=on,file=$PREFIX/share/qemu/edk2-x86_64-code.fd -netdev user,id=n1,dns=8.8.8.8,hostfwd=tcp::2222-:22 -device virtio-net,netdev=n1 -cdrom alpine-virt-3.21.3-x86_64.iso -nographic alpine.img
```

8. Login with username `root` (no password).

9. Set up the network (press Enter to use defaults):
```bash
localhost:~# setup-interfaces
 Available interfaces are: eth0.
 Enter '?' for help on bridges, bonding, and VLANs.
 Which one do you want to initialize? (or '?' or 'done') [eth0]
 Ip address for eth0? (or 'dhcp', 'none', '?') [dhcp]
 Do you want to do any manual network configuration? [no]
```
After that, bring up the interface:
```bash
ifup eth0
```

10. Create an answerfile to speed up the installation:
```bash
wget https://raw.githubusercontent.com/trefeon/Docker-Termux/main/answerfile
```
> **NOTE:** If you see any error like this: `wget: bad address 'gist.githubusercontent.com'`, run the following command:
> ```bash
> echo -e "nameserver 192.168.1.1\nnameserver 1.1.1.1" > /etc/resolv.conf
> ```

11. Patch `setup-disk` to enable serial console output on boot:
```bash
sed -i -E 's/(local kernel_opts)=.*/\1="console=ttyS0"/' /sbin/setup-disk
```

12. Run the setup to install Alpine to the disk:
```bash
setup-alpine -f answerfile
```

13. Once the installation is complete, power off the VM using the `poweroff` command.

14. Boot again without the CD-ROM:
```bash
qemu-system-x86_64 -machine q35 -m 1024 -smp cpus=2 -cpu qemu64 -drive if=pflash,format=raw,read-only=on,file=$PREFIX/share/qemu/edk2-x86_64-code.fd -netdev user,id=n1,dns=8.8.8.8,hostfwd=tcp::2222-:22 -device virtio-net,netdev=n1 -nographic alpine.img
```

### A. Create a script to simplify booting:
```bash
nano run_qemu.sh
```
In the text editor, add the following:
```bash
#!/bin/bash
qemu-system-x86_64 -machine q35 -m 1024 -smp cpus=2 -cpu qemu64 -drive if=pflash,format=raw,read-only=on,file=$PREFIX/share/qemu/edk2-x86_64-code.fd -netdev user,id=n1,dns=8.8.8.8,hostfwd=tcp::2222-:22 -device virtio-net,netdev=n1 -nographic alpine.img
```
Save and exit.

### B. Make the script executable:
```bash
chmod +x run_qemu.sh
```

### C. Run the script:
```bash
./run_qemu.sh
```

15. Update the system and install Docker:
```bash
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 8.8.4.4" >> /etc/resolv.conf

apk update && apk add docker
```

16. Start Docker:
```bash
service docker start
```

17. Enable Docker to start on boot:
```bash
rc-update add docker
```

18. Check if Docker was installed successfully:
```bash
docker run hello-world
```

# Some useful keys:
- `Ctrl+a x`: Quit emulation.
- `Ctrl+a h`: Toggle QEMU console.

# Usage
Now that Docker is installed in Termux, you can start using it to manage and run containers on your Android device. Refer to the official [Docker documentation](https://docs.docker.com/) for more information on how to use Docker.

# Contributing
If you encounter any issues during the installation process or have suggestions for improvements, please feel free to open an issue or submit a pull request.

# License
This project is licensed under the [MIT License](LICENSE).

